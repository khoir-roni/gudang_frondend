
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <--- PERBAIKAN: Import yang diperlukan ditambahkan
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/tf_service.dart';
// tflite and image imports removed; processing handled in TfService

const double kConfidenceThreshold = 0.4;

// Enum untuk mengelola state UI
enum CameraState {
  initializing,
  permissionDenied,
  ready,
  capturing,
  classifying,
  resultNotFound,
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraState _cameraState = CameraState.initializing;
  CameraController? _cameraController;
  final TfService _tfService = TfService();
  String? _modelName;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _tfService.close();
    super.dispose();
  }

  Future<void> _initialize() async {
    if (await Permission.camera.request().isGranted) {
      await _initializeCamera();
      await _tfService.loadModel();
      _modelName = _tfService.loadedModelName;
      debugPrint('CameraScreen: model loaded: $_modelName');
      if (!_tfService.isLoaded) {
        if (mounted) setState(() => _cameraState = CameraState.permissionDenied);
        return;
      }
      if (mounted) setState(() => _cameraState = CameraState.ready);
    } else {
      if (mounted) setState(() => _cameraState = CameraState.permissionDenied);
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _cameraController = CameraController(cameras[0], ResolutionPreset.high, enableAudio: false);
    await _cameraController!.initialize();
  }
  

  Future<void> _onTakePhoto() async {
    if (_cameraController == null || !_tfService.isLoaded || !mounted) return;
    setState(() => _cameraState = CameraState.capturing);
    try {
      final XFile picture = await _cameraController!.takePicture();
      if (mounted) setState(() => _cameraState = CameraState.classifying);
      final Uint8List imageBytes = await picture.readAsBytes();
      final results = await _tfService.classifyBytes(imageBytes);
      if (results.isNotEmpty) {
        final label = (results[0]['label'] ?? '').toString();
        final confidence = (results[0]['confidence'] ?? 0.0);
        final raw = results[0]['raw_score'] ?? null;
        debugPrint('Prediction: $label conf=$confidence raw=$raw');
        if (mounted) await _showPredictionPreview(label, confidence as double);
      } else {
        if (mounted) setState(() => _cameraState = CameraState.resultNotFound);
      }
    } catch (e) {
      debugPrint("Error saat mengambil atau mengklasifikasikan foto: $e");
      if (mounted) setState(() => _cameraState = CameraState.ready);
    }
  }

  Future<void> _showPredictionPreview(String label, double confidence) async {
    const threshold = kConfidenceThreshold;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Prediksi: $label', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Confidence: ${(confidence * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (confidence >= threshold) context.go('/inventory?q=$label');
                    setState(() => _cameraState = CameraState.ready);
                  },
                  child: const Text('Gunakan'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _showManualEdit(label);
                  },
                  child: const Text('Edit'),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() => _cameraState = CameraState.ready);
                },
                child: const Text('Batal')),
            const SizedBox(height: 12),
            if (_modelName != null) Text('Model: $_modelName', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        );
      },
    );
  }

  void _showManualEdit(String initial) {
    final controller = TextEditingController(text: initial);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Prediksi'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Nama alat')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final q = controller.text.trim();
              Navigator.of(ctx).pop();
              if (q.isNotEmpty) context.go('/inventory?q=$q');
              setState(() => _cameraState = CameraState.ready);
            },
            child: const Text('Cari'),
          ),
        ],
      ),
    );
  }

  Future<void> _classifyImage(Uint8List imageBytes) async {
    // Removed: use `TfService.classifyBytes` instead.
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Tool')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_cameraState) {
      case CameraState.initializing:
        return const Center(child: CircularProgressIndicator());
      case CameraState.permissionDenied:
        return _buildPermissionDeniedUI();
      case CameraState.capturing:
      case CameraState.classifying:
        return _buildCameraPreviewWithOverlay(Center(child: _buildLoaderUI()));
      case CameraState.resultNotFound:
        return _buildCameraPreviewWithOverlay(_buildResultNotFoundUI());
      case CameraState.ready:
        if (_cameraController == null || !_cameraController!.value.isInitialized) {
          return const Center(child: Text("Kamera tidak tersedia."));
        }
        return _buildCameraPreviewWithOverlay(_buildShutterButton());
    }
  }

  Widget _buildPermissionDeniedUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Izin Kamera Ditolak', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Untuk mengklasifikasikan alat, mohon berikan izin kamera di pengaturan.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: openAppSettings, child: const Text('Buka Pengaturan')),
            const SizedBox(height: 10),
            TextButton(onPressed: _initialize, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoaderUI() {
      return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _cameraState == CameraState.capturing ? "Mengambil gambar..." : "Menganalisis...",
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        );
  }

  Widget _buildResultNotFoundUI() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, color: Colors.white, size: 50),
            const SizedBox(height: 16),
            const Text("Alat Tidak Dikenali", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() => _cameraState = CameraState.ready),
              child: const Text("Ambil Foto Lagi"),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildShutterButton(){
       return Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: FloatingActionButton(
                onPressed: _onTakePhoto,
                child: const Icon(Icons.camera_alt, size: 36),
              ),
            ),
          );
  }

  Widget _buildCameraPreviewWithOverlay(Widget overlayWidget) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: Text("Kamera tidak tersedia."));
    }
    return Stack(fit: StackFit.expand, children: [CameraPreview(_cameraController!), overlayWidget]);
  }
}

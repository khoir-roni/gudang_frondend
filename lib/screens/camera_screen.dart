import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart'; // Tambahan untuk Skenario C
import '../services/tf_service.dart';

List<CameraDescription> cameras = [];

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? controller;
  bool _isCameraInitialized = false;
  bool _isPermissionDenied = false; // Flag untuk Skenario C
  final TfService _tfService = TfService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionAndInit(); // Cek permission dulu
    _tfService.loadModel();
  }

  // Skenario C: Handling Permission
  Future<void> _checkPermissionAndInit() async {
    var status = await Permission.camera.status;

    if (status.isDenied || status.isPermanentlyDenied) {
      status = await Permission.camera.request();
    }

    if (status.isGranted) {
      setState(() => _isPermissionDenied = false);
      await initCamera();
    } else {
      setState(() => _isPermissionDenied = true);
    }
  }

  Future<void> initCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Pilih kamera belakang, resolusi medium cukup untuk MobileNet
      controller = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller!.initialize();

      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      print("Camera error: $e");
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    _tfService.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Cek lifecycle app (misal user balik dari Settings)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isPermissionDenied) {
        _checkPermissionAndInit();
      } else if (controller == null || !controller!.value.isInitialized) {
        initCamera();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Skenario C: Tampilan jika izin ditolak
    if (_isPermissionDenied) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                "Izin kamera dibutuhkan",
                style: TextStyle(fontSize: 18),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: Text(
                  "Mohon aktifkan izin kamera di pengaturan untuk menggunakan fitur scan.",
                  textAlign: TextAlign.center,
                ),
              ),
              ElevatedButton(
                onPressed: () => openAppSettings(), // Buka Settings HP
                child: const Text("Buka Pengaturan"),
              ),
              TextButton(
                onPressed: _checkPermissionAndInit,
                child: const Text("Coba Lagi"),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraInitialized || controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Scan Tool (Offline ML)")),
      body: Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: controller!.value.aspectRatio,
              child: CameraPreview(controller!),
            ),
          ),
          // Area Kontrol
          Container(
            height: 150,
            color: Colors.black87,
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tombol Shutter (Skenario A: Trigger Manual)
                FloatingActionButton.large(
                  onPressed: _captureAndClassify,
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.camera,
                    color: Colors.black,
                    size: 50,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _captureAndClassify() async {
    if (controller == null || !controller!.value.isInitialized) return;

    try {
      // 1. Ambil Foto
      final image = await controller!.takePicture();

      if (!mounted) return;
      // Show loading indicator overlay or snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Menganalisa..."),
          duration: Duration(milliseconds: 500),
        ),
      );

      // 2. Jalankan Inference
      // Format results dari TF Service harus:List<Map<String, dynamic>>
      // Contoh: [{'label': 'hammer', 'confidence': 95.5}]
      final results = await _tfService.classifyImage(image.path);

      if (!mounted) return;

      if (results.isEmpty) {
        _showLowConfidenceDialog();
        return;
      }

      final topResult = results[0];
      final String label = topResult['label'];
      final double confidence =
          topResult['confidence']; // Pastikan TF Service return double (0-100)

      // Skenario A: Ambang Batas (Threshold)
      if (confidence < 50.0) {
        _showLowConfidenceDialog();
      } else {
        // Skenario A: Interaksi (Otomatis cari ke server)
        // Langsung pindah ke Inventory Screen dengan query
        print("Detected: $label ($confidence%)");
        context.go(
          Uri(path: '/inventory', queryParameters: {'q': label}).toString(),
        );
      }
    } catch (e) {
      print("Error classification: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // Skenario A: Dialog jika Confidence Rendah
  void _showLowConfidenceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tidak Dikenali"),
        content: const Text(
          "Objek tidak dapat dikenali dengan jelas (Confidence < 50%).\nSilakan coba lagi dengan pencahayaan yang lebih baik.",
        ),
        actions: [
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context), // Tutup dialog & Foto Ulang
            child: const Text("Foto Ulang"),
          ),
        ],
      ),
    );
  }
}

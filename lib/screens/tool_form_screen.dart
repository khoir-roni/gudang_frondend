
import 'package:flutter/material.dart';
import '../models/tool.dart';
import '../services/api_service.dart';

class ToolFormScreen extends StatefulWidget {
  // Jika `tool` tidak null, berarti ini adalah mode edit.
  // Jika null, ini adalah mode tambah.
  final Tool? tool;

  const ToolFormScreen({Key? key, this.tool}) : super(key: key);

  @override
  _ToolFormScreenState createState() => _ToolFormScreenState();
}

class _ToolFormScreenState extends State<ToolFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // Controller untuk setiap field
  late TextEditingController _namaController;
  late TextEditingController _jumlahController;
  late TextEditingController _lemariController;
  late TextEditingController _lokasiController;

  bool get _isEditing => widget.tool != null;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan data yang ada jika dalam mode edit
    _namaController = TextEditingController(text: widget.tool?.namaBarang ?? '');
    _jumlahController = TextEditingController(text: widget.tool?.jumlah.toString() ?? '');
    _lemariController = TextEditingController(text: widget.tool?.lemari ?? '');
    _lokasiController = TextEditingController(text: widget.tool?.lokasi ?? '');
  }

  @override
  void dispose() {
    _namaController.dispose();
    _jumlahController.dispose();
    _lemariController.dispose();
    _lokasiController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    // Validasi form
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Siapkan data untuk dikirim ke API
      final toolData = {
        'nama_barang': _namaController.text,
        'jumlah': int.tryParse(_jumlahController.text) ?? 0,
        'lemari': _lemariController.text,
        'lokasi': _lokasiController.text,
        'username': 'admin' // TODO: Ganti dengan username yang sedang login
      };

      try {
        if (_isEditing) {
          // Panggil API untuk update (misalnya, update jumlah)
          // Anda mungkin perlu menyesuaikan endpoint ini sesuai kebutuhan
          await _apiService.updateTool(toolData);
        } else {
          // Panggil API untuk menambah barang baru
          await _apiService.addTool(toolData);
        }
        
        // Kembali ke layar sebelumnya dengan hasil sukses
        if (mounted) Navigator.of(context).pop(true);

      } catch (e) {
        // Tampilkan pesan error jika gagal
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Barang' : 'Tambah Barang'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Barang'),
                validator: (value) => value!.isEmpty ? 'Nama barang tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _jumlahController,
                decoration: const InputDecoration(labelText: 'Jumlah'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Jumlah tidak boleh kosong';
                  if (int.tryParse(value) == null) return 'Masukkan angka yang valid';
                  return null;
                },
              ),
              TextFormField(
                controller: _lemariController,
                decoration: const InputDecoration(labelText: 'Lemari / Rak'),
                validator: (value) => value!.isEmpty ? 'Lemari tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _lokasiController,
                decoration: const InputDecoration(labelText: 'Lokasi / Ruangan'),
                validator: (value) => value!.isEmpty ? 'Lokasi tidak boleh kosong' : null,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitForm,
                      child: Text(_isEditing ? 'Simpan Perubahan' : 'Tambah Barang'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

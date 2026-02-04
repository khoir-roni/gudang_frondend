
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/tool.dart';

class ApiService {
  // Untuk development di emulator Android, gunakan 10.0.2.2
  // Untuk development di perangkat fisik, ganti dengan alamat IP lokal komputer Anda (misal: 192.168.1.10)
  static final String _baseUrl = Platform.isAndroid ? "http://10.0.2.2:5000" : "http://localhost:5000";

  /// Mengambil semua barang, dengan opsi filter berdasarkan nama (query).
  Future<List<Tool>> fetchTools({String? query}) async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/get_barang"));

      if (response.statusCode == 200) {
        List<Tool> tools = toolsFromJson(response.body);
        
        // Jika ada query, filter hasil di sisi klien.
        if (query != null && query.isNotEmpty) {
          tools = tools.where((tool) => tool.namaBarang.toLowerCase().contains(query.toLowerCase())).toList();
        }
        return tools;
      } else {
        throw Exception('Gagal memuat data dari API. Status code: ${response.statusCode}');
      }
    } on SocketException {
        throw Exception('Tidak ada koneksi internet. Mohon periksa jaringan Anda.');
    } catch (e) {
        debugPrint(e.toString());
        rethrow; // Lempar kembali error untuk ditangani oleh UI
    }
  }

  /// Menambah barang baru ke database.
  Future<void> addTool(Map<String, dynamic> toolData) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/add_barang"),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(toolData),
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal menambah barang baru.');
    }
  }

  /// Mengupdate jumlah barang (mengambil barang).
  Future<void> updateTool(Map<String, dynamic> toolData) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/update_barang"),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(toolData),
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal mengupdate barang.');
    }
  }

  /// Menghapus barang dari database.
  Future<void> deleteTool(Map<String, dynamic> toolData) async {
    final response = await http.delete(
      Uri.parse("$_baseUrl/delete_barang"),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(toolData),
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus barang.');
    }
  }
}

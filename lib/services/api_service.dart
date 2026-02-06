import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_config.dart';
import '../models/tool.dart';

class ApiService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<List<dynamic>> getTools() async {
    final uri = Uri.parse('$baseUrl/get_barang');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return json.decode(res.body) as List<dynamic>;
    }
    throw Exception('Failed to load tools');
  }

  Future<List<dynamic>> searchTools(String q) async {
    final all = await getTools();
    final lower = q.toLowerCase();
    return all.where((item) {
      final name = (item['nama_barang'] ?? '').toString().toLowerCase();
      return name.contains(lower);
    }).toList();
  }

  Future<dynamic> addTool(Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/add_barang');
    final res = await http.post(uri,
        headers: {'Content-Type': 'application/json'}, body: json.encode(data));
    if (res.statusCode == 200 || res.statusCode == 201) {
      return json.decode(res.body);
    }
    throw Exception('Failed to add tool: ${res.body}');
  }

  Future<dynamic> updateTool(Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/update_barang');
    final res = await http.post(uri,
        headers: {'Content-Type': 'application/json'}, body: json.encode(data));
    if (res.statusCode == 200) {
      return json.decode(res.body);
    }
    throw Exception('Failed to update tool');
  }

  Future<dynamic> takeToolStock(
      {required String namaBarang,
      required int jumlahDiambil,
      required String lemari,
      required String lokasi,
      required String username}) async {
    final uri = Uri.parse('$baseUrl/update_barang');
    final data = {
      'nama_barang': namaBarang,
      'jumlah_diambil': jumlahDiambil,
      'lemari': lemari,
      'lokasi': lokasi,
      'username': username,
    };

    print('==== takeToolStock DEBUG ====');
    print('URL: $uri');
    print('Data: ${json.encode(data)}');

    final res = await http.post(uri,
        headers: {'Content-Type': 'application/json'}, body: json.encode(data));

    print('Response status: ${res.statusCode}');
    print('Response body: ${res.body}');

    if (res.statusCode == 200) {
      return json.decode(res.body);
    }
    throw Exception('Failed to take tool: ${res.body}');
  }

  Future<dynamic> deleteTool(Tool tool) async {
    final uri = Uri.parse('$baseUrl/delete_barang');
    final res = await http.delete(uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nama_barang': tool.namaBarang,
          'lemari': tool.lemari,
          'lokasi': tool.lokasi,
        }));
    if (res.statusCode == 200) {
      return json.decode(res.body);
    }
    throw Exception('Failed to delete tool: ${res.body}');
  }

  Future<List<dynamic>> getHistory() async {
    final uri = Uri.parse('$baseUrl/get_history');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return json.decode(res.body) as List<dynamic>;
    }
    throw Exception('Failed to load history');
  }

  Future<dynamic> deleteHistory(int id) async {
    final uri = Uri.parse('$baseUrl/delete_history');
    final res = await http.delete(uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': id}));
    if (res.statusCode == 200) {
      return json.decode(res.body);
    }
    throw Exception('Failed to delete history');
  }
}

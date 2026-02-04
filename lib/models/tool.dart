
import 'dart:convert';

class Tool {
  final int id;
  final String namaBarang;
  final int jumlah;
  final String lemari;
  final String lokasi;

  Tool({
    required this.id,
    required this.namaBarang,
    required this.jumlah,
    required this.lemari,
    required this.lokasi,
  });

  // Factory constructor untuk membuat instance Tool dari JSON map
  factory Tool.fromJson(Map<String, dynamic> json) {
    return Tool(
      id: json['id'],
      namaBarang: json['nama_barang'],
      jumlah: json['jumlah'],
      lemari: json['lemari'],
      lokasi: json['lokasi'],
    );
  }
}

// Helper function untuk mem-parse list JSON menjadi List<Tool>
List<Tool> toolsFromJson(String str) => List<Tool>.from(json.decode(str).map((x) => Tool.fromJson(x)));

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/tool.dart';

void main() {
  test('Tool.fromJson parses correctly', () {
    final json = {
      'id': 1,
      'nama_barang': 'Obeng',
      'jumlah': 5,
      'lemari': 'A1',
      'lokasi': 'Gudang 1',
      'username': 'admin',
      'tanggal': '2026-02-05T12:00:00Z',
      'aksi': 'taruh',
    };

    final tool = Tool.fromJson(json);
    expect(tool.id, 1);
    expect(tool.namaBarang, 'Obeng');
    expect(tool.jumlah, 5);
    expect(tool.lemari, 'A1');
    expect(tool.lokasi, 'Gudang 1');
    expect(tool.user, 'admin');
    expect(tool.tanggal, '2026-02-05T12:00:00Z');
    expect(tool.aksi, 'taruh');
  });

  test('toolsFromJson parses list', () {
    const jsonStr = '[{"id":2,"nama_barang":"Pal","jumlah":3,"lemari":"B2","lokasi":"Gudang 2"}]';
    final list = toolsFromJson(jsonStr);
    expect(list, isA<List<Tool>>());
    expect(list.length, 1);
    expect(list[0].id, 2);
    expect(list[0].namaBarang, 'Pal');
  });
}

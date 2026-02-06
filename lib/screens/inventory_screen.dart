import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tool.dart';
import '../services/api_service.dart';
import 'tool_form_screen.dart';

class InventoryScreen extends StatefulWidget {
  // Accept an optional search query.
  final String? searchQuery;

  const InventoryScreen({Key? key, this.searchQuery}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _api = ApiService();
  List<Tool> _tools = [];
  List<Tool> _filtered = [];
  bool _isLoading = false;

  static const _searchHistoryKey = 'search_history';
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    // If a search query is passed from the camera screen, populate the text field.
    if (widget.searchQuery != null) {
      _searchController.text = widget.searchQuery!;
      // Trigger search with the initial query.
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _performSearch(widget.searchQuery!));
    }
    _loadTools();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory = prefs.getStringList(_searchHistoryKey) ?? [];
    setState(() {});
  }

  Future<void> _saveSearchQuery(String q) async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory.remove(q);
    _searchHistory.insert(0, q);
    if (_searchHistory.length > 10)
      _searchHistory = _searchHistory.sublist(0, 10);
    await prefs.setStringList(_searchHistoryKey, _searchHistory);
    setState(() {});
  }

  Future<void> _loadTools() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getTools();
      _tools =
          data.map((e) => Tool.fromJson(e as Map<String, dynamic>)).toList();
      _filtered = List.from(_tools);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _performSearch(String q) async {
    setState(() => _isLoading = true);
    try {
      await _saveSearchQuery(q);
      final results = await _api.searchTools(q);
      _filtered =
          results.map((e) => Tool.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTool(Tool tool) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Yakin ingin menghapus "${tool.namaBarang}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.deleteTool(tool);
      await _loadTools();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _takeTool(Tool tool) async {
    bool hasOperation = false;

    try {
      final confirm = await showDialog<String?>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          // Controller lifecycle terikat dengan dialog
          final quantityController = TextEditingController();

          return AlertDialog(
            title: const Text('Ambil Barang'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Barang: ${tool.namaBarang}'),
                  Text('Stok Saat Ini: ${tool.jumlah}'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah yang diambil',
                      hintText: 'Masukkan jumlah',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  final value = quantityController.text;
                  Navigator.of(ctx).pop(value);
                },
                child: const Text('Ambil'),
              ),
            ],
          );
        },
      );

      // Dialog dibatalkan
      if (confirm == null || confirm.isEmpty) {
        return;
      }

      final quantity = int.tryParse(confirm) ?? 0;

      if (quantity <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jumlah harus lebih dari 0')),
          );
        }
        return;
      }

      if (quantity > tool.jumlah) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Stok tidak mencukupi! Stok tersedia: ${tool.jumlah}')),
          );
        }
        return;
      }

      // Ada actual operation dari sini
      hasOperation = true;
      if (mounted) setState(() => _isLoading = true);

      await _api.takeToolStock(
        namaBarang: tool.namaBarang,
        jumlahDiambil: quantity,
        lemari: tool.lemari,
        lokasi: tool.lokasi,
        username: 'admin',
      );

      await _loadTools();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${quantity}x ${tool.namaBarang} telah diambil')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      // Only call setState jika ada actual operation (bukan dibatalkan)
      if (hasOperation && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openForm({Tool? tool}) async {
    final res = await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ToolFormScreen(tool: tool)));
    if (res == true) {
      await _loadTools();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onSubmitted: (v) => _performSearch(v),
              decoration: InputDecoration(
                labelText: 'Search Tool',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _performSearch(_searchController.text),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_searchHistory.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  scrollDirection: Axis.horizontal,
                  children: _searchHistory
                      .map((s) => Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ActionChip(
                              label:
                                  Text(s, style: const TextStyle(fontSize: 13)),
                              onPressed: () {
                                _searchController.text = s;
                                _performSearch(s);
                              },
                            ),
                          ))
                      .toList(),
                ),
              ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? const Center(child: Text('No results'))
                      : ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (context, idx) {
                            final t = _filtered[idx];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 4),
                              child: ListTile(
                                title: Text(t.namaBarang),
                                subtitle: Text(
                                    'Qty: ${t.jumlah} • ${t.lemari} • ${t.lokasi}'),
                                trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.remove_circle_outline),
                                        tooltip: 'Ambil Barang',
                                        onPressed: () => _takeTool(t),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () => _openForm(tool: t),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () => _deleteTool(t),
                                      ),
                                    ]),
                                onTap: () {
                                  // quick search by tapping item name
                                  _searchController.text = t.namaBarang;
                                  _performSearch(t.namaBarang);
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

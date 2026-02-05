
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
      WidgetsBinding.instance.addPostFrameCallback((_) => _performSearch(widget.searchQuery!));
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
    if (_searchHistory.length > 10) _searchHistory = _searchHistory.sublist(0, 10);
    await prefs.setStringList(_searchHistoryKey, _searchHistory);
    setState(() {});
  }

  Future<void> _loadTools() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getTools();
      _tools = data.map((e) => Tool.fromJson(e as Map<String, dynamic>)).toList();
      _filtered = List.from(_tools);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _performSearch(String q) async {
    setState(() => _isLoading = true);
    try {
      await _saveSearchQuery(q);
      final results = await _api.searchTools(q);
      _filtered = results.map((e) => Tool.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTool(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Yakin ingin menghapus barang ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.deleteTool(id);
      await _loadTools();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _openForm({Tool? tool}) async {
    final res = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ToolFormScreen(tool: tool)));
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
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: ActionChip(
                                label: Text(s, style: const TextStyle(fontSize: 13)),
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
                              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                              child: ListTile(
                                title: Text(t.namaBarang),
                                subtitle: Text('Qty: ${t.jumlah} • ${t.lemari} • ${t.lokasi}'),
                                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _openForm(tool: t),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _deleteTool(t.id),
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

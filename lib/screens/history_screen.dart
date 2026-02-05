import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();
  List<dynamic> _actionHistory = [];
  List<String> _searchHistory = [];
  bool _isLoading = false;

  static const _searchHistoryKey = 'search_history';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadSearchHistory(), _loadActionHistory()]);
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory = prefs.getStringList(_searchHistoryKey) ?? [];
    setState(() {});
  }

  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchHistoryKey);
    _searchHistory = [];
    setState(() {});
  }

  Future<void> _loadActionHistory() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getHistory();
      _actionHistory = data;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteActionHistory(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus History'),
        content: const Text('Yakin ingin menghapus history ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.deleteHistory(id);
      await _loadActionHistory();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Search History'), Tab(text: 'Action History')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchHistoryTab(),
          _buildActionHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildSearchHistoryTab() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent searches'),
              TextButton(onPressed: _clearSearchHistory, child: const Text('Clear')),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _searchHistory.isEmpty
                ? const Center(child: Text('No search history'))
                : ListView.builder(
                    itemCount: _searchHistory.length,
                    itemBuilder: (context, idx) {
                      final s = _searchHistory[idx];
                      return ListTile(title: Text(s));
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadActionHistory,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _actionHistory.isEmpty
              ? ListView(children: const [Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No action history')))])
              : ListView.builder(
                  itemCount: _actionHistory.length,
                  itemBuilder: (context, idx) {
                    final h = _actionHistory[idx] as Map<String, dynamic>;
                    return ListTile(
                      title: Text(h['nama_barang'] ?? '—'),
                      subtitle: Text('${h['aksi'] ?? '-'} • ${h['username'] ?? '-'} • ${h['tanggal'] ?? '-'}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          final id = h['id'];
                          if (id != null) _deleteActionHistory(id as int);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

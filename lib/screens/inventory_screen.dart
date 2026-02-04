
import 'package:flutter/material.dart';

class InventoryScreen extends StatefulWidget {
  // Accept an optional search query.
  final String? searchQuery;

  const InventoryScreen({Key? key, this.searchQuery}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // If a search query is passed from the camera screen, populate the text field.
    if (widget.searchQuery != null) {
      _searchController.text = widget.searchQuery!;
      // TODO: Trigger search with the initial query.
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Tool',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // TODO: Implement search logic.
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Placeholder for search results
            Expanded(
              child: Center(
                child: widget.searchQuery != null
                    ? Text("Searching for: ${widget.searchQuery}")
                    : const Text('Search for a tool to see results.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

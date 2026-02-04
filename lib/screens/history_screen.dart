
import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Action History'),
      ),
      body: const Center(
        child: Text('A log of all actions (take/put) will be shown here.'),
      ),
    );
  }
}

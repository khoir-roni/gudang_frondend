
import 'package:flutter/material.dart';
import 'package:frontend/router.dart'; // Import the router

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use MaterialApp.router to integrate GoRouter.
    return MaterialApp.router(
      routerConfig: router, // Pass the router configuration
      title: 'Warehouse Manager',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}

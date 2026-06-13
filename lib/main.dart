import 'package:flutter/material.dart';

void main() {
  runApp(const CloudNexApp());
}

class CloudNexApp extends StatelessWidget {
  const CloudNexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CloudNex PDF Pro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CloudNex PDF Pro")),
      body: const Center(
        child: Text("Ready for your PDF Engine!"),
      ),
    );
  }
}
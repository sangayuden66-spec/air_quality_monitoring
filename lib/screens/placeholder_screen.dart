import 'package:flutter/material.dart';

/// Simple placeholder used until each tab gets its real implementation.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title — coming soon',
        style: const TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }
}
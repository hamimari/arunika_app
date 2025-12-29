import 'package:flutter/material.dart';

class AppProgress extends StatelessWidget {
  final double value;

  const AppProgress({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 8,
        backgroundColor: Colors.grey[300],
        valueColor:
        const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
      ),
    );
  }
}

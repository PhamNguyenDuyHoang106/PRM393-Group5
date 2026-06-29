import 'package:flutter/material.dart';

class EmptyWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const EmptyWidget({
    super.key,
    this.title = 'No Data Found',
    this.message = 'There is nothing here to display right now.',
    this.icon = Icons.folder_open,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

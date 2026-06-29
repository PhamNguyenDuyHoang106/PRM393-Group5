import 'package:flutter/material.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Statistics')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pie_chart, size: 80, color: Colors.blue),
              SizedBox(height: 16),
              Text(
                'Task Status Distribution',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('TODO: 33% | IN_PROGRESS: 17% | DONE: 50%', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

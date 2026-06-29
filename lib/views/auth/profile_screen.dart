import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hoang Team Lead',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text('manager@example.com'),
              const Text('Role: Manager', style: TextStyle(color: Colors.blue)),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => context.go('/login'),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

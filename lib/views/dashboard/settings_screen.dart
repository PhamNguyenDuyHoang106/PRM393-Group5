import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle light or dark interface theme'),
            value: false,
            onChanged: (val) {},
          ),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive push alerts for deadline limits'),
            value: true,
            onChanged: (val) {},
          ),
          const Divider(),
          ListTile(
            title: const Text('About App'),
            subtitle: const Text('Smart Task Management v1.0.0 (PRM393 MVP)'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

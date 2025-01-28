import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final Function(int) onTimeoutChanged; // Callback to notify parent of timeout changes
  final int currentTimeout; // Current timeout value in seconds

  SettingsScreen({required this.onTimeoutChanged, required this.currentTimeout});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int selectedTimeout; // Timeout in seconds

  @override
  void initState() {
    super.initState();
    selectedTimeout = widget.currentTimeout; // Initialize with the current timeout
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Inactivity Timeout (minutes):",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: selectedTimeout.toDouble(),
              min: 1, // Minimum 1 minute
              max: 30, // Maximum 30 minutes
              divisions: 30,
              label: "$selectedTimeout min",
              onChanged: (value) {
                setState(() {
                  selectedTimeout = value.toInt();
                });
              },
              onChangeEnd: (value) {
                widget.onTimeoutChanged(selectedTimeout); // Notify parent
              },
            ),
            Text(
              "Turn off AC after $selectedTimeout minutes of no motion.",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

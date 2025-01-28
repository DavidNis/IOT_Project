import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SettingsScreen extends StatefulWidget {
  final Function(int) onTimeoutChanged; // Callback for inactivity timeout changes
  final int currentTimeout; // Current timeout in minutes
  final Function(Map<String, dynamic>) onFavoriteChanged; // Callback for favorite settings
  final Map<String, dynamic> favoriteSettings; // Current favorite settings
  final bool isMyFavoriteActive; // Whether My Favorite toggle is active
  final Function applyFavoriteSettings; // Callback to apply favorite settings immediately

  SettingsScreen({
    required this.onTimeoutChanged,
    required this.currentTimeout,
    required this.onFavoriteChanged,
    required this.favoriteSettings,
    required this.isMyFavoriteActive,
    required this.applyFavoriteSettings,
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int selectedTimeout;
  late String selectedMode;
  late String selectedFanSpeed;
  late double selectedTemperature;

  @override
  void initState() {
    super.initState();
    selectedTimeout = widget.currentTimeout;
    selectedMode = widget.favoriteSettings['mode'] ?? 'Cool';
    selectedFanSpeed = widget.favoriteSettings['fanSpeed'] ?? 'Low';
    selectedTemperature = widget.favoriteSettings['temperature'] ?? 24.0;
  }

  void _saveTimeoutToFirebase(int timeout) async {
    try {
      await FirebaseDatabase.instance.ref('transmitter').update({
        'inactivityTimeout': timeout,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inactivity timeout saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onTimeoutChanged(timeout); // Update the main screen timeout
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save timeout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveFavoriteSettingsToFirebase(Map<String, dynamic> favorites) async {
    try {
      await FirebaseDatabase.instance.ref('transmitter').update({
        'mode': favorites['mode'],
        'fanSpeed': favorites['fanSpeed'],
        'temp': favorites['temperature'],
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Favorite settings saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // If "My Favorite" is active, apply the new settings immediately
      if (widget.isMyFavoriteActive) {
        widget.applyFavoriteSettings();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save favorite settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              "Inactivity Timeout (minutes):",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: selectedTimeout.toDouble(),
              min: 1,
              max: 30,
              divisions: 30,
              label: "$selectedTimeout min",
              onChanged: (value) {
                setState(() {
                  selectedTimeout = value.toInt();
                });
              },
            ),
            Text(
              "Turn off AC after $selectedTimeout minutes of no motion.",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Save Timeout Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Save timeout to Firebase
                  _saveTimeoutToFirebase(selectedTimeout);
                },
                child: const Text('Save Timeout Changes'),
              ),
            ),
            const Divider(height: 32),

            const Text(
              "Favorite Settings:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Favorite Mode
            const Text("Mode:"),
            DropdownButton<String>(
              value: selectedMode,
              items: ['Cool', 'Heat'].map((String mode) {
                return DropdownMenuItem<String>(
                  value: mode,
                  child: Text(mode),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedMode = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Favorite Fan Speed
            const Text("Fan Speed:"),
            DropdownButton<String>(
              value: selectedFanSpeed,
              items: ['Low', 'High'].map((String speed) {
                return DropdownMenuItem<String>(
                  value: speed,
                  child: Text(speed),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedFanSpeed = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Favorite Temperature
            const Text("Temperature:"),
            Slider(
              value: selectedTemperature,
              min: 16.0,
              max: 30.0,
              divisions: 14,
              label: "${selectedTemperature.toInt()}°C",
              onChanged: (value) {
                setState(() {
                  selectedTemperature = value;
                });
              },
            ),
            Text(
              "Set temperature to ${selectedTemperature.toInt()}°C.",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Save Changes Button for Favorites
            Center(
              child: ElevatedButton(
                onPressed: () {
                  final updatedFavorites = {
                    'mode': selectedMode,
                    'fanSpeed': selectedFanSpeed,
                    'temperature': selectedTemperature,
                  };

                  // Save the favorite settings locally
                  widget.onFavoriteChanged(updatedFavorites);

                  // Save the favorite settings to Firebase
                  _saveFavoriteSettingsToFirebase(updatedFavorites);
                },
                child: const Text('Save Favorite Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

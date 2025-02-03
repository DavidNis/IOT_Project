import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SettingsScreen extends StatefulWidget {
  final Function(int) onTimeoutChanged;
  final int currentTimeout;

  // Callback that notifies the parent widget about updated favorites
  final Function(Map<String, dynamic>) onFavoriteChanged;

  // The parent’s current favorite settings
  final Map<String, dynamic> favoriteSettings;

  // Whether "My Favorite" toggle is active
  final bool isMyFavoriteActive;

  // The parent’s method to apply favorites to the AC (if needed),
  // but we won't be calling it here (since we only save to "favorites" in Firebase).
  final Function applyFavoriteSettings;

  const SettingsScreen({
    Key? key,
    required this.onTimeoutChanged,
    required this.currentTimeout,
    required this.onFavoriteChanged,
    required this.favoriteSettings,
    required this.isMyFavoriteActive,
    required this.applyFavoriteSettings,
  }) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int selectedTimeout;
  late String selectedMode;
  late String selectedFanSpeed;
  late double selectedTemperature;

  String newMode = "Cool";
  String newFanSpeed = "Low";
  double newTemperature = 24.0;

  // Options for inactivity timeout in seconds
  final List<int> timeoutOptions = [
    10, 20, 30, 40, 50, 60, 120, 180, 240, 300, 360, 420, 480, 540, 600
  ];

  @override
  void initState() {
    super.initState();

        _loadInitialSettingsFromFirebase();


    // Initialize local state for inactivity timeout
    selectedTimeout = widget.currentTimeout;

    // Initialize local state for favorite settings
    selectedMode = widget.favoriteSettings['mode'] ?? 'Cool';
    selectedFanSpeed = widget.favoriteSettings['fanSpeed'] ?? 'Low';
    selectedTemperature = widget.favoriteSettings['temperature'] ?? 24.0;

    // Ensure valid defaults for Mode and Fan Speed
    if (!['Cool', 'Heat'].contains(selectedMode)) {
      selectedMode = 'Cool';
    }
    if (!['Low', 'High'].contains(selectedFanSpeed)) {
      selectedFanSpeed = 'Low';
    }
  }

 Future<void> _loadInitialSettingsFromFirebase() async {
    try {
      // Reference your /favorites node
      final ref = FirebaseDatabase.instance.ref('favorites');
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        
        // Safely parse the data and update local states
        setState(() {
          selectedMode = data['mode']?.toString() ?? 'Cool';
          selectedFanSpeed = data['fanSpeed']?.toString() ?? 'Low';
          selectedTemperature =
              double.tryParse(data['temperature']?.toString() ?? '24.0') ?? 24.0;
        });
      } else {
        print('No favorite settings found in Firebase.');
      }
    } catch (e) {
      print('Error fetching initial settings: $e');
    }
  }

  /// Save the user's selected inactivity timeout to Firebase under "transmitter/inactivityTimeout"
  void _saveTimeoutToFirebase(int timeout) async {
    try {
      await FirebaseDatabase.instance.ref('transmitter').update({
        'inactivityTimeout': timeout,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inactivity timeout saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      widget.onTimeoutChanged(timeout); // Notify parent widget
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save timeout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Save the user's favorite settings to Firebase **under "favorites"** only
  /// This will NOT change AC or transmit anything.
  Future<void> _saveFavoriteSettingsToFirebase(
      Map<String, dynamic> favorites) async {
    try {
      // Save them under /favorites node (or any path you prefer)
      await FirebaseDatabase.instance.ref('favorites').set({
        'mode': favorites['mode'],
        'fanSpeed': favorites['fanSpeed'],
        'temperature': favorites['temperature'],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Favorite settings saved successfully!'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
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
            // -------------------------- TIMEOUT SETTING -------------------------
            const Text(
              "Inactivity Timeout:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: timeoutOptions.indexOf(selectedTimeout).toDouble(),
              min: 0,
              max: (timeoutOptions.length - 1).toDouble(),
              divisions: timeoutOptions.length - 1,
              label: selectedTimeout < 60
                  ? "$selectedTimeout seconds"
                  : "${(selectedTimeout / 60).toStringAsFixed(0)} minutes",
              onChanged: (value) {
                setState(() {
                  selectedTimeout = timeoutOptions[value.toInt()];
                });
              },
            ),
            Text(
              selectedTimeout < 60
                  ? "Turn off AC after $selectedTimeout seconds of no motion."
                  : "Turn off AC after ${(selectedTimeout / 60).toStringAsFixed(0)} minutes of no motion.",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            Center(
              child: ElevatedButton(
                onPressed: () {
                  _saveTimeoutToFirebase(selectedTimeout);
                },
                child: const Text('Save Timeout Changes'),
              ),
            ),
            const Divider(height: 32),

            // ----------------------- FAVORITE SETTINGS ------------------------
            const Text(
              "Favorite Settings:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Mode
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

            // Fan Speed
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

            // Temperature
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

            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final updatedFavorites = {
                    'mode': selectedMode,
                    'fanSpeed': selectedFanSpeed,
                    'temperature': selectedTemperature,
                  };

                  // 1. Update the local favorite settings in the parent
                  widget.onFavoriteChanged(updatedFavorites);

                  // 2. Always save to "favorites" in Firebase,
                  //    regardless of whether "My Favorite" is active
                  //    (or you can conditionally do so if you prefer).
                  await _saveFavoriteSettingsToFirebase(updatedFavorites);

                  // 3. IMPORTANT: We do NOT call `applyFavoriteSettings` here,
                  //    because you said you don't want it to update the AC or transmit anything.
                  //    So we do nothing else.
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

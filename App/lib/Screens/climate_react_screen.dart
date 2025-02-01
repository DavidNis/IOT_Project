import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ClimateReactScreen extends StatefulWidget {
  @override
  _ClimateReactScreenState createState() => _ClimateReactScreenState();
}

class _ClimateReactScreenState extends State<ClimateReactScreen> {
  final DatabaseReference databaseRef = FirebaseDatabase.instance.ref();

  double tempAbove = 0; // Temperature when AC reacts above
  double tempBelow = 0; // Temperature when AC reacts below
  bool changeACStateAbove = false;
  bool changeACStateBelow = false;

  // Settings for "Change AC State"
  String acStateAbove = "On";
  String acStateBelow = "On";
  String modeAbove = "Cool";
  String modeBelow = "Heat";
  String fanLevelAbove = "Low";
  String fanLevelBelow = "Low";
  String swingAbove = "Stopped";
  String swingBelow = "Stopped";
  int temperatureAbove = 24;
  int temperatureBelow = 22;

  @override
  void initState() {
    super.initState();
    _loadSettingsFromFirebase();
  }

  /// Fetch the existing settings from Firebase and update the local state
  Future<void> _loadSettingsFromFirebase() async {
    try {
      final snapshot = await databaseRef.child("climateReact").get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>?;

        if (data != null) {
          final aboveData = data["above"] as Map<dynamic, dynamic>?;
          final belowData = data["below"] as Map<dynamic, dynamic>?;

          if (aboveData != null) {
            setState(() {
              changeACStateAbove = aboveData["aboveActive"] ?? false;
              tempAbove = (aboveData["aboveTemp"] ?? 0).toDouble();
              fanLevelAbove = aboveData["setFan"] ?? "Low";
              modeAbove = aboveData["setMode"] ?? "Cool";
              swingAbove = aboveData["swing"] ?? "Stopped";
              temperatureAbove = aboveData["setTemp"] ?? 24;
            });
          }
          if (belowData != null) {
            setState(() {
              changeACStateBelow = belowData["belowActive"] ?? false;
              tempBelow = (belowData["belowTemp"] ?? 0).toDouble();
              fanLevelBelow = belowData["setFan"] ?? "Low";
              modeBelow = belowData["setMode"] ?? "Heat";
              swingBelow = belowData["swing"] ?? "Stopped";
              temperatureBelow = belowData["setTemp"] ?? 22;
            });
          }
        }
      }
    } catch (e) {
      print("Error loading data from Firebase: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Climate React"),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trigger Dropdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Trigger",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: "Temperature",
                    items: ["Temperature"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (_) {},
                    icon: SizedBox.shrink(),
                  ),
                ],
              ),
              Divider(),

              // When temperature goes above
              _buildTemperatureSection(
                label: "When temperature goes above",
                currentTemp: tempAbove,
                onMinusPressed: () {
                  setState(() {
                    if (tempAbove > 0) tempAbove--;
                  });
                },
                onPlusPressed: () {
                  setState(() {
                    if (tempAbove < 50) tempAbove++;
                  });
                },
                onSliderChanged: (value) {
                  setState(() {
                    tempAbove = value;
                  });
                },
                tempValue: "${tempAbove.toInt()}°",
                isACStateEnabled: changeACStateAbove,
                onACStateChanged: (value) {
                  setState(() {
                    // If the user is checking "above" on (value == true),
                    // uncheck the "below" one.
                    if (value == true) {
                      changeACStateBelow = false;
                    }
                    changeACStateAbove = value!;
                  });
                },
                settings: _buildACSettings(
                  acState: acStateAbove,
                  mode: modeAbove,
                  fanLevel: fanLevelAbove,
                  swing: swingAbove,
                  temperature: temperatureAbove,
                  onACStateChanged: (value) {
                    setState(() {
                      acStateAbove = value!;
                    });
                  },
                  onModeChanged: (value) {
                    setState(() {
                      modeAbove = value!;
                    });
                  },
                  onFanLevelChanged: (value) {
                    setState(() {
                      fanLevelAbove = value!;
                    });
                  },
                  onSwingChanged: (value) {
                    setState(() {
                      swingAbove = value!;
                    });
                  },
                  onTemperatureChanged: (value) {
                    setState(() {
                      temperatureAbove = value!;
                    });
                  },
                ),
              ),

              Divider(),

              // When temperature goes below
              _buildTemperatureSection(
                label: "When temperature goes below",
                currentTemp: tempBelow,
                onMinusPressed: () {
                  setState(() {
                    if (tempBelow > 0) tempBelow--;
                  });
                },
                onPlusPressed: () {
                  setState(() {
                    if (tempBelow < 50) tempBelow++;
                  });
                },
                onSliderChanged: (value) {
                  setState(() {
                    tempBelow = value;
                  });
                },
                tempValue: "${tempBelow.toInt()}°",
                isACStateEnabled: changeACStateBelow,
                onACStateChanged: (value) {
                  setState(() {
                    // If the user is checking "below" on (value == true),
                    // uncheck the "above" one.
                    if (value == true) {
                      changeACStateAbove = false;
                    }
                    changeACStateBelow = value!;
                  });
                },
                settings: _buildACSettings(
                  acState: acStateBelow,
                  mode: modeBelow,
                  fanLevel: fanLevelBelow,
                  swing: swingBelow,
                  temperature: temperatureBelow,
                  onACStateChanged: (value) {
                    setState(() {
                      acStateBelow = value!;
                    });
                  },
                  onModeChanged: (value) {
                    setState(() {
                      modeBelow = value!;
                    });
                  },
                  onFanLevelChanged: (value) {
                    setState(() {
                      fanLevelBelow = value!;
                    });
                  },
                  onSwingChanged: (value) {
                    setState(() {
                      swingBelow = value!;
                    });
                  },
                  onTemperatureChanged: (value) {
                    setState(() {
                      temperatureBelow = value!;
                    });
                  },
                ),
              ),

              Divider(),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
  try {
    // The parent node can be anything you want, e.g. "climateReact"
      final DatabaseReference databaseRef = FirebaseDatabase.instance.ref();
    await databaseRef.child("climateReact").set({
      "above": {
        "aboveActive": changeACStateAbove,    // true/false from checkbox
        "aboveTemp": tempAbove.toInt(),      // your slider value
        "setFan": fanLevelAbove,             // e.g. "Auto", "High", ...
        "setMode": modeAbove,                   // "Cool" or "Heat", etc.
        "swing": swingAbove,
        "setTemp": temperatureAbove,     // AC set temperature
      },
      "below": {
        "belowActive": changeACStateBelow,
        "belowTemp": tempBelow.toInt(),
        "setFan": fanLevelBelow,
        "setMode": modeBelow,
        "swing": swingBelow,
        "setTemp": temperatureBelow,
      },
    });

    print("Settings saved to Firebase.");
    // Optionally show a snackbar or any UI feedback
  } catch (e) {
    print("Error saving to Firebase: $e");
    // Handle error
  }
},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    "Save",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemperatureSection({
    required String label,
    required double currentTemp,
    required VoidCallback onMinusPressed,
    required VoidCallback onPlusPressed,
    required ValueChanged<double> onSliderChanged,
    required String tempValue,
    required bool isACStateEnabled,
    required ValueChanged<bool?> onACStateChanged,
    required Widget settings,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            IconButton(icon: Icon(Icons.remove), onPressed: onMinusPressed),
            Expanded(
              child: Slider(
                value: currentTemp,
                min: 0,
                max: 50,
                onChanged: onSliderChanged,
              ),
            ),
            IconButton(icon: Icon(Icons.add), onPressed: onPlusPressed),
            Text(tempValue),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.power_settings_new, color: Colors.teal),
                SizedBox(width: 8),
                Text("Change AC state"),
              ],
            ),
            Checkbox(value: isACStateEnabled, onChanged: onACStateChanged),
          ],
        ),
        if (isACStateEnabled) settings,
      ],
    );
  }

  Widget _buildACSettings({
    required String acState,
    required String mode,
    required String fanLevel,
    required String swing,
    required int temperature,
    required ValueChanged<String?> onACStateChanged,
    required ValueChanged<String?> onModeChanged,
    required ValueChanged<String?> onFanLevelChanged,
    required ValueChanged<String?> onSwingChanged,
    required ValueChanged<int?> onTemperatureChanged,
  }) {
    return Container(
      color: Colors.black.withOpacity(0.1),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildDropdownRow("AC state", acState, ["On"], onACStateChanged),
          _buildDropdownRow("Mode", mode, ["Cool", "Heat"], onModeChanged),
          _buildDropdownRow(
              "Fan level", fanLevel, ["Low", "High"], onFanLevelChanged),
          _buildDropdownRow(
              "Swing", swing, ["Stopped", "Vertical", "Horizontal"], onSwingChanged),
          _buildDropdownRow(
              "Temperature",
              temperature.toString(),
              List.generate(16, (index) => (16 + index).toString()),
              (value) {
            onTemperatureChanged(int.tryParse(value!));
          }),
        ],
      ),
    );
  }

  Widget _buildDropdownRow(
      String title, String currentValue, List<String> options, ValueChanged<String?> onChanged) {
    return ListTile(
      title: Text(title, style: TextStyle(fontSize: 16)),
      trailing: DropdownButton<String>(
        value: currentValue,
        onChanged: onChanged,
        items: options
            .map((option) => DropdownMenuItem(
                  value: option,
                  child: Text(option),
                ))
            .toList(),
      ),
    );
  }
}

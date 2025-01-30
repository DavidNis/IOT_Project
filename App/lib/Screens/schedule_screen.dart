import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  TimeOfDay selectedTime = TimeOfDay.now();
  List<bool> repeatDays = List.generate(7, (index) => false);
  bool changeAcState = true;
  String acState = "On";
  String mode = "Heat";
  double temperature = 24;
  String fanSpeed = "Medium";

  final DatabaseReference scheduleRef = FirebaseDatabase.instance.ref().child('Schedule');
  StreamSubscription<DatabaseEvent>? _scheduleSubscription;

  @override
  void initState() {
    super.initState();
    _loadScheduleFromFirebase(); // Load saved schedule on page entry
  }

  @override
  void dispose() {
    _scheduleSubscription?.cancel();
    super.dispose();
  }

  // Load schedule from Firebase on page entry
  Future<void> _loadScheduleFromFirebase() async {
    try {
      _scheduleSubscription = scheduleRef.onValue.listen((event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;

        if (data != null) {
          if (!mounted) return;
          setState(() {
            // Time
            if (data.containsKey("runAt") && data["runAt"] is String) {
              List<String> timeParts = data["runAt"].split(":");
              if (timeParts.length == 2) {
                selectedTime = TimeOfDay(
                  hour: int.tryParse(timeParts[0]) ?? selectedTime.hour,
                  minute: int.tryParse(timeParts[1]) ?? selectedTime.minute,
                );
              }
            }

            // Repeat Days
            if (data.containsKey("repeatDays") && data["repeatDays"] is String) {
              repeatDays = List.generate(7, (index) => data["repeatDays"][index] == "1");
            }

            // AC Settings
            acState = data["acState"] ?? acState;
            mode = data["mode"] ?? mode;
            temperature = (data["temperature"] is num) ? (data["temperature"] as num).toDouble() : temperature;
            fanSpeed = data["fanSpeed"] ?? fanSpeed;
          });
        }
      });
    } catch (e) {
      print("Error loading from Firebase: $e");
    }
  }

  // Function to select time using a time picker
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      if (!mounted) return;
      setState(() {
        selectedTime = picked;
      });
    }
  }

  // Save schedule to Firebase
  Future<void> saveScheduleToFirebase() async {
    final String formattedTime = "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";
    final String repeatDaysString = repeatDays.map((e) => e ? "1" : "0").join("");

    try {
      await scheduleRef.set({
        "runAt": formattedTime,
        "repeatDays": repeatDaysString,
        "acState": acState,
        "mode": mode,
        "temperature": temperature,
        "fanSpeed": fanSpeed,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Schedule saved successfully!")));
    } catch (e) {
      print("Error saving to Firebase: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to save schedule! Error: $e")));
    }
  }

  // Send schedule to ESP32
  Future<void> sendScheduleToESP32() async {
    final String esp32Url = "http://192.168.1.100/set_schedule"; // Replace with ESP32 IP

    try {
      final response = await http.post(
        Uri.parse(esp32Url),
        body: {
          "time": selectedTime.format(context),
          "days": repeatDays.map((e) => e ? "1" : "0").join(""),
          "ac_state": acState,
          "mode": mode,
          "temperature": temperature.toString(),
          "fan_speed": fanSpeed,
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Schedule sent successfully to ESP32!")));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to send schedule! Error: ${response.statusCode}")));
      }
    } catch (e) {
      print("Error sending schedule to ESP32: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to send schedule! Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text("Schedule"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Run at", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => _selectTime(context),
                  child: Text("${selectedTime.format(context)}", style: TextStyle(fontSize: 16, color: Colors.teal)),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Repeat Days
            Text("Repeat on", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                String day = "SMTWTFS"[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      repeatDays[index] = !repeatDays[index];
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: repeatDays[index] ? Colors.teal : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      day,
                      style: TextStyle(color: repeatDays[index] ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 20),

            // AC State Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Change AC state", style: TextStyle(fontSize: 16)),
                Switch(
                  value: changeAcState,
                  onChanged: (value) {
                    setState(() {
                      changeAcState = value;
                    });
                  },
                ),
              ],
            ),
            Divider(),

            // AC Settings
            if (changeAcState)
              Column(
                children: [
                  ListTile(
                    title: Text("AC State"),
                    trailing: DropdownButton<String>(
                      value: acState,
                      onChanged: (value) => setState(() => acState = value!),
                      items: ["On", "Off"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    ),
                  ),
                  ListTile(
                    title: Text("Mode"),
                    trailing: DropdownButton<String>(
                      value: mode,
                      onChanged: (value) => setState(() => mode = value!),
                      items: ["Heat", "Cool", "Fan"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    ),
                  ),
                  ListTile(
                    title: Text("Fan Speed"),
                    trailing: DropdownButton<String>(
                      value: fanSpeed,
                      onChanged: (value) => setState(() => fanSpeed = value!),
                      items: ["Low", "Medium", "High"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    ),
                  ),
                  ListTile(
                    title: Text("Temperature"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              temperature = (temperature - 1).clamp(16, 30);
                            });
                          },
                        ),
                        Text("${temperature.toStringAsFixed(1)}°C"),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              temperature = (temperature + 1).clamp(16, 30);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            Spacer(),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await saveScheduleToFirebase();
                  await sendScheduleToESP32();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: EdgeInsets.symmetric(vertical: 14)),
                child: Text("Save", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

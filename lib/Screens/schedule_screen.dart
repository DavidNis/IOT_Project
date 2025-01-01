import 'package:flutter/material.dart';
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

  // Function to select time using a time picker
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  // Function to send schedule data to ESP32
  Future<void> sendScheduleToESP32() async {
    final String esp32Url = "http://192.168.1.100/set_schedule"; // Replace with your ESP32's IP address

    final response = await http.post(
      Uri.parse(esp32Url),
      body: {
        "time": selectedTime.format(context),
        "days": repeatDays.map((e) => e ? "1" : "0").join(""), // For example "1000010"
        "ac_state": acState,
        "mode": mode,
        "temperature": temperature.toString(),
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Schedule sent successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send schedule! Error: ${response.statusCode}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context); // Ensures the current screen is popped from the stack
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
                Text(
                  "Run at",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => _selectTime(context),
                  child: Text(
                    "${selectedTime.format(context)}",
                    style: TextStyle(fontSize: 16, color: Colors.teal),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Repeat Days
            Text(
              "Repeat on",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
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
                      style: TextStyle(
                        color: repeatDays[index] ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
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

            // Temperature Adjustment
            if (changeAcState)
              Column(
                children: [
                  ListTile(
                    title: Text("AC State"),
                    trailing: DropdownButton<String>(
                      value: acState,
                      onChanged: (value) {
                        setState(() {
                          acState = value!;
                        });
                      },
                      items: ["On", "Off"]
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                    ),
                  ),
                  ListTile(
                    title: Text("Mode"),
                    trailing: DropdownButton<String>(
                      value: mode,
                      onChanged: (value) {
                        setState(() {
                          mode = value!;
                        });
                      },
                      items: ["Cool", "Heat", "Fan", "Dry", "Auto"] // TODO: maybe remove anything but cool and heat.
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                    ),
                  ),
                  ListTile(
                    title: Text("Temperature"),
                    trailing: DropdownButton<double>(
                      value: temperature,
                      onChanged: (value) {
                        setState(() {
                          temperature = value!;
                        });
                      },
                      items: List.generate(
                          15, (index) => (16 + index).toDouble())
                          .map((e) => DropdownMenuItem(value: e, child: Text("$e")))
                          .toList(),
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
                  await sendScheduleToESP32();
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
    );
  }
}

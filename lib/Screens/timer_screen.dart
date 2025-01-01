import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class TimerScreen extends StatefulWidget {
  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  int selectedHours = 0;
  int selectedMinutes = 0;
  bool isTimerRunning = false;
  int remainingSeconds = 0;
  Timer? timer;

  void _startTimer() {
    setState(() {
      remainingSeconds = (selectedHours * 3600) + (selectedMinutes * 60);
      isTimerRunning = true;
    });

    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      setState(() {
        if (remainingSeconds > 0) {
          remainingSeconds--;
        } else {
          t.cancel();
          isTimerRunning = false;
          _powerOffAC();
        }
      });
    });
  }

  void _cancelTimer() {
    setState(() {
      timer?.cancel();
      isTimerRunning = false;
      remainingSeconds = 0;
    });
  }

  Future<void> _powerOffAC() async {
    const String esp32Url = "http://192.168.4.1/power"; // Replace with your ESP32 IP address
    const String powerOffCommand = "off"; // Command to power off the AC

    try {
      final response = await http.post(
        Uri.parse(esp32Url),
        body: {"state": powerOffCommand},
      );

      if (response.statusCode == 200) {
        print("AC Powered Off");
      } else {
        print("Failed to power off AC: ${response.statusCode}");
      }
    } catch (error) {
      print("Error while powering off AC: $error");
    }
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 80, // Increases the height of the AppBar for the larger content
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.timer,
              color: Colors.white, 
              size: 40,
            ),
            SizedBox(width: 16), // Space between the icon and the text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Timer",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Never forget to turn off your AC",
                  style: TextStyle(
                    color: Colors.white70, 
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isTimerRunning
                    ? "The AC will turn off in"
                    : "Set the AC timer",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black87,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 40),
              if (isTimerRunning)
                Text(
                  _formatTime(remainingSeconds),
                  style: TextStyle(
                    fontSize: 60,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPicker(
                      "hours",
                      24,
                      selectedHours,
                      (value) {
                        setState(() {
                          selectedHours = value;
                        });
                      },
                    ),
                    SizedBox(width: 10),
                    _buildPicker(
                      "min.",
                      60,
                      selectedMinutes,
                      (value) {
                        setState(() {
                          selectedMinutes = value;
                        });
                      },
                    ),
                  ],
                ),
              SizedBox(height: 60),
              ElevatedButton(
                onPressed: isTimerRunning ? _cancelTimer : _startTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTimerRunning ? Colors.red : Colors.teal,
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  isTimerRunning ? "Cancel Timer" : "Start Timer",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPicker(String label, int itemCount, int selectedValue,
      ValueChanged<int> onSelectedItemChanged) {
    return Column(
      children: [
        Container(
          height: 100,
          width: 60,
          child: ListWheelScrollView.useDelegate(
            itemExtent: 40,
            physics: FixedExtentScrollPhysics(),
            onSelectedItemChanged: onSelectedItemChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                return Center(
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: index == selectedValue
                          ? Colors.grey[300]
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      index.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: index == selectedValue
                            ? Colors.black
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                );
              },
              childCount: itemCount,
            ),
          ),
        ),
        SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

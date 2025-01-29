import 'package:flutter/material.dart';
import '../Utils/timer_manager.dart';

class TimerScreen extends StatefulWidget {
  final Function togglePower;
  final bool isACOn;

  TimerScreen({required this.togglePower, required this.isACOn});

  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  int selectedHours = 0;
  int selectedMinutes = 0;
  int selectedSeconds = 0;
  final TimerManager _timerManager = TimerManager();

  @override
  void initState() {
    super.initState();
    _timerManager.remainingSecondsNotifier.addListener(_updateState);
  }

  @override
  void dispose() {
    _timerManager.remainingSecondsNotifier.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 80,
        title: Text(
          "Timer",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _timerManager.isRunning()
                    ? "Turn the AC off in:"
                    : "Set the AC Timer:",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPicker(
                    "Hours",
                    24,
                    selectedHours,
                    (value) => setState(() => selectedHours = value),
                    enabled: !_timerManager.isRunning(),
                  ),
                  SizedBox(width: 15),
                  _buildPicker(
                    "Min",
                    60,
                    selectedMinutes,
                    (value) => setState(() => selectedMinutes = value),
                    enabled: !_timerManager.isRunning(),
                  ),
                  SizedBox(width: 15),
                  _buildPicker(
                    "Sec",
                    60,
                    selectedSeconds,
                    (value) => setState(() => selectedSeconds = value),
                    enabled: !_timerManager.isRunning(),
                  ),
                ],
              ),
              SizedBox(height: 40),
              ValueListenableBuilder<int>(
                valueListenable: _timerManager.remainingSecondsNotifier,
                builder: (context, remainingSeconds, child) {
                  return Text(
                    _timerManager.isRunning()
                        ? _formatTime(remainingSeconds)
                        : "",
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  );
                },
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: !_timerManager.isRunning() && widget.isACOn
                    ? () {
                        int totalSeconds = (selectedHours * 3600) +
                            (selectedMinutes * 60) +
                            selectedSeconds;
                        _timerManager.startTimer(totalSeconds, () {
                          widget.togglePower(); // Turn off the AC
                          print("AC turned off.");
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      !_timerManager.isRunning() && widget.isACOn
                          ? Colors.teal
                          : Colors.grey,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "Start Timer",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _timerManager.isRunning()
                    ? () {
                        _timerManager.stopTimer();
                        print("Timer canceled.");
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _timerManager.isRunning()
                      ? Colors.red
                      : Colors.grey,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "Cancel Timer",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPicker(String label, int itemCount, int selectedValue,
      ValueChanged<int> onSelectedItemChanged,
      {required bool enabled}) {
    return Column(
      children: [
        Container(
          height: 120,
          width: 80,
          child: ListWheelScrollView.useDelegate(
            itemExtent: 50,
            physics:
                enabled ? FixedExtentScrollPhysics() : NeverScrollableScrollPhysics(),
            onSelectedItemChanged: enabled ? onSelectedItemChanged : null,
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                bool isSelected = index == selectedValue;
                return Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blueAccent : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Text(
                      index.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black,
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: enabled ? Colors.black87 : Colors.grey,
          ),
        ),
      ],
    );
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }
}
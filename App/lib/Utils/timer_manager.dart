import 'dart:async';
import 'package:flutter/material.dart';

class TimerManager {
  static final TimerManager _instance = TimerManager._internal();
  factory TimerManager() => _instance;

  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  final ValueNotifier<int> remainingSecondsNotifier = ValueNotifier(0);

  TimerManager._internal();

  void startTimer(int seconds, VoidCallback onTimerEnd) {
    if (_isRunning) return; // Prevent starting multiple timers
    _remainingSeconds = seconds;
    _isRunning = true;
    remainingSecondsNotifier.value = _remainingSeconds;

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        remainingSecondsNotifier.value = _remainingSeconds;
      } else {
        stopTimer(); // Stop the timer and reset state
        onTimerEnd();
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
    _isRunning = false;
    _remainingSeconds = 0;
    remainingSecondsNotifier.value = 0;
  }

  bool isRunning() => _isRunning;

  int getRemainingSeconds() => _remainingSeconds;
}

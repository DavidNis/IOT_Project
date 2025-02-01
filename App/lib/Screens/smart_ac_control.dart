import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Services/weather_service.dart';
import '../widgets/temperature_control.dart';
import '../widgets/feature_card.dart';
import '../widgets/icon_button_feature.dart';
import '../widgets/toggle_row.dart';
import '../Screens/graphs_and_logs.dart';
import '../Screens/schedule_screen.dart';
import '../Screens/timer_screen.dart';
import '../Screens/climate_react_screen.dart';
import '../Screens/setting_screen.dart';
import '../Screens/login_screen.dart';
//import 'package:connectivity_plus/connectivity_plus.dart';


class SmartACControl extends StatefulWidget {
  @override
  _SmartACControlState createState() => _SmartACControlState();
}

class _SmartACControlState extends State<SmartACControl> {
  final List<TemperatureReading> _temperatureLog = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  //StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  //final Connectivity _connectivity = Connectivity();
  //ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _connectionSnackBarController;

  double temperature = 24;       // AC set temperature
  double outdoorTemperature = 0; // Outdoor temperature fetched from API
  double indoorTemperature = 0;  // Indoor temperature from Firebase
  double humidity = 0;           // Indoor humidity from Firebase
  double ledBrightness = 50;
  String mode = "Cool";          // Default mode
  String fanSpeed = "Low";       // Default fan speed
  bool sleepCurve = false;
  bool myFavorite = false; // Whether the favorite settings are enabled
  bool isPowerOn = true;
  bool isConnected = true;

  bool verticalSwingActive = false;
  bool horizontalSwingActive = false;
  bool lightActive = false;
  bool soundActive = false;

  bool isMonitoring = false;
  bool isManualOverride = false;
  int inactivityTimeout = 20; // Default timeout value

  // Local variables to store changes
  String newMode = "Cool";
  String newFanSpeed = "Low";
  double newTemperature = 24;

  int randomSeconds = 5;
  String randomValue = '';
  Timer? _timer;
  Timer? _inactivityTimer;
  Timer? _scheduleTimer; //schedule 

  //bool showError = false;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _snackBarController;

  
  Map<String, dynamic> favoriteSettings = {
    'mode': 'Cool',
    'fanSpeed': 'Low',
    'temperature': 24.0,
  };

  // A list of Map entries, each containing a DateTime and temperature
  List<Map<String, dynamic>> temperatureLog = [];

  Timer? _pollingTimer; // Timer to poll the set temperature from Firebase

  @override
  void initState() {
    super.initState();
    fetchCurrentTemperature();
    fetchIndoorData();
    _loadFavoriteSettings();
    initializeTemperatureLog();
    _monitorMotionSensor();
    _startListeningToRandomValue();
    // _checkConnection();
    _loadHistoricalTemperatureData();

    _listenToFavoriteSettings();


    // Start polling the userג€™s set temperature every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchSetTemperatureFromFirebase();
    });

     // Start checking the schedule every minute
    _scheduleTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkSchedule();
    });//schedule
  }


Future<void> _checkSchedule() async {
  try {
    final DatabaseReference scheduleRef = FirebaseDatabase.instance.ref().child('Schedule');
    final snapshot = await scheduleRef.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      final now = DateTime.now();
      final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);
      final currentDay = now.weekday;

      // Extract stored time
      final List<String> timeParts = (data['runAt'] ?? "").split(":");
      if (timeParts.length != 2) {
        debugPrint('Invalid scheduled time format');
        return;
      }

      final int scheduledHour = int.tryParse(timeParts[0]) ?? -1;
      final int scheduledMinute = int.tryParse(timeParts[1]) ?? -1;

      if (scheduledHour == -1 || scheduledMinute == -1) {
        debugPrint('Invalid scheduled hour or minute');
        return;
      }

      // Ensure 'repeatDays' is a valid string
      final String repeatDays = (data['repeatDays'] ?? "0000000");
      if (repeatDays.length != 7) {
        debugPrint('Invalid repeatDays format');
        return;
      }

      // Debugging statements to verify values
      debugPrint('Current day: $currentDay');
      debugPrint('Repeat days: $repeatDays');
      debugPrint('Scheduled hour: $scheduledHour');
      debugPrint('Scheduled minute: $scheduledMinute');
      debugPrint('Current hour: ${currentTime.hour}');
      debugPrint('Current minute: ${currentTime.minute}');

      // Check if todayג€™s schedule should run
      if (data['isScheduleOn'] == true &&
          scheduledHour == currentTime.hour &&
          scheduledMinute == currentTime.minute &&
          repeatDays[currentDay%7] == '1') {
        
        debugPrint('Schedule matched: Applying settings');
        debugPrint('Mode: ${data['mode']}, Fan Speed: ${data['fanSpeed']}, Temperature: ${data['temperature']}');

        // Apply the scheduled settings
        if (mounted) {
          setState(() {
            isPowerOn = data['acState'] == 'On';
            newMode = data['mode'];
            newFanSpeed = data['fanSpeed'];
            newTemperature = (data['temperature'] as num).toDouble();
          });

          // Apply changes to Firebase
          String hexCode = isPowerOn ? "F7C03F" : "F740BF";
          String hexValue = isPowerOn ? "On" : "Off";

          try {
            await FirebaseDatabase.instance
                .ref()
                .child('transmitter/onOff/code')
                .set(hexCode);
            await FirebaseDatabase.instance
                .ref()
                .child('transmitter/onOff/value')
                .set(hexValue);

            print("Power command enqueued and value set: $hexCode");
          } catch (e) {
            print("Failed to enqueue power command or set value: $e");
          }

          await _applyChanges();
        }
      } else {
        debugPrint('Schedule did not match: ${data['runAt']}');
      }
    } else {
      debugPrint('No schedule found');
    }
  } catch (e) {
    debugPrint('Error checking schedule: $e');
  }
}

  void _loadHistoricalTemperatureData() async {
  try {
    final DatabaseReference logRef = FirebaseDatabase.instance.ref('temperatureLog');
    final DataSnapshot snapshot = await logRef.get();

    if (snapshot.exists) {
      final Map<dynamic, dynamic> logs = snapshot.value as Map<dynamic, dynamic>;
      logs.forEach((key, value) {
        final DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(value['timestamp']);
        final double temp = (value['value'] as num).toDouble();
        _temperatureLog.add(TemperatureReading(timestamp: timestamp, value: temp));
      });

      // Sort logs by timestamp (oldest first)
      _temperatureLog.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      setState(() {});
    }
  } catch (e) {
    debugPrint('Error loading historical data: $e');
  }
}

  // Future<void> _checkConnection() async {
  //   final connectivityResult = await _connectivity.checkConnectivity();
  //   _updateConnectionStatus(connectivityResult);
  // }

  // void _updateConnectionStatus(ConnectivityResult result) {
  //   final hasInternet = result == ConnectivityResult.mobile ||
  //       result == ConnectivityResult.wifi;

  //   if (!hasInternet) {
  //     _showNoConnectionMessage();
  //   } else {
  //     _hideNoConnectionMessage();
  //   }

  //   setState(() {
  //     isConnected = hasInternet;
  //   });
  // }

  // void _showNoConnectionMessage() {
  //   _connectionSnackBarController = ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(
  //       content: Text('No connection'),
  //       backgroundColor: Colors.red,
  //       duration: Duration(days: 1), // Persistent until hidden
  //     ),
  //   );
  // }

  // void _hideNoConnectionMessage() {
  //   _connectionSnackBarController?.close();
  //   _connectionSnackBarController = null;
  // }




  void _startListeningToRandomValue() {
    DatabaseReference randomRef = FirebaseDatabase.instance.ref().child('random');
    randomRef.onValue.listen((event) {
      String newValue = event.snapshot.value.toString();
      if (randomValue != newValue) {
        setState(() {
          randomValue = newValue;
        });
        _hideErrorMessage();
        _resetTimer();
      }
    });
  }

void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: randomSeconds), () {
      _showErrorMessage();
    });
  }

void _showErrorMessage() {
  _snackBarController = ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Center(
        child: Text(
          'The AC is not connected',
          style: TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 10), // Retry after 10 seconds
    ),
  );

  // Retry checking connection every 10 seconds
  Timer(Duration(seconds: 10), () {
    _startListeningToRandomValue();
  });
}

  void _hideErrorMessage() {
    _snackBarController?.close();
  }


  @override
  void dispose() {
    // Cancel the timer when this widget is disposed
    _pollingTimer?.cancel();
    _timer?.cancel();
   _scheduleTimer?.cancel();
    _inactivityTimer?.cancel();
    //_connectivitySubscription?.cancel();
    super.dispose();
  }

  void _listenToFavoriteSettings() {
    final DatabaseReference favoriteRef = FirebaseDatabase.instance.ref('transmitter');

    favoriteRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;

        // Update favorite settings dynamically if the toggle is on
        if (myFavorite) {
          setState(() {
            mode = data['mode']?.toString() ?? 'Cool';
            fanSpeed = data['fanSpeed']?.toString() ?? 'Low';
            temperature = double.tryParse(data['temp']?.toString() ?? '24.0') ?? 24.0;
          });
        }
      }
    });
  }

  // Fetch the current outdoor temperature from Weather API
  Future<void> fetchCurrentTemperature() async {
    double? temp = await WeatherService().getCurrentTemperature();
    if (temp != null) {
      setState(() {
        outdoorTemperature = temp;
      });
    }
  }

  // Load the favorite settings from Firebase
  Future<void> _loadFavoriteSettings() async {
    try {
      final ref = FirebaseDatabase.instance.ref('transmitter');
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          favoriteSettings = {
            'mode': data['mode']?.toString() ?? 'Cool',
            'fanSpeed': data['fanSpeed']?.toString() ?? 'Low',
            'temperature': double.tryParse(data['temp']?.toString() ?? '24.0') ?? 24.0,
          };
        });
      }
    } catch (e) {
      debugPrint('Failed to load favorite settings: $e');
    }
  }

  // apply the favorite settings
  void _applyFavoriteSettings() async {
    try {
      // Use local favorite settings
      setState(() {
        newMode = favoriteSettings['mode'];
        newFanSpeed = favoriteSettings['fanSpeed'];
        newTemperature = favoriteSettings['temperature'];
      });

      // Apply these changes to Firebase
      await _applyChanges();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Favorite settings applied successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error applying favorite settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to apply favorite settings: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Callback when the favorite settings are changed
  void _onFavoriteChanged(Map<String, dynamic> newFavorites) {
    setState(() {
      favoriteSettings = newFavorites;

      // If My Favorite is active, apply the new settings immediately
      if (myFavorite) {
        _applyFavoriteSettings();
      }
    });
  }



  // Callback when the inactivity timeout is changed
  void _onTimeoutChanged(int newTimeout) {
    setState(() {
      inactivityTimeout = newTimeout; // Update the timeout value
    });
  }



  // Continuously listen for indoor temp & humidity from Firebase (DHT sensor)
  Future<void> fetchIndoorData() async {
    try {
      final DatabaseReference databaseRef = FirebaseDatabase.instance.ref();

      databaseRef.child("DHT/temperature").onValue.listen((event) {
        if (event.snapshot.exists) {
          setState(() {
            indoorTemperature =
                double.tryParse(event.snapshot.value.toString()) ?? 0.0;
          });
        } else {
          print("Temperature data not found in the database.");
        }
      });

      databaseRef.child("DHT/humidity").onValue.listen((event) {
        if (event.snapshot.exists) {
          setState(() {
            humidity =
                double.tryParse(event.snapshot.value.toString()) ?? 0.0;
          });
        } else {
          print("Humidity data not found in the database.");
        }
      });
    } catch (e) {
      print("Error fetching data from Firebase: $e");
    }
  }

  // Initialize the log with some example data
  void initializeTemperatureLog() {
    temperatureLog.add({
      'time': DateTime.now().subtract(const Duration(hours: 1)),
      'temperature': 23.5,
    });
    temperatureLog.add({
      'time': DateTime.now(),
      'temperature': 24.0,
    });
  }

  // get the userג€™s set temperature from firebase under`transmitter/temp/value`
  // and add it to `temperatureLog` every 5 seconds.
// In _SmartACControlState of smart_ac_control.dart
Future<void> _fetchSetTemperatureFromFirebase() async {
  try {
    final ref = FirebaseDatabase.instance.ref('transmitter/temp/value');
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final dataStr = snapshot.value.toString();
      final parsed = double.tryParse(dataStr);

      if (parsed != null) {
        // Push to historical log in Firebase
        final logRef = FirebaseDatabase.instance.ref('temperatureLog').push();
        await logRef.set({
          'timestamp': ServerValue.timestamp,
          'value': parsed,
        });

        setState(() {
          _temperatureLog.add(
            TemperatureReading(timestamp: DateTime.now(), value: parsed),
          );

          if (_temperatureLog.length > 60) {
            _temperatureLog.removeAt(0);
          }
        });
      }
    }
  } catch (e) {
    debugPrint('Error fetching temperature: $e');
  }
}

  // Toggle the AC power on/off (IR code) via Firebase
  void _togglePower() async {
    setState(() {
      isPowerOn = !isPowerOn;
      isManualOverride = true;
    });

    String hexCode = isPowerOn ? "F7C03F" : "F740BF";
    String hexValue = isPowerOn ? "On" : "Off";

    try {
      await FirebaseDatabase.instance
          .ref()
          .child('transmitter/onOff/code')
          .set(hexCode);
      await FirebaseDatabase.instance
          .ref()
          .child('transmitter/onOff/value')
          .set(hexValue);

      print("Power command enqueued and value set: $hexCode");
    } catch (e) {
      print("Failed to enqueue power command or set value: $e");
    }
  }

  // Switch between Cool/Heat mode
  void _changeMode(String newMode) {
    setState(() {
      this.newMode = newMode;
    });
  }

  // Switch fan speed between Low/High
  void _changeFanSpeed(String newFanSpeed) {
    setState(() {
      this.newFanSpeed = newFanSpeed;
    });
  }

  // Define the map for temperature to hex value mapping
  final Map<int, String> temperatureHexMap = {
    16: "F7A05F",
    17: "F710EF",
    18: "F7906F",
    19: "F750AF",
    20: "F730CF",
    21: "F7B04F",
    22: "F7708F",
    23: "F708F7",
    24: "F78877",
    25: "F748B7",
    26: "F7A857",
    27: "F7A05F",
    28: "F710EF",
    29: "F7906F",
    30: "F750AF",
  };

  // Change the userג€™s set temperature in Firebase + local state
  void _changeTemperature(double newTemperature) async {
    setState(() {
      this.newTemperature = newTemperature; // Update local state
    });

    // Generate the temperature hex code
    String temperatureHexValue =temperatureHexMap[newTemperature.toInt()] ?? "F7A05F";  

/*
    try {
      // Update the Firebase nodes
      await FirebaseDatabase.instance
          .ref()
          .child('transmitter/temp/code')
          .set(temperatureHexValue);
      await FirebaseDatabase.instance
          .ref()
          .child('transmitter/temp/value')
          .set(newTemperature.toString());
    } catch (e) {
      print("Failed to update Firebase: $e");
    }
    */
  }

    void _signOut() async {
    try {
      await FirebaseAuth.instance.signOut(); // Sign out from Firebase
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()), // Go to LoginScreen
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

 /// Monitor the motion sensor to automatically turn off AC if no motion
void _monitorMotionSensor() {
  final DatabaseReference motionSensorRef =
      FirebaseDatabase.instance.ref().child('motionSensor/value');

  motionSensorRef.onValue.listen((event) async {
    if (event.snapshot.exists && event.snapshot.value != null) {
      int motionValue = int.tryParse(event.snapshot.value.toString()) ?? 1;

      if (motionValue == 0) {
        // No motion detected, start inactivity timer
        if (_inactivityTimer == null || !_inactivityTimer!.isActive) {
          int timeoutSeconds = await _getInactivityTimeout();
          print("No motion detected. Waiting for $timeoutSeconds seconds before turning off AC.");

          _inactivityTimer = Timer(Duration(seconds: timeoutSeconds), () {
            _turnOffAC();
          });
        }
      } else {
        // Motion detected, reset timer
        _resetInactivityTimer();
      }
    }
  });
}

/// Fetch inactivityTimeout from Firebase (in seconds)
Future<int> _getInactivityTimeout() async {
  try {
    final DatabaseReference timeoutRef =
        FirebaseDatabase.instance.ref().child('transmitter/inactivityTimeout');
    final snapshot = await timeoutRef.get();

    if (snapshot.exists) {
      return int.tryParse(snapshot.value.toString()) ?? 6; // Default to 6 seconds
    }
  } catch (e) {
    print("Error fetching inactivity timeout: $e");
  }
  return 6; // Default timeout
}

/// Reset the inactivity timer if motion is detected
void _resetInactivityTimer() {
  if (_inactivityTimer != null) {
    _inactivityTimer!.cancel();
    _inactivityTimer = null;
  }
}


  /// Turn off AC via IR command
  Future<void> _turnOffAC() async {
    try {
      await FirebaseDatabase.instance
          .ref()
          .child('transmitter/onOff/code')
          .set('F740BF');
      await FirebaseDatabase.instance
          .ref()
          .child('transmitter/onOff/value')
          .set('Off');

      setState(() {
        isPowerOn = false;
      });
      print("AC turned off and command sent to transmitter.");
    } catch (e) {
      print("Failed to turn off AC: $e");
    }
  }

  /// Apply the current newMode, newFanSpeed, and newTemperature to Firebase
 Future<void> _applyChanges() async {
  try {
    // Update mode
    String modeHexValue = newMode == "Cool" ? "F7609F" : "F720DF";
    await FirebaseDatabase.instance
        .ref()
        .child('transmitter/mode/code')
        .set(modeHexValue);
    await FirebaseDatabase.instance
        .ref()
        .child('transmitter/mode/value')
        .set(newMode);

    // Update fan speed
    String fanSpeedHexValue = newFanSpeed == "Low" ? "F728D7" : "F76897";
    await FirebaseDatabase.instance
        .ref()
        .child('transmitter/fanSpeed/code')
        .set(fanSpeedHexValue);
    await FirebaseDatabase.instance
        .ref()
        .child('transmitter/fanSpeed/value')
        .set(newFanSpeed);

    // Update temperature
    String temperatureHexValue = temperatureHexMap[newTemperature.toInt()] ?? "F7A05F";
    await FirebaseDatabase.instance
        .ref()
        .child('transmitter/temp/code')
        .set(temperatureHexValue);
    await FirebaseDatabase.instance
        .ref()
        .child('transmitter/temp/value')
        .set(newTemperature);

    // Apply changes to the main variables
    if (mounted) {
      setState(() {
        mode = newMode;
        fanSpeed = newFanSpeed;
        temperature = newTemperature;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Changes applied successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      debugPrint('Failed to apply changes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to apply changes: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text("Bedroom AC"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    FirebaseAuth.instance.currentUser?.displayName != null
                        ? 'Welcome ${FirebaseAuth.instance.currentUser!.displayName}'
                        : 'Welcome User',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      currentTimeout: inactivityTimeout,
                      onTimeoutChanged: _onTimeoutChanged,
                      favoriteSettings: favoriteSettings,
                      onFavoriteChanged: _onFavoriteChanged,
                      isMyFavoriteActive: myFavorite,
                      applyFavoriteSettings: _applyFavoriteSettings,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('Timer'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TimerScreen(
                      togglePower: _togglePower, // Pass the togglePower function
                      isACOn: isPowerOn, // Pass the isPowerOn state
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Schedule'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScheduleScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.show_chart),
              title: const Text('Graphs & Logs'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GraphsAndLogsScreen(
                      temperatureLog: _temperatureLog,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud),
              title: const Text('Climate React'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ClimateReactScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Sign Out'),
              onTap: _signOut, // Sign out action
            ),
          ],
        ),
      ),
      
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    if (!isConnected)
                    Container(
                      width: double.infinity,
                      color: Colors.red,
                      padding: const EdgeInsets.all(8.0),
                      child: const Text(
                        'No Internet Connection',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Container(
                      width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: newMode == "Cool"
                              ? [Colors.blue[200]!, Colors.blue[50]!]
                              : [Colors.red[200]!, Colors.red[50]!],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Outdoor Temperature: ${outdoorTemperature.toInt()}ֲ°C",
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "Indoor Temperature: ${indoorTemperature.toInt()}ֲ°C",
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "Humidity: ${humidity.toInt()}%",
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.black54),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: _togglePower,
                                  child: Column(
                                    children: [
                                      Container(
                                        width: constraints.maxWidth * 0.15,
                                        height: constraints.maxWidth * 0.15,
                                        decoration: BoxDecoration(
                                          color:
                                              isPowerOn ? Colors.blue : Colors.grey,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.power_settings_new,
                                          color: Colors.white,
                                          size: constraints.maxWidth * 0.07,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        "Power",
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: constraints.maxHeight * 0.02),
                            TemperatureControl(
                              temperature: newTemperature,
                              onTemperatureChange: (value) {
                                _changeTemperature(value);
                              },
                            ),
                            SizedBox(height: constraints.maxHeight * 0.02),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 100, // Adjust as needed
                                    child: FeatureCard(
                                      title: "Mode",
                                      value: newMode,
                                      icon: Icons.ac_unit,
                                      onTap: () => _changeMode(
                                          newMode == "Cool" ? "Heat" : "Cool"),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    height: 100, // Adjust as needed
                                    child: FeatureCard(
                                      title: "Fan Speed",
                                      value: newFanSpeed,
                                      icon: Icons.air,
                                      onTap: () => _changeFanSpeed(
                                          newFanSpeed == "Low" ? "High" : "Low"),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        SizedBox(height: constraints.maxHeight * 0.02),

                            SizedBox(
  width: double.infinity, // Full width
  height: 60, // Increase height for a longer button
  child: ElevatedButton(
    onPressed: _applyChanges,
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color.fromARGB(255, 86, 143, 240), // Bolder color
      foregroundColor: Colors.white, // White text for contrast
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Bigger, bold text
      padding: const EdgeInsets.symmetric(vertical: 16), // Extra padding for better touch area
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // Slightly rounded corners
      ),
    ),
    child: const Text('Press to Set AC Settings'), // Button text
  ),
),
                            SizedBox(height: constraints.maxHeight * 0.06),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButtonFeature(
                                  label: "Light",
                                  icon: Icons.lightbulb,
                                  isActive: lightActive,
                                  onPressed: () {
                                    setState(() {
                                      lightActive = !lightActive;
                                    });
                                  },
                                ),
                                IconButtonFeature(
                                  label: "Sound",
                                  icon: Icons.volume_up,
                                  isActive: soundActive,
                                  onPressed: () {
                                    setState(() {
                                      soundActive = !soundActive;
                                    });
                                  },
                                ),
                                IconButtonFeature(
                                  label: "Horizontal Swing",
                                  icon: Icons.swap_horiz,
                                  isActive: horizontalSwingActive,
                                  onPressed: () {
                                    setState(() {
                                      horizontalSwingActive =
                                          !horizontalSwingActive;
                                    });
                                  },
                                ),
                                IconButtonFeature(
                                  label: "Vertical Swing",
                                  icon: Icons.north,
                                  isActive: verticalSwingActive,
                                  onPressed: () {
                                    setState(() {
                                      verticalSwingActive = !verticalSwingActive;
                                    });
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: constraints.maxHeight * 0.02),
                            Divider(height: 1, color: Colors.grey[300]),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                children: [
                                  ToggleRow(
                                    label: "Sleep Curve",
                                    description:
                                        "Customizes temperature and sleep times",
                                    icon: Icons.nights_stay,
                                    value: sleepCurve,
                                    onChanged: (value) {
                                      setState(() {
                                        sleepCurve = value;
                                      });
                                    },
                                  ),
                                  Divider(height: 1, color: Colors.grey[300]),
                                  ToggleRow(
                                    label: "My Favorite",
                                    description:
                                        "Choose your favorite settings",
                                    icon: Icons.favorite_border,
                                    value: myFavorite,
                                    onChanged: (value) {
                                      setState(() {
                                        myFavorite = value;
                                        if (myFavorite) {
                                          _applyFavoriteSettings();
                                        }
                                      });
                                    },
                                  ),
                                  Divider(height: 1, color: Colors.grey[300]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

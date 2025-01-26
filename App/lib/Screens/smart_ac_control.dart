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

class SmartACControl extends StatefulWidget {
  @override
  _SmartACControlState createState() => _SmartACControlState();
}

class _SmartACControlState extends State<SmartACControl> {
  final List<TemperatureReading> _temperatureLog = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  double temperature = 24;       // AC set temperature
  double outdoorTemperature = 0; // Outdoor temperature fetched from API
  double indoorTemperature = 0;  // Indoor temperature from Firebase
  double humidity = 0;           // Indoor humidity from Firebase
  double ledBrightness = 50;
  String mode = "Cool";          // Default mode
  String fanSpeed = "Low";       // Default fan speed
  bool sleepCurve = false;
  bool myFavorite = false;
  bool isPowerOn = true;

  bool verticalSwingActive = false;
  bool horizontalSwingActive = false;
  bool lightActive = false;
  bool soundActive = false;

  bool isMonitoring = false;
  bool isManualOverride = false;

  // Local variables to store changes
  String newMode = "Cool";
  String newFanSpeed = "Low";
  double newTemperature = 24;

  // A list of Map entries, each containing a DateTime and temperature
  List<Map<String, dynamic>> temperatureLog = [];

  Timer? _pollingTimer; // Timer to poll the set temperature from Firebase

  @override
  void initState() {
    super.initState();
    fetchCurrentTemperature();
    fetchIndoorData();
    initializeTemperatureLog();
    _monitorMotionSensor();

    // Start polling the user’s set temperature every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchSetTemperatureFromFirebase();
    });
  }

  @override
  void dispose() {
    // Cancel the timer when this widget is disposed
    _pollingTimer?.cancel();
    super.dispose();
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

  // get the user’s set temperature from firebase under`transmitter/temp/value`
  // and add it to `temperatureLog` every 5 seconds.
  Future<void> _fetchSetTemperatureFromFirebase() async {
    try {
      final ref = FirebaseDatabase.instance.ref('transmitter/temp/value');
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final dataStr = snapshot.value.toString(); // e.g. "23.0"
        final parsed = double.tryParse(dataStr);

        if (parsed != null) {
          setState(() {
            // add new reading
            _temperatureLog.add(
              TemperatureReading(timestamp: DateTime.now(), value: parsed),
            );

            // if we have more than 60 items (for 5 min at 5-second intervals),
            // remove the oldest item.
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

  // Change the user’s set temperature in Firebase + local state
  void _changeTemperature(double newTemperature) async {
    setState(() {
      this.newTemperature = newTemperature; // Update local state
    });

    // Generate the temperature hex code
    String temperatureHexValue =
        "F7A" + newTemperature.toInt().toRadixString(16).toUpperCase();

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
    motionSensorRef.onValue.listen((event) {
      if (event.snapshot.value == 0) {
        if (!isMonitoring) {
          isMonitoring = true;
          Future.delayed(const Duration(seconds: 6), () {
            if (isMonitoring && !isManualOverride) {
              _turnOffAC();
            }
          });
        }
      } else {
        isMonitoring = false;
        isManualOverride = false;
      }
    });
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
      String temperatureHexValue =
          "F7A" + newTemperature.toInt().toRadixString(16).toUpperCase();
      await FirebaseDatabase.instance
          .ref()
          .child('transmitter/temp/code')
          .set(temperatureHexValue);

      // Apply changes to the main variables
      setState(() {
        mode = newMode;
        fanSpeed = newFanSpeed;
        temperature = newTemperature;
      });

      //print(
          //"Changes applied: Mode: $newMode, Fan Speed: $newFanSpeed, Temperature: $newTemperature");
    } catch (e) {
      print("Failed to apply changes: $e");
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
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blueAccent,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
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
                                      "Outdoor Temperature: ${outdoorTemperature.toInt()}°C",
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "Indoor Temperature: ${indoorTemperature.toInt()}°C",
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
                            ElevatedButton(
                              onPressed: _applyChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Change'),
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

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../Services/weather_service.dart';
import '../widgets/temperature_control.dart';
import '../widgets/feature_card.dart';
import '../widgets/icon_button_feature.dart';
import '../widgets/toggle_row.dart';
import '../widgets/graphs_and_logs.dart';
import '../Screens/schedule_screen.dart';
import '../Screens/timer_screen.dart';
import '../Screens/climate_react_screen.dart';

class SmartACControl extends StatefulWidget {
  @override
  _SmartACControlState createState() => _SmartACControlState();
}

class _SmartACControlState extends State<SmartACControl> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  double temperature = 24; // AC set temperature
  double outdoorTemperature = 0; // Outdoor temperature fetched from API
  double indoorTemperature = 0; // Indoor temperature from Firebase
  double humidity = 0; // Indoor humidity from Firebase
  double ledBrightness = 50;
  String mode = "Cool"; // Default mode
  String fanSpeed = "Low"; // Default fan speed
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

  List<Map<String, dynamic>> temperatureLog = [];

  @override
  void initState() {
    super.initState();
    fetchCurrentTemperature();
    fetchIndoorData();
    initializeTemperatureLog();
    _monitorMotionSensor();
  }

  Future<void> fetchCurrentTemperature() async {
    double? temp = await WeatherService().getCurrentTemperature();
    if (temp != null) {
      setState(() {
        outdoorTemperature = temp;
      });
    }
  }

  Future<void> fetchIndoorData() async {
    try {
      final DatabaseReference databaseRef = FirebaseDatabase.instance.ref();

      databaseRef.child("DHT/temperature").onValue.listen((event) {
        if (event.snapshot.exists) {
          setState(() {
            indoorTemperature = double.tryParse(event.snapshot.value.toString()) ?? 0.0;
          });
        } else {
          print("Temperature data not found in the database.");
        }
      });

      databaseRef.child("DHT/humidity").onValue.listen((event) {
        if (event.snapshot.exists) {
          setState(() {
            humidity = double.tryParse(event.snapshot.value.toString()) ?? 0.0;
          });
        } else {
          print("Humidity data not found in the database.");
        }
      });
    } catch (e) {
      print("Error fetching data from Firebase: $e");
    }
  }

  void initializeTemperatureLog() {
    temperatureLog.add({
      'time': DateTime.now().subtract(Duration(hours: 1)),
      'temperature': 23.5
    });
    temperatureLog.add({
      'time': DateTime.now(),
      'temperature': 24.0
    });
  }

  void _togglePower() async {
    setState(() {
      isPowerOn = !isPowerOn;
      isManualOverride = true; // Set manual override to true when toggling power manually
    });

    String hexCode = isPowerOn ? "F7C03F" : "F740BF"; // IR codes for power on/off
    String hexValue = isPowerOn ? "On" : "Off"; // IR codes for power on/off

    try {
      await FirebaseDatabase.instance.ref().child('transmitter/onOff/code').set(hexCode); 
      await FirebaseDatabase.instance.ref().child('transmitter/onOff/value').set(hexValue); 

      print("Power command enqueued and value set: $hexCode");
    } catch (e) {
      print("Failed to enqueue power command or set value: $e");
    }
  }

  void _changeMode(String newMode) {
    setState(() {
      this.newMode = newMode;
    });
  }

  void _changeFanSpeed(String newFanSpeed) {
    setState(() {
      this.newFanSpeed = newFanSpeed;
    });
  }

  void _changeTemperature(double newTemperature) {
    setState(() {
      this.newTemperature = newTemperature;
    });
  }

  void _monitorMotionSensor() {
    final DatabaseReference motionSensorRef = FirebaseDatabase.instance.ref().child('motionSensor/value');
    motionSensorRef.onValue.listen((event) {
      if (event.snapshot.value == 0) {
        if (!isMonitoring) {
          isMonitoring = true;
          Future.delayed(Duration(seconds: 6), () {
            if (isMonitoring && !isManualOverride) {
              _turnOffAC();
            }
          });
        }
      } else {
        isMonitoring = false;
        isManualOverride = false; // Reset manual override when motion is detected
      }
    });
  }

  Future<void> _turnOffAC() async {
    try {
      await FirebaseDatabase.instance.ref().child('transmitter/onOff/code').set('F740BF'); // Directly set the value
      await FirebaseDatabase.instance.ref().child('transmitter/onOff/value').set('Off'); // Directly set the value

      setState(() {
        isPowerOn = false;
      });
      print("AC turned off and command sent to transmitter.");
    } catch (e) {
      print("Failed to turn off AC: $e");
    }
  }

  Future<void> _applyChanges() async {
    try {
      // Update mode
      String modeHexValue = newMode == "Cool" ? "F7609F" : "F720DF";
      await FirebaseDatabase.instance.ref().child('transmitter/mode/code').set(modeHexValue);
      await FirebaseDatabase.instance.ref().child('transmitter/mode/value').set(newMode);

      // Update fan speed
      String fanSpeedHexValue = newFanSpeed == "Low" ? "F728D7" : "F76897";
      await FirebaseDatabase.instance.ref().child('transmitter/fanSpeed/code').set(fanSpeedHexValue);
      await FirebaseDatabase.instance.ref().child('transmitter/fanSpeed/value').set(newFanSpeed);

      // Update temperature
      String temperatureHexValue = "F7A" + (newTemperature.toInt()).toRadixString(16).toUpperCase();
      await FirebaseDatabase.instance.ref().child('transmitter/temperature/code').set(temperatureHexValue);

      // Apply changes to the main variables
      setState(() {
        mode = newMode;
        fanSpeed = newFanSpeed;
        temperature = newTemperature;
      });

      print("Changes applied: Mode: $newMode, Fan Speed: $newFanSpeed, Temperature: $newTemperature");
    } catch (e) {
      print("Failed to apply changes: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Bedroom AC"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
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
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.timer),
              title: Text('Timer'),
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
              leading: Icon(Icons.calendar_today),
              title: Text('Schedule'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScheduleScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.show_chart),
              title: Text('Graphs & Logs'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GraphsAndLogsScreen(
                      temperatureLog: temperatureLog,
                      humidityLog: [], 
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.cloud),
              title: Text('Climate React'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ClimateReactScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
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
                                      style: TextStyle(fontSize: 16, color: Colors.black54),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "Indoor Temperature: ${indoorTemperature.toInt()}°C",
                                      style: TextStyle(fontSize: 16, color: Colors.black54),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "Humidity: ${humidity.toInt()}%",
                                      style: TextStyle(fontSize: 16, color: Colors.black54),
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
                                          color: isPowerOn ? Colors.blue : Colors.grey,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.power_settings_new,
                                          color: Colors.white,
                                          size: constraints.maxWidth * 0.07,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "Power",
                                        style: TextStyle(fontSize: 12, color: Colors.black54),
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
                                    height: 100, // Adjust the height as needed
                                    child: FeatureCard(
                                      title: "Mode",
                                      value: newMode,
                                      icon: Icons.ac_unit,
                                      onTap: () => _changeMode(newMode == "Cool" ? "Heat" : "Cool"),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10), // Add some spacing between the cards
                                Expanded(
                                  child: Container(
                                    height: 100, // Adjust the height as needed
                                    child: FeatureCard(
                                      title: "Fan Speed",
                                      value: newFanSpeed,
                                      icon: Icons.air,
                                      onTap: () => _changeFanSpeed(newFanSpeed == "Low" ? "High" : "Low"),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: constraints.maxHeight * 0.02),
                            ElevatedButton(
                              onPressed: _applyChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white, // Background color
                                foregroundColor: Colors.black, // Text color
                              ),
                              child: Text('Change'),
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
                                      horizontalSwingActive = !horizontalSwingActive;
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
                              padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal padding
                              child: Column(
                                children: [
                                  ToggleRow(
                                    label: "Sleep Curve",
                                    description: "Customizes temperature and sleep times",
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
                                    description: "Choose your favorite settings",
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

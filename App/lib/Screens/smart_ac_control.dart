import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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
  String fanSpeed = "Auto";
  bool sleepCurve = false;
  bool myFavorite = false;
  bool isPowerOn = true;

  bool verticalSwingActive = false;
  bool horizontalSwingActive = false;
  bool lightActive = false;
  bool soundActive = false;

  List<Map<String, dynamic>> temperatureLog = [];

  @override
  void initState() {
    super.initState();
    fetchCurrentTemperature();
    fetchIndoorData();
    initializeTemperatureLog();
  }

  Future<void> fetchCurrentTemperature() async {
    double? temp = await WeatherService().getCurrentTemperature();
    if (temp != null) {
      setState(() {
        outdoorTemperature = temp;
      });
    }
  }
  
  Future<void> updateGradientInFirebase() async {
  try {
    final DatabaseReference databaseRef = FirebaseDatabase.instance.ref();

    // Determine the gradient color code based on mode and temperature
    String gradientCode;
    if (mode == "Cool") {
      double normalizedTemp = (temperature - 16) / 14;
      normalizedTemp = normalizedTemp.clamp(0.0, 1.0);
      int hexValue = (0xF7B04F +
              ((0xF7609F - 0xF7B04F) * normalizedTemp).toInt())
          .toInt();
      gradientCode = hexValue.toRadixString(16).toUpperCase();
    } else if (mode == "Heat") {
      double normalizedTemp = (temperature - 16) / 14;
      normalizedTemp = normalizedTemp.clamp(0.0, 1.0);
      int hexValue = (0xF730CF +
              ((0xF720DF - 0xF730CF) * normalizedTemp).toInt())
          .toInt();
      gradientCode = hexValue.toRadixString(16).toUpperCase();
    } else {
      gradientCode = "000000"; // Default for unsupported modes
    }

    // Write the gradient code to Firebase
    await databaseRef.child("transmitter/code").set(gradientCode);

    print("Gradient color updated in Firebase: $gradientCode");
  } catch (e) {
    print("Failed to update gradient in Firebase: $e");
  }
}

Future<void> fetchIndoorData() async {
  try {
    // Get a reference to the Firebase Realtime Database
    final DatabaseReference databaseRef = FirebaseDatabase.instance.ref();

    // Listen for changes in the "DHT/temperature" node
    databaseRef.child("DHT/temperature").onValue.listen((event) {
      if (event.snapshot.exists) {
        // Parse and update indoor temperature
        setState(() {
          indoorTemperature = double.tryParse(event.snapshot.value.toString()) ?? 0.0;
        });
      } else {
        print("Temperature data not found in the database.");
      }
    });

    // Listen for changes in the "DHT/humidity" node
    databaseRef.child("DHT/humidity").onValue.listen((event) {
      if (event.snapshot.exists) {
        // Parse and update humidity
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
    // Initialize temperature log with dummy or historical data
    temperatureLog.add({
      'time': DateTime.now().subtract(Duration(hours: 1)),
      'temperature': 23.5
    });
    temperatureLog.add({
      'time': DateTime.now(),
      'temperature': 24.0
    });
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
                  MaterialPageRoute(builder: (context) => TimerScreen()),
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
            child: Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: mode == "Cool"
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
                          onTap: () async {
                            setState(() {
                              isPowerOn = !isPowerOn;
                            });

                            // Set the hex value based on the power state
                            String hexValue = isPowerOn ? "F7C03F" : "F740BF";

                            // write the hex value to Firebase under the "transmitter" node
                            try {
                              final DatabaseReference databaseRef = FirebaseDatabase.instance.ref();
                              await databaseRef.child("transmitter").set(hexValue);

                              print("Transmitter value updated: $hexValue");
                            } catch (e) {
                              print("Failed to update transmitter value in Firebase: $e");
                            }
                          },
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
                      temperature: temperature,
                      onTemperatureChange: (value) {
                        setState(() {
                          temperature = value;
                        });
                      },
                    ),
                    SizedBox(height: constraints.maxHeight * 0.02),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FeatureCard(
                          title: "Mode",
                          value: mode,
                          icon: Icons.ac_unit,
                          onTap: () {
                            setState(() {
                              mode = mode == "Cool" ? "Heat" : "Cool";
                            });
                          },
                        ),
                        FeatureCard(
                          title: "Fan Speed",
                          value: fanSpeed,
                          icon: Icons.air,
                          onTap: () {
                            setState(() {
                              fanSpeed = fanSpeed == "Auto" ? "High" : "Auto";
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: constraints.maxHeight * 0.02),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
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
                      ],
                    ),
                    SizedBox(height: constraints.maxHeight * 0.02),
                    Text(
                      "LED Brightness: ${ledBrightness.toInt()}%",
                      style: TextStyle(fontSize: 18),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              if (ledBrightness > 0) ledBrightness -= 10;
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              if (ledBrightness < 100) ledBrightness += 10;
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: constraints.maxHeight * 0.02),
                    Divider(height: 1, color: Colors.grey[300]),
                    ToggleRow(
                      label: "Sleep Curve",
                      description: "Customize the set temperature and sleep times",
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
            ),
          );
        },
      ),
    );
  }
}

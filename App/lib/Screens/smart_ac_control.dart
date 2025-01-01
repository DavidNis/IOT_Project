import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../Services/weather_service.dart';
import '../Services/esp32_service.dart';
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
  double indoorTemperature = 0; // Indoor temperature from ESP32
  double humidity = 0; // Indoor humidity from ESP32
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

  // Map of button labels to their respective hex codes
  final Map<String, String> buttonHexCodes = {
    "Vertical Swing": "0x1A2B",
    "Horizontal Swing": "0x3C4D",
    "Light": "0x5E6F",
    "Sound": "0x7G8H",
  };

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

  Future<void> fetchIndoorData() async {
    Map<String, double>? indoorData = await ESP32Service().fetchSensorData();
    if (indoorData != null) {
      setState(() {
        indoorTemperature = indoorData['temperature'] ?? 0;
        humidity = indoorData['humidity'] ?? 0;
      });
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

  void handleButtonPress(String buttonLabel) {
    String? hexCode = buttonHexCodes[buttonLabel];
    if (hexCode != null) {
      print('Button "$buttonLabel" pressed. Sending hex code: $hexCode');
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
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: mode == "Cool"
                ? [Colors.blue[200]!, Colors.blue[50]!]
                : [Colors.red[200]!, Colors.red[50]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
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
                      onTap: () {
                        setState(() {
                          isPowerOn = !isPowerOn;
                        });
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isPowerOn ? Colors.blue : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.power_settings_new,
                              color: Colors.white,
                              size: 30,
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
                SizedBox(height: 20),
                TemperatureControl(
                  temperature: temperature,
                  onTemperatureChange: (value) {
                    setState(() {
                      temperature = value;
                    });
                  },
                ),
                SizedBox(height: 20),
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
                SizedBox(height: 20),
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
                        handleButtonPress("Vertical Swing");
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
                        handleButtonPress("Horizontal Swing");
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
                        handleButtonPress("Light");
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
                        handleButtonPress("Sound");
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
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
                SizedBox(height: 20),
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
      ),
    );
  }
}

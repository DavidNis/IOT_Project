import 'package:flutter/material.dart';
//import 'package:firebase_core/firebase_core.dart';
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
  String fanSpeed = "Auto"; // Default fan speed
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


  Future<void> enqueueCommand(String command, dynamic value) async {
    try {
      final DatabaseReference databaseRef = FirebaseDatabase.instance.ref();

      // Check if "commandQueue" exists, initialize if null
      final snapshot = await databaseRef.child("transmitter/commandQueue").get();
      if (!snapshot.exists) {
        await databaseRef.child("transmitter/commandQueue").set({});
      }

      // Push the new command 
      await databaseRef.child("transmitter/commandQueue").push().set({
        "command": command,
        "value": value,
        "timestamp": DateTime.now().toIso8601String(),
      });

      print("Command enqueued: $command with value $value");
    } catch (e) {
      print("Failed to enqueue command: $e");
    }
  }

  Future<void> dequeueCommand() async {
    try {
      final DatabaseReference databaseRef = FirebaseDatabase.instance.ref();

      // Retrieve the current commandQueue
      final snapshot = await databaseRef.child("transmitter/commandQueue").get();

      if (snapshot.exists) {
        List<dynamic> commandQueue = List<dynamic>.from(snapshot.value as List);

        if (commandQueue.isNotEmpty) {
          // Remove the first command (FIFO behavior)
          commandQueue.removeAt(0);

          // Update the queue in Firebase
          await databaseRef.child("transmitter/commandQueue").set(commandQueue);

          print("Dequeued the first command successfully.");
        } else {
          print("Command queue is empty, nothing to dequeue.");
        }
      } else {
        print("Command queue does not exist.");
      }
    } catch (e) {
      print("Failed to dequeue command: $e");
    }
  }



  Future<void> clearCommandQueue() async {
    try {
      final DatabaseReference databaseRef = FirebaseDatabase.instance.ref();
      await databaseRef.child("transmitter/commandQueue").remove(); // Removes the queue (null)
      print("Command queue cleared.");
    } catch (e) {
      print("Failed to clear command queue: $e");
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
  });

  String hexValue = isPowerOn ? "F7C03F" : "F740BF"; // IR codes for power on/off

  try {
    if (!isPowerOn) {
      // Clear the queue when turning off the AC
      await clearCommandQueue();
    }
    await enqueueCommand("togglePower", hexValue); // Add power toggle command to queue
    print("Power command enqueued: $hexValue");
  } catch (e) {
    print("Failed to enqueue power command: $e");
  }
}

  void _changeMode(String newMode) async {
    setState(() {
      mode = newMode;
    });

    String hexValue = mode == "Cool" ? "F7609F" : "F720DF";

    try {
      await enqueueCommand("changeMode", hexValue); // Add command to queue
      print("Mode command enqueued: $hexValue");
    } catch (e) {
      print("Failed to enqueue mode command: $e");
    }
  }

  void _changeFanSpeed(String newFanSpeed) async {
    setState(() {
      fanSpeed = newFanSpeed;
    });

    String hexValue = fanSpeed == "Auto" ? "F728D7" : "F76897";

  try {
    await enqueueCommand("changeFanSpeed", hexValue); // Add command to queue
    print("Fan speed command enqueued: $hexValue");
  } catch (e) {
    print("Failed to enqueue fan speed command: $e");
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
                      isACOn: isPowerOn, // Add the required isACOn argument
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
                  MaterialPageRoute(
                    builder: (context) => ScheduleScreen(
                      //togglePower: _togglePower,
                      //isACOn: isPowerOn,
                    ),
                  ),
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
                      humidityLog: [], // Add the required humidityLog argument
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
                              temperature: temperature,
                              onTemperatureChange: (value) async {
                                setState(() {
                                  temperature = value;
                                });

                                // Generate IR code for temperature (example logic)
                                String hexValue = "F7A" + (temperature.toInt()).toRadixString(16).toUpperCase(); 

                                try {
                                  await enqueueCommand("setTemperature", hexValue); // Add command to queue
                                  print("Temperature command enqueued: $hexValue");
                                } catch (e) {
                                  print("Failed to enqueue temperature command: $e");
                                }
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
                                      value: mode,
                                      icon: Icons.ac_unit,
                                      onTap: () => _changeMode(mode == "Cool" ? "Heat" : "Cool"),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10), // Add some spacing between the cards
                                Expanded(
                                  child: Container(
                                    height: 100, // Adjust the height as needed
                                    child: FeatureCard(
                                      title: "Fan Speed",
                                      value: fanSpeed,
                                      icon: Icons.air,
                                      onTap: () => _changeFanSpeed(fanSpeed == "Auto" ? "High" : "Auto"),
                                    ),
                                  ),
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

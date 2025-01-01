import 'dart:convert';
import 'package:http/http.dart' as http;

class ESP32Service {
  final String baseUrl;

  ESP32Service({this.baseUrl = "http://192.168.4.1"}); // Default IP address for ESP32

  Future<Map<String, double>?> fetchSensorData() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/sensor-data"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          "temperature": data['temperature']?.toDouble() ?? 0.0,
          "humidity": data['humidity']?.toDouble() ?? 0.0,
        };
      } else {
        print("Failed to fetch data from ESP32: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error fetching data from ESP32: $e");
      return null;
    }
  }
}

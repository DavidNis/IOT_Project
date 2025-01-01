import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  Future<double?> getCurrentTemperature() async {
    try {
      // Check if location permissions are granted
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          throw Exception("Location permissions are permanently denied.");
        } else if (permission == LocationPermission.denied) {
          throw Exception("Location permissions are denied.");
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      double latitude = position.latitude;
      double longitude = position.longitude;

      // OpenWeatherMap API
      String apiKey = 'd68f002808f39d8172f1d156be43f584'; // Your API key
      String url =
          'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&units=metric&appid=$apiKey';

      // HTTP request
      final response = await http.get(Uri.parse(url));
      print("API Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['main']['temp']; // Return the temperature
      } else {
        print("Failed to load weather data: ${response.statusCode}");
        return null; // Return null in case of failure
      }
    } catch (e) {
      print("Error fetching temperature: $e");
      return null; // Return null in case of an exception
    }
  }
}

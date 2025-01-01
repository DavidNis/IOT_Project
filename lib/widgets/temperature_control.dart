import 'package:flutter/material.dart';

class TemperatureControl extends StatelessWidget {
  final double temperature;
  final ValueChanged<double> onTemperatureChange;

  TemperatureControl({required this.temperature, required this.onTemperatureChange});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: CircularProgressIndicator(
            value: (temperature - 16) / 14, // Map 16°C to 30°C
            strokeWidth: 10,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(Colors.blueAccent),
          ),
        ),
        Column(
          children: [
            Text(
              "${temperature.toInt()}°C",
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () {
                    onTemperatureChange(temperature > 16 ? temperature - 1 : 16);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    onTemperatureChange(temperature < 30 ? temperature + 1 : 30);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

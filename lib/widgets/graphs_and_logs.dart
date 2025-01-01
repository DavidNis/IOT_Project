import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

class GraphsAndLogsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> temperatureLog;

  GraphsAndLogsScreen({required this.temperatureLog});

  @override
  _GraphsAndLogsScreenState createState() => _GraphsAndLogsScreenState();
}

class _GraphsAndLogsScreenState extends State<GraphsAndLogsScreen> {
  String selectedRange = 'Hour';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Graphs & Logs"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRangeButton("Hour"),
              _buildRangeButton("Day"),
              _buildRangeButton("Week"),
              _buildRangeButton("Year"),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text("${value.toStringAsFixed(1)}°C", style: TextStyle(fontSize: 12));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 == 0) {
                            switch (selectedRange) {
                              case "Hour":
                                return Text("${value.toInt()}", style: TextStyle(fontSize: 12));
                              case "Day":
                                return Text("${value.toInt()}", style: TextStyle(fontSize: 12));
                              case "Week":
                                return Text("${value.toInt()}", style: TextStyle(fontSize: 12));
                              case "Year":
                                return Text("${value.toInt()}", style: TextStyle(fontSize: 12));
                              default:
                                return Container();
                            }
                          } else {
                            return Container();
                          }
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey, width: 1),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateSpots(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                  ],
                  minX: 0,
                  maxX: _getMaxX(),
                  minY: _getMinY(),
                  maxY: _getMaxY(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeButton(String range) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRange = range;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selectedRange == range ? Colors.redAccent : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          range,
          style: TextStyle(
            color: selectedRange == range ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  List<FlSpot> _generateSpots() {
    List<FlSpot> spots = [];
    final now = DateTime.now();

    // Filter temperatureLog based on the selected range
    List<Map<String, dynamic>> filteredLog = widget.temperatureLog.where((entry) {
      DateTime time = entry['time'];
      switch (selectedRange) {
        case "Hour":
          return now.difference(time).inMinutes < 60;
        case "Day":
          return now.difference(time).inHours < 24;
        case "Week":
          return now.difference(time).inDays < 7;
        case "Year":
          return now.difference(time).inDays < 365;
        default:
          return false;
      }
    }).toList();

    // Map filteredLog to FlSpot list
    for (var i = 0; i < filteredLog.length; i++) {
      spots.add(FlSpot(
        i.toDouble(),
        filteredLog[i]['temperature']?.toDouble() ?? 0.0,
      ));
    }

    return spots;
  }

  double _getMaxX() {
    switch (selectedRange) {
      case "Hour":
        return 60;
      case "Day":
        return 24;
      case "Week":
        return 7;
      case "Year":
        return 12;
      default:
        return 12;
    }
  }

  double _getMinY() {
    return 16; // Minimum temperature for all ranges
  }

  double _getMaxY() {
    return 30; // Maximum temperature for all ranges
  }
}

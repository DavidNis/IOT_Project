import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TemperatureReading {
  final DateTime timestamp;
  final double value;
  TemperatureReading({required this.timestamp, required this.value});
}

class GraphsAndLogsScreen extends StatelessWidget {
  final List<TemperatureReading> temperatureLog;
  final bool isACOn; // Pass this flag to indicate if the AC is on or off.
  final VoidCallback onClearLogs;
  

  const GraphsAndLogsScreen({
    Key? key,
    required this.temperatureLog,
    required this.isACOn,
    required this.onClearLogs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Graph & Logs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Graphs & Logs'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onClearLogs, // Call the clear logs function
              tooltip: 'Clear Logs',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.show_chart), text: 'Graph'),
              Tab(icon: Icon(Icons.list), text: 'Logs'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGraphTab(),
            _buildLogsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphTab() {
    if (temperatureLog.isEmpty) {
      return const Center(child: Text('No temperature data yet...'));
    }

    // Compute the recommended temperature (e.g., the average)
    double sum = 0;
    for (final reading in temperatureLog) {
      sum += reading.value;
    }
    final recommended = sum / temperatureLog.length;

    // Convert each reading to FlSpot
    final spots = temperatureLog.asMap().entries.map((entry) {
      final index = entry.key;
      final reading = entry.value;
      final xVal = index * 5.0;
      return FlSpot(xVal, reading.value);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Show AC status
          Text(
            isACOn ? 'AC is ON' : 'AC is OFF - Logging Paused',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isACOn ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 12),

          // Display the recommended temperature
          Text(
            'Recommended Temperature: ${recommended.toStringAsFixed(1)}°C',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: LineChart(
              LineChartData(
                minY: 16,
                maxY: 30,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    color: Colors.blue,
                  ),
                ],
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value % 5 == 0) {
                          return Text('${value.toInt()}s',
                              style: const TextStyle(fontSize: 12));
                        }
                        return Container();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    left: BorderSide(color: Colors.black, width: 1),
                    bottom: BorderSide(color: Colors.black, width: 1),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsTab() {
    // Check if the log is empty
    if (temperatureLog.isEmpty) {
      return const Center(
        child: Text(
          'No temperature logs available.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      itemCount: temperatureLog.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        // Safeguard against potential out-of-range errors
        if (index < 0 || index >= temperatureLog.length) {
          return const SizedBox(); // Return an empty widget if index is invalid
        }

        final reading = temperatureLog[index];
        final time = reading.timestamp;
        final dateStr = '${time.day}/${time.month}/${time.year}';
        final timeStr =
            '${time.hour.toString().padLeft(2, '0')}:' +
            '${time.minute.toString().padLeft(2, '0')}:' +
            '${time.second.toString().padLeft(2, '0')}';

        return ListTile(
          leading: const Icon(Icons.device_thermostat),
          title: Text('${reading.value.toStringAsFixed(1)} °C'),
          subtitle: Text('$dateStr $timeStr'),
        );
      },
    );
  }
}

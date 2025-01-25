import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TemperatureReading {
  final DateTime timestamp;
  final double value;
  TemperatureReading({required this.timestamp, required this.value});
}

class GraphsAndLogsScreen extends StatelessWidget {
  final List<TemperatureReading> temperatureLog;

  const GraphsAndLogsScreen({
    Key? key,
    required this.temperatureLog,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Graph & Logs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Graphs & Logs'),
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

    // 1) Compute a recommended temperature (e.g. the average)
    double sum = 0;
    for (final reading in temperatureLog) {
      sum += reading.value;
    }
    final recommended = sum / temperatureLog.length;

    // 2) Convert each reading to FlSpot. If each reading is 5s apart => x = index*5
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
          // Display the recommended temperature just above the chart
          Text(
            'Recommended: ${recommended.toStringAsFixed(1)}°C',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: LineChart(
              LineChartData(
                // Force Y range 16..30 (adjust if you want a different range)
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
                        // Render text horizontally (angle=0)
                        return Transform.rotate(
                          angle: 0.0,
                          child: Text(
                            '${value.toInt()}',
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        // Show label only if multiple of 5
                        if (value % 5 == 0) {
                          return Text('${value.toInt()}s',
                              style: const TextStyle(fontSize: 12));
                        }
                        return Container();
                      },
                    ),
                  ),
                ),

                // Only bottom & left borders as axes
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    left: BorderSide(color: Colors.black, width: 1),
                    bottom: BorderSide(color: Colors.black, width: 1),
                    right: BorderSide(color: Colors.transparent, width: 0),
                    top: BorderSide(color: Colors.transparent, width: 0),
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
    return ListView.separated(
      itemCount: temperatureLog.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final reading = temperatureLog[index];
        final time = reading.timestamp;
        final dateStr = '${time.day}/${time.month}/${time.year}';
        final timeStr =
            '${time.hour.toString().padLeft(2, '0')}:'
            '${time.minute.toString().padLeft(2, '0')}:'
            '${time.second.toString().padLeft(2, '0')}';
        return ListTile(
          leading: const Icon(Icons.device_thermostat),
          title: Text('${reading.value} °C'),
          subtitle: Text('$dateStr $timeStr'),
        );
      },
    );
  }
}

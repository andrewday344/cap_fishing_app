import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class WindForecastScreen extends StatefulWidget {
  final Map<String, dynamic> forecastData;
  const WindForecastScreen({super.key, required this.forecastData});

  @override
  State<WindForecastScreen> createState() => _WindForecastScreenState();
}

class _WindForecastScreenState extends State<WindForecastScreen> {
  int _daysToShow = 1; // Default to 1-Day view like the screenshot

  @override
  Widget build(BuildContext context) {
    List<dynamic> allEntries = [];
    try {
      // Combine entries based on selected days
      for (int i = 0; i < _daysToShow; i++) {
        allEntries.addAll(widget.forecastData['wind']['days'][i]['entries']);
      }
    } catch (e) {
      return const Scaffold(body: Center(child: Text("Data limited to 2 days currently")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Lighter background like the web view
      appBar: AppBar(
        title: const Text("Seacliff Wind Forecast", style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // DAY TOGGLE BUTTONS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [1, 3, 5].map((day) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text("$day-Day"),
                selected: _daysToShow == day,
                onSelected: (selected) {
                  setState(() => _daysToShow = day);
                },
              ),
            )).toList(),
          ),

          // THE PRO GRAPH
          Container(
            height: 250,
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            child: CustomPaint(
              painter: WillyStylePainter(allEntries),
            ),
          ),

          // DATA LIST
          Expanded(
            child: ListView.builder(
              itemCount: allEntries.length,
              itemBuilder: (context, index) {
                final entry = allEntries[index];
                final date = DateTime.parse(entry['dateTime']);
                final timeLabel = _daysToShow == 1 
                    ? DateFormat('h:mm a').format(date) 
                    : DateFormat('E d h aa').format(date);
                
                final knots = (entry['speed'] / 1.852).round();
                return ListTile(
                  dense: true,
                  title: Text(timeLabel),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("$knots kts ", style: const TextStyle(fontWeight: FontWeight.bold)),
                      _getWindIcon(entry['directionText']),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _getWindIcon(String dir) {
    Map<String, double> directions = {'N': 0, 'NE': 45, 'E': 90, 'SE': 135, 'S': 180, 'SW': 225, 'W': 270, 'NW': 315};
    double angle = (directions[dir.toUpperCase().substring(0, math.min(dir.length, 2))] ?? 0) * (math.pi / 180);
    return Transform.rotate(
      angle: angle,
      child: const Icon(Icons.navigation, size: 16, color: Colors.green),
    );
  }
}

class WillyStylePainter extends CustomPainter {
  final List<dynamic> entries;
  WillyStylePainter(this.entries);

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    
    double stepX = size.width / (entries.length - 1);
    double maxWind = 40.0;

    for (int i = 0; i < entries.length; i++) {
      double wind = (entries[i]['speed'] / 1.852);
      double x = i * stepX;
      double y = size.height - (wind / maxWind * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
      
      if (i == entries.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }
    
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
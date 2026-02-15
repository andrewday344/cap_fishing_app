import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class WindForecastScreen extends StatelessWidget {
  final Map<String, dynamic> forecastData;

  const WindForecastScreen({super.key, required this.forecastData});

  // Helper to convert compass text to degrees for the icon
  double _getRotation(String dir) {
    Map<String, double> directions = {
      'N': 0, 'NNE': 22.5, 'NE': 45, 'ENE': 67.5,
      'E': 90, 'ESE': 112.5, 'SE': 135, 'SSE': 157.5,
      'S': 180, 'SSW': 202.5, 'SW': 225, 'WSW': 247.5,
      'W': 270, 'WNW': 292.5, 'NW': 315, 'NNW': 337.5,
    };
    // math.pi / 180 converts degrees to radians for Flutter
    return (directions[dir] ?? 0) * (math.pi / 180);
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> windEntries = [];
    try {
      // Pulling the first day of wind entries from the WillyWeather JSON
      windEntries = forecastData['wind']['days'][0]['entries'];
    } catch (e) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: Text("Forecast data unavailable", style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Wind Forecast - Seacliff", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // The Cyan Back Arrow
        iconTheme: const IconThemeData(color: Colors.cyanAccent), 
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text("24-Hour Trend (Knots)", 
            style: TextStyle(color: Colors.white70, fontSize: 16)),
          
          // GRAPH AREA
          Container(
            height: 200,
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: CustomPaint(
              painter: WindGraphPainter(windEntries),
            ),
          ),

          // LIST AREA
          Expanded(
            child: ListView.builder(
              itemCount: windEntries.length,
              itemBuilder: (context, index) {
                final entry = windEntries[index];
                final time = DateFormat('h:mm a').format(DateTime.parse(entry['dateTime']));
                final knots = (entry['speed'] / 1.852).round();
                final dir = entry['directionText'] ?? 'N';

                return ListTile(
                  leading: Text(time, style: const TextStyle(color: Colors.white70)),
                  title: Text("$knots kts $dir", 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  trailing: Transform.rotate(
                    angle: _getRotation(dir),
                    child: const Icon(Icons.navigation, color: Colors.cyanAccent, size: 24),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- THIS IS THE MISSING PIECE ---
class WindGraphPainter extends CustomPainter {
  final List<dynamic> entries;
  WindGraphPainter(this.entries);

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final paint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    double stepX = size.width / (entries.length - 1);
    
    // We scale the graph based on a 30 knot max for visual consistency
    double maxWindHeight = 30.0; 

    for (int i = 0; i < entries.length; i++) {
      double wind = (entries[i]['speed'] / 1.852);
      double x = i * stepX;
      // In Flutter (0,0) is top-left, so we subtract from height to flip the graph
      double y = size.height - (wind / maxWindHeight * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
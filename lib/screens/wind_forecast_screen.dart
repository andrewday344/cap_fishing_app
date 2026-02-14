import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WindForecastScreen extends StatelessWidget {
  final Map<String, dynamic> forecastData;

  const WindForecastScreen({super.key, required this.forecastData});

  @override
  Widget build(BuildContext context) {
    // Extract wind entries for the next 24 hours
    List<dynamic> windEntries = [];
    try {
      windEntries = forecastData['wind']['days'][0]['entries'];
    } catch (e) {
      return Scaffold(body: Center(child: Text("Forecast data unavailable")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Navy
      appBar: AppBar(
        title: const Text("Wind Forecast - Seacliff"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text("24-Hour Trend (Knots)", 
            style: TextStyle(color: Colors.white70, fontSize: 16)),
          
          // The Graph Area
          Container(
            height: 200,
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: CustomPaint(
              painter: WindGraphPainter(windEntries),
            ),
          ),

          // The List View for exact times
          Expanded(
            child: ListView.builder(
              itemCount: windEntries.length,
              itemBuilder: (context, index) {
                final entry = windEntries[index];
                final time = DateFormat('h:mm a').format(DateTime.parse(entry['dateTime']));
                final knots = (entry['speed'] / 1.852).round();
                final dir = entry['directionText'];

                return ListTile(
                  leading: Text(time, style: const TextStyle(color: Colors.white)),
                  title: Text("$knots kts $dir", 
                    style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                  trailing: Icon(Icons.navigation, 
                    color: Colors.white24, 
                    size: 18), // We'll rotate this eventually!
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class WindGraphPainter extends CustomPainter {
  final List<dynamic> entries;
  WindGraphPainter(this.entries);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    double stepX = size.width / (entries.length - 1);
    
    // Find max wind for scaling
    double maxWind = 30.0; // Default floor

    for (int i = 0; i < entries.length; i++) {
      double wind = (entries[i]['speed'] / 1.852);
      double x = i * stepX;
      double y = size.height - (wind / maxWind * size.height);

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
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
  int _daysToShow = 1;
  int? _hoverIndex;

  @override
  Widget build(BuildContext context) {
    List<dynamic> allEntries = [];
    try {
      for (int i = 0; i < _daysToShow; i++) {
        allEntries.addAll(widget.forecastData['wind']['days'][i]['entries']);
      }
    } catch (e) {
      return const Scaffold(backgroundColor: Color(0xFFF1F5F9), body: Center(child: Text("Data missing")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Seacliff Wind Forecast", style: TextStyle(color: Colors.black87, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      body: Column(
        children: [
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [1, 3, 5].map((day) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ChoiceChip(
                label: Text("$day-Day"),
                selected: _daysToShow == day,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _daysToShow = day;
                      _hoverIndex = null;
                    });
                  }
                },
              ),
            )).toList(),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Stack(
              children: [
                GestureDetector(
                  onPanUpdate: (details) => _handleTouch(details.localPosition, allEntries, context),
                  onTapDown: (details) => _handleTouch(details.localPosition, allEntries, context),
                  child: Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: CustomPaint(
                      painter: InteractiveWillyPainter(allEntries, _hoverIndex),
                    ),
                  ),
                ),
                if (_hoverIndex != null && _hoverIndex! < allEntries.length)
                  _buildTooltip(allEntries[_hoverIndex!]),
              ],
            ),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text("Slide finger across graph to see details", 
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _handleTouch(Offset localPosition, List<dynamic> entries, BuildContext context) {
    double chartWidth = MediaQuery.of(context).size.width - 20;
    double stepX = chartWidth / (entries.length - 1);
    
    int index = (localPosition.dx / stepX).round();
    if (index >= 0 && index < entries.length) {
      setState(() => _hoverIndex = index);
    }
  }

  Widget _buildTooltip(dynamic entry) {
    final date = DateTime.parse(entry['dateTime']);
    final knots = (entry['speed'] / 1.852).round();
    final dir = entry['directionText'];
    String severity = knots < 10 ? "Light" : (knots < 18 ? "Moderate" : "Fresh");

    return Positioned(
      top: 20,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          "${DateFormat('h:mm a').format(date)} $dir $knots knots $severity",
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class InteractiveWillyPainter extends CustomPainter {
  final List<dynamic> entries;
  final int? hoverIndex;
  InteractiveWillyPainter(this.entries, this.hoverIndex);

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final double stepX = size.width / (entries.length - 1);
    const double maxWind = 40.0;

    final linePath = Path();
    final fillPath = Path();
    
    for (int i = 0; i < entries.length; i++) {
      double wind = (entries[i]['speed'] / 1.852);
      double x = i * stepX;
      double y = size.height - (wind / maxWind * size.height);

      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (i == entries.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    canvas.drawPath(fillPath, Paint()..color = Colors.blue.withValues(alpha: 0.05));
    canvas.drawPath(linePath, Paint()..color = Colors.blue.shade300..strokeWidth = 2..style = PaintingStyle.stroke);

    for (int i = 0; i < entries.length; i++) {
      if (entries.length > 50 && i % 2 != 0) continue; 
      double wind = (entries[i]['speed'] / 1.852);
      double x = i * stepX;
      double y = size.height - (wind / maxWind * size.height);
      _drawArrow(canvas, x, y, entries[i]['directionText'], wind);
    }

    if (hoverIndex != null) {
      double hoverX = hoverIndex! * stepX;
      canvas.drawLine(Offset(hoverX, 0), Offset(hoverX, size.height), 
        Paint()..color = Colors.blue..strokeWidth = 1);
    }
  }

  void _drawArrow(Canvas canvas, double x, double y, String dir, double speed) {
    Color arrowColor = speed < 10 ? Colors.green : (speed < 18 ? Colors.lightBlue : Colors.orange);
    Map<String, double> directions = {'N': 0, 'NE': 45, 'E': 90, 'SE': 135, 'S': 180, 'SW': 225, 'W': 270, 'NW': 315};
    double angle = (directions[dir.toUpperCase().substring(0, math.min(dir.length, 2))] ?? 0) * (math.pi / 180);

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);
    
    final path = Path()..moveTo(0, -7)..lineTo(4, 3)..lineTo(0, 1)..lineTo(-4, 3)..close();
    canvas.drawPath(path, Paint()..color = arrowColor);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
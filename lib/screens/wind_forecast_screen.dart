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
    String topDateLabel = "";
    
    try {
      allEntries.addAll(widget.forecastData['wind']['days'][0]['entries']);
      // Formats the header date: Mon 16 Feb
      topDateLabel = DateFormat('E d MMM').format(DateTime.parse(allEntries[0]['dateTime']));
      
      if (_daysToShow > 1) {
        for (int i = 1; i < _daysToShow; i++) {
          allEntries.addAll(widget.forecastData['wind']['days'][i]['entries']);
        }
      }
    } catch (e) {
      return const Scaffold(body: Center(child: Text("Data missing")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Very light grey background
      appBar: AppBar(
        title: const Text("Seacliff Wind", style: TextStyle(color: Colors.black87, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      body: Column(
        children: [
          // 1. DATE HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.white,
            child: Text(
              topDateLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
          ),
          
          const SizedBox(height: 10),
          
          // DAY TOGGLES
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

          const SizedBox(height: 15),

          // 2. THE INTERACTIVE GRAPH WITH DAY/NIGHT SHADING
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
          const Text("Slide to view wind trend", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ... _handleTouch and _buildTooltip remain the same as previous response ...
  void _handleTouch(Offset localPosition, List<dynamic> entries, BuildContext context) {
    double chartWidth = MediaQuery.of(context).size.width - 20;
    double stepX = chartWidth / (entries.length - 1);
    int index = (localPosition.dx / stepX).round();
    if (index >= 0 && index < entries.length) setState(() => _hoverIndex = index);
  }

  Widget _buildTooltip(dynamic entry) {
    final date = DateTime.parse(entry['dateTime']);
    final knots = (entry['speed'] / 1.852).round();
    return Positioned(
      top: 10, left: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
        child: Text("${DateFormat('h:mm a').format(date)} | $knots kts ${entry['directionText']}",
          style: const TextStyle(color: Colors.white, fontSize: 12)),
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

    // 1. DRAW DAY/NIGHT BACKGROUND COLUMNS
    for (int i = 0; i < entries.length - 1; i++) {
      final hour = DateTime.parse(entries[i]['dateTime']).hour;
      // Night is typically 6 PM (18) to 6 AM (6)
      bool isNight = hour < 6 || hour >= 18;
      
      final rect = Rect.fromLTWH(i * stepX, 0, stepX, size.height);
      final paint = Paint()..color = isNight 
          ? const Color(0xFFE2E8F0) // Light blue-grey for night
          : Colors.white;            // White for day
      canvas.drawRect(rect, paint);
    }

    // 2. DRAW GRAPH LINES & ARROWS
    final linePath = Path();
    for (int i = 0; i < entries.length; i++) {
      double wind = (entries[i]['speed'] / 1.852);
      double x = i * stepX;
      double y = size.height - (wind / maxWind * size.height);
      if (i == 0) {
        linePath.moveTo(x, y);
      } else { linePath.lineTo(x, y);
      }
      // Draw colored arrow
      _drawArrow(canvas, x, y, entries[i]['directionText'], wind);
    }
    canvas.drawPath(linePath, Paint()..color = Colors.blue.shade300..strokeWidth = 2..style = PaintingStyle.stroke);

    // 3. HOVER LINE
    if (hoverIndex != null) {
      double hoverX = hoverIndex! * stepX;
      canvas.drawLine(Offset(hoverX, 0), Offset(hoverX, size.height), Paint()..color = Colors.blue);
    }
  }

  void _drawArrow(Canvas canvas, double x, double y, String dir, double speed) {
    Color arrowColor = speed < 10 ? Colors.green : (speed < 18 ? Colors.lightBlue : Colors.orange);
    Map<String, double> directions = {'N': 0, 'NE': 45, 'E': 90, 'SE': 135, 'S': 180, 'SW': 225, 'W': 270, 'NW': 315};
    double angle = (directions[dir.toUpperCase().substring(0, math.min(dir.length, 2))] ?? 0) * (math.pi / 180);
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);
    canvas.drawPath(Path()..moveTo(0, -6)..lineTo(3, 3)..lineTo(0, 1)..lineTo(-3, 3)..close(), Paint()..color = arrowColor);
    canvas.restore();
  }

  @override bool shouldRepaint(CustomPainter oldDelegate) => true;
}
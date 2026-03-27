import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

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
    // --- 1. THE SAFETY GUARD ---
    // This stops the RangeError: Index out of range: 0
    if (widget.forecastData['wind'] == null || 
        widget.forecastData['wind']['days'] == null || 
        (widget.forecastData['wind']['days'] as List).isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Wind Forecast")),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, size: 50, color: Colors.grey),
              SizedBox(height: 10),
              Text("No forecast data available.", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Please check your internet or refresh.", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    List<dynamic> allEntries = [];
    List<Map<String, dynamic>> dayBoundaries = [];

    // --- 2. DATA PROCESSING (Wrapped in Safety) ---
    try {
      // Ensure we don't try to show more days than the API actually returned
      int availableDays = (widget.forecastData['wind']['days'] as List).length;
      int daysToProcess = math.min(_daysToShow, availableDays);

      for (int i = 0; i < daysToProcess; i++) {
        var dayData = widget.forecastData['wind']['days'][i];
        
        // Record where each day starts for the painter
        if (dayData['entries'] != null && (dayData['entries'] as List).isNotEmpty) {
          dayBoundaries.add({
            'startIndex': allEntries.length,
            'label': DateFormat('E d MMM').format(DateTime.parse(dayData['entries'][0]['dateTime'])),
          });
          allEntries.addAll(dayData['entries']);
        }
      }
    } catch (e) {
      // Fallback if data structure is unexpected
      return const Scaffold(body: Center(child: Text("Error parsing wind data")));
    }

    // --- 3. THE UI (Your Original Logic) ---
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
          // Day Toggles
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

          // THE GRAPH
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Stack(
              children: [
                GestureDetector(
                  onPanUpdate: (details) => _handleTouch(details.localPosition, allEntries, context),
                  onTapDown: (details) => _handleTouch(details.localPosition, allEntries, context),
                  child: Container(
                    height: 350, 
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black12),
                    ),
                    child: CustomPaint(
                      painter: WillyStyleInteractivePainter(allEntries, _hoverIndex, dayBoundaries),
                    ),
                  ),
                ),
                if (_hoverIndex != null && _hoverIndex! < allEntries.length)
                  _buildTooltip(allEntries[_hoverIndex!]),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  void _handleTouch(Offset localPosition, List<dynamic> entries, BuildContext context) {
    if (entries.isEmpty) return; // Guard for empty touch
    double chartWidth = MediaQuery.of(context).size.width - 20;
    double stepX = chartWidth / (entries.length > 1 ? entries.length - 1 : 1);
    int index = (localPosition.dx / stepX).round();
    if (index >= 0 && index < entries.length) setState(() => _hoverIndex = index);
  }

  Widget _buildTooltip(dynamic entry) {
    final date = DateTime.parse(entry['dateTime']);
    final knots = (entry['speed'] / 1.852).round();
    return Positioned(
      bottom: 20, 
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(20)),
        child: Text("${DateFormat('h:mm a').format(date)}: $knots kts ${entry['directionText']}",
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// --- WillyStyleInteractivePainter and _drawArrow remain unchanged ---

class WillyStyleInteractivePainter extends CustomPainter {
  final List<dynamic> entries;
  final int? hoverIndex;
  final List<Map<String, dynamic>> dayBoundaries;

  WillyStyleInteractivePainter(this.entries, this.hoverIndex, this.dayBoundaries);

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final double stepX = size.width / (entries.length - 1);
    const double maxWind = 40.0;
    const double graphTopPadding = 40.0; // Space for dates

    // 1. DRAW DAY/NIGHT BACKGROUNDS
    for (int i = 0; i < entries.length - 1; i++) {
      final hour = DateTime.parse(entries[i]['dateTime']).hour;
      bool isNight = hour < 6 || hour >= 18;
      
      final rect = Rect.fromLTWH(i * stepX, graphTopPadding, stepX, size.height - graphTopPadding);
      canvas.drawRect(rect, Paint()..color = isNight ? const Color(0xFFF1F5F9) : Colors.white);
    }

    // 2. DRAW DATE LABELS AT THE TOP
    for (var boundary in dayBoundaries) {
      double x = boundary['startIndex'] * stepX;
      
      // Draw a subtle vertical line to separate days
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), Paint()..color = Colors.black12);

      TextPainter(
        text: TextSpan(
          text: boundary['label'],
          style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout()..paint(canvas, Offset(x + 5, 10));
    }

    // 3. DRAW WIND LINE & ARROWS
    final path = Path();
    for (int i = 0; i < entries.length; i++) {
      double wind = (entries[i]['speed'] / 1.852);
      double x = i * stepX;
      // Scale y to stay within the graph area (below the date labels)
      double y = size.height - (wind / maxWind * (size.height - graphTopPadding));

      if (i == 0) { 
        path.moveTo(x, y);
      } else { path.lineTo(x, y);
     }

      if (entries.length < 50 || i % 2 == 0) {
        _drawArrow(canvas, x, y, entries[i]['directionText'], wind);
      }
    }
    canvas.drawPath(path, Paint()..color = Colors.blue.shade300..strokeWidth = 2..style = PaintingStyle.stroke);

    // 4. HOVER LINE
    if (hoverIndex != null) {
      double hoverX = hoverIndex! * stepX;
      canvas.drawLine(Offset(hoverX, graphTopPadding), Offset(hoverX, size.height), 
          Paint()..color = Colors.blue.withValues(alpha: 0.5)..strokeWidth = 1);
    }
  }
void _drawArrow(Canvas canvas, double x, double y, String dir, double speed) {
    Color arrowColor = speed < 10 ? Colors.green : (speed < 18 ? Colors.lightBlue : Colors.orange);
    Map<String, double> directions = {'N': 0, 'NE': 45, 'E': 90, 'SE': 135, 'S': 180, 'SW': 225, 'W': 270, 'NW': 315};
    double angle = (directions[dir.toUpperCase().substring(0, math.min(dir.length, 2))] ?? 0) * (math.pi / 180);

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);
    
    // Coordinates multiplied by 1.5 for a 50% size increase:
    // Original (0, -6) -> (0, -9)
    // Original (3, 3)  -> (4.5, 4.5)
    // Original (0, 1)  -> (0, 1.5)
    // Original (-3, 3) -> (-4.5, 4.5)
    canvas.drawPath(
      Path()
        ..moveTo(0, -9)
        ..lineTo(4.5, 4.5)
        ..lineTo(0, 1.5)
        ..lineTo(-4.5, 4.5)
        ..close(), 
      Paint()..color = arrowColor
    );
    
    canvas.restore();
  }
}
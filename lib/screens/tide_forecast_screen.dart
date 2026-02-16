import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class TideForecastScreen extends StatefulWidget {
  final Map<String, dynamic> forecastData;
  const TideForecastScreen({super.key, required this.forecastData});

  @override
  State<TideForecastScreen> createState() => _TideForecastScreenState();
}

class _TideForecastScreenState extends State<TideForecastScreen> {
  int _daysToShow = 1;
  int? _hoverIndex;

  @override
  Widget build(BuildContext context) {
    List<dynamic> allEntries = [];
    List<Map<String, dynamic>> dayBoundaries = [];

    try {
      // Pulling tide heights from the WillyWeather JSON
      for (int i = 0; i < _daysToShow; i++) {
        var dayData = widget.forecastData['tides']['days'][i];
        dayBoundaries.add({
          'startIndex': allEntries.length,
          'label': DateFormat('E d MMM').format(DateTime.parse(dayData['dateTime'])),
        });
        allEntries.addAll(dayData['entries']);
      }
    } catch (e) {
      return const Scaffold(body: Center(child: Text("Tide data unavailable")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Seacliff Tide Times", style: TextStyle(color: Colors.black87, fontSize: 18)),
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

          // THE TIDE GRAPH
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
                      painter: TideGraphPainter(allEntries, _hoverIndex, dayBoundaries),
                    ),
                  ),
                ),
                // Tooltip
                if (_hoverIndex != null && _hoverIndex! < allEntries.length)
                  _buildTideTooltip(allEntries[_hoverIndex!]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleTouch(Offset localPosition, List<dynamic> entries, BuildContext context) {
    double chartWidth = MediaQuery.of(context).size.width - 20;
    double stepX = chartWidth / (entries.length - 1);
    int index = (localPosition.dx / stepX).round();
    if (index >= 0 && index < entries.length) setState(() => _hoverIndex = index);
  }

  Widget _buildTideTooltip(dynamic entry) {
    final date = DateTime.parse(entry['dateTime']);
    final height = entry['height'].toStringAsFixed(2);
    return Positioned(
      top: 60,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(20)),
        child: Text("${DateFormat('h:mm a').format(date)}: $height m",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class TideGraphPainter extends CustomPainter {
  final List<dynamic> entries;
  final int? hoverIndex;
  final List<Map<String, dynamic>> dayBoundaries;

  TideGraphPainter(this.entries, this.hoverIndex, this.dayBoundaries);

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final double stepX = size.width / (entries.length - 1);
    const double maxTideHeight = 4.0; // Adjusted for SA tides
    const double graphTopPadding = 50.0;

    // 1. DAY/NIGHT BACKGROUNDS
    for (int i = 0; i < entries.length - 1; i++) {
      final hour = DateTime.parse(entries[i]['dateTime']).hour;
      bool isNight = hour < 6 || hour >= 18;
      final rect = Rect.fromLTWH(i * stepX, graphTopPadding, stepX, size.height - graphTopPadding);
      canvas.drawRect(rect, Paint()..color = isNight ? const Color(0xFFDDE4ED) : Colors.white);
    }

    // 2. DATE LABELS & SEPARATORS
    for (var boundary in dayBoundaries) {
      double x = boundary['startIndex'] * stepX;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), Paint()..color = Colors.black12);
      TextPainter(
        text: TextSpan(text: boundary['label'], style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
        textDirection: ui.TextDirection.ltr,
      )..layout()..paint(canvas, Offset(x + 8, 15));
    }

    // 3. THE TIDE WAVE (Smooth Curve)
    final path = Path();
    final fillPath = Path();
    
    path.moveTo(0, _getY(entries[0]['height'], size, maxTideHeight, graphTopPadding));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, _getY(entries[0]['height'], size, maxTideHeight, graphTopPadding));

    for (int i = 0; i < entries.length - 1; i++) {
      double x1 = i * stepX;
      double y1 = _getY(entries[i]['height'], size, maxTideHeight, graphTopPadding);
      double x2 = (i + 1) * stepX;
      double y2 = _getY(entries[i + 1]['height'], size, maxTideHeight, graphTopPadding);

      // Cubic Bezier for smooth tide curves
      path.cubicTo((x1 + x2) / 2, y1, (x1 + x2) / 2, y2, x2, y2);
      fillPath.cubicTo((x1 + x2) / 2, y1, (x1 + x2) / 2, y2, x2, y2);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw the blue "Water" fill
    canvas.drawPath(fillPath, Paint()..color = Colors.blue.withValues(alpha: 0.3));
    // Draw the tide line
    canvas.drawPath(path, Paint()..color = Colors.blue.shade700..strokeWidth = 3..style = PaintingStyle.stroke);

    // 4. INTERACTIVE HOVER LINE
    if (hoverIndex != null) {
      double hoverX = hoverIndex! * stepX;
      canvas.drawLine(Offset(hoverX, graphTopPadding), Offset(hoverX, size.height), Paint()..color = Colors.blue);
      canvas.drawCircle(Offset(hoverX, _getY(entries[hoverIndex!]['height'], size, maxTideHeight, graphTopPadding)), 6, Paint()..color = Colors.blue);
    }
  }

  double _getY(dynamic height, Size size, double maxHeight, double padding) {
    return size.height - (height / maxHeight * (size.height - padding));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
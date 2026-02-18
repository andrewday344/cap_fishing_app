import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class SwellForecastScreen extends StatefulWidget {
  final Map<String, dynamic> forecastData;
  const SwellForecastScreen({super.key, required this.forecastData});

  @override
  State<SwellForecastScreen> createState() => _SwellForecastScreenState();
}

class _SwellForecastScreenState extends State<SwellForecastScreen> {
  int _daysToShow = 1;
  int? _hoverIndex;

  @override
  Widget build(BuildContext context) {
    List<dynamic> allEntries = [];
    List<Map<String, dynamic>> dayBoundaries = [];

    try {
      // Safety check: ensure 'swell' and 'days' exist
      if (widget.forecastData['swell'] != null && widget.forecastData['swell']['days'] != null) {
        var daysList = widget.forecastData['swell']['days'];
        // Ensure we don't try to show more days than we actually have data for
        int actualDays = _daysToShow > daysList.length ? daysList.length : _daysToShow;

        for (int i = 0; i < actualDays; i++) {
          var dayData = daysList[i];
          dayBoundaries.add({
            'startIndex': allEntries.length,
            'label': DateFormat('E d MMM').format(DateTime.parse(dayData['dateTime'])),
          });
          allEntries.addAll(dayData['entries']);
        }
      }
    } catch (e) {
      return const Scaffold(body: Center(child: Text("Swell data processing error")));
    }

    // Fallback if data is empty after processing
    if (allEntries.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Seacliff Sea & Swell")),
        body: const Center(child: Text("No swell data available for the selected range.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Seacliff Sea & Swell", style: TextStyle(color: Colors.black87, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 1,
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
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Stack(
              children: [
                GestureDetector(
                  // Safety: check if entries is empty before handling touch
                  onPanUpdate: (details) => allEntries.isNotEmpty ? _handleTouch(details.localPosition, allEntries) : null,
                  onTapDown: (details) => allEntries.isNotEmpty ? _handleTouch(details.localPosition, allEntries) : null,
                  child: Container(
                    height: 380,
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12)),
                    child: CustomPaint(
                      // Pass data to the painter
                      painter: SwellGraphPainter(allEntries, _hoverIndex, dayBoundaries),
                    ),
                  ),
                ),
                // Tooltip logic with null-safety
                if (_hoverIndex != null && _hoverIndex! >= 0 && _hoverIndex! < allEntries.length)
                  _buildSwellTooltip(allEntries[_hoverIndex!]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleTouch(Offset localPosition, List<dynamic> entries) {
    if (entries.length < 2) return; // Prevent division by zero
    
    double chartWidth = MediaQuery.of(context).size.width - 20;
    double stepX = chartWidth / (entries.length - 1);
    
    // Calculate index and clamp it to the list bounds
    int index = (localPosition.dx / stepX).round().clamp(0, entries.length - 1);
    
    if (_hoverIndex != index) {
      setState(() => _hoverIndex = index);
    }
  }

  Widget _buildSwellTooltip(dynamic entry) {
    try {
      final date = DateTime.parse(entry['dateTime']);
      final seaHeight = (entry['seaHeight'] ?? 0.0).toDouble().toStringAsFixed(1);
      final swellHeight = (entry['swellHeight'] ?? 0.0).toDouble().toStringAsFixed(1);
      final period = entry['swellPeriod'] ?? 0;
      
      return Positioned(
        top: 60,
        left: 20,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "${DateFormat('h:mm a').format(date)} | Sea: ${seaHeight}m | Swell: ${swellHeight}m (${period}s)",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink(); // Hide tooltip if data is malformed
    }
  }
}

class SwellGraphPainter extends CustomPainter {
  final List<dynamic> entries;
  final int? hoverIndex;
  final List<Map<String, dynamic>> dayBoundaries;

  SwellGraphPainter(this.entries, this.hoverIndex, this.dayBoundaries);

  @override
  void paint(Canvas canvas, Size size) {
    // CRITICAL FIX: Prevent crash if list is empty or size is invalid
    if (entries.isEmpty || size.width <= 0) return;

    final double stepX = size.width / (entries.length - 1);
    const double maxWaveHeight = 3.5; 
    const double topPad = 50.0;

    // Helper for Y calculation with safety
    double getY(dynamic h) {
      double height = (h ?? 0.0).toDouble();
      return size.height - (height / maxWaveHeight * (size.height - topPad)).clamp(0, size.height);
    }

    // 1. Internal Date Labels
    for (var boundary in dayBoundaries) {
      double x = boundary['startIndex'] * stepX;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), Paint()..color = Colors.black12);
      
      TextPainter(
        text: TextSpan(text: boundary['label'], style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
        textDirection: ui.TextDirection.ltr,
      )..layout()..paint(canvas, Offset(x + 8, 15));
    }

    // 2. SEAS (Significant Wave Height)
    if (entries.length >= 2) {
      final seaPath = Path();
      seaPath.moveTo(0, getY(entries[0]['seaHeight']));

      for (int i = 0; i < entries.length - 1; i++) {
        double x1 = i * stepX;
        double x2 = (i + 1) * stepX;
        double y1 = getY(entries[i]['seaHeight']);
        double y2 = getY(entries[i + 1]['seaHeight']);
        seaPath.cubicTo((x1 + x2) / 2, y1, (x1 + x2) / 2, y2, x2, y2);
      }
      canvas.drawPath(seaPath, Paint()..color = Colors.cyan.shade300..strokeWidth = 2..style = PaintingStyle.stroke);

      // 3. SWELL HEIGHT
      final swellPath = Path();
      swellPath.moveTo(0, getY(entries[0]['swellHeight']));
      for (int i = 0; i < entries.length - 1; i++) {
        double x1 = i * stepX;
        double x2 = (i + 1) * stepX;
        double y1 = getY(entries[i]['swellHeight']);
        double y2 = getY(entries[i + 1]['swellHeight']);
        swellPath.cubicTo((x1 + x2) / 2, y1, (x1 + x2) / 2, y2, x2, y2);
      }
      canvas.drawPath(swellPath, Paint()..color = Colors.blue.shade900..strokeWidth = 3..style = PaintingStyle.stroke);
    }

    // 4. Interactive Marker
    if (hoverIndex != null && hoverIndex! < entries.length) {
      double hX = hoverIndex! * stepX;
      double seaY = getY(entries[hoverIndex!]['seaHeight']);
      double swellY = getY(entries[hoverIndex!]['swellHeight']);

      canvas.drawLine(Offset(hX, topPad), Offset(hX, size.height), Paint()..color = Colors.blueGrey.withValues(alpha: 0.5));
      canvas.drawCircle(Offset(hX, seaY), 4, Paint()..color = Colors.cyan);
      canvas.drawCircle(Offset(hX, swellY), 5, Paint()..color = Colors.blue.shade900);
    }
  }

  @override
  bool shouldRepaint(covariant SwellGraphPainter oldDelegate) => true;
}
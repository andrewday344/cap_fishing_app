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
        title: const Text("Seacliff Tide Forecast", style: TextStyle(color: Colors.black87, fontSize: 18)),
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
                label: Text("${day}-Day"),
                selected: _daysToShow == day,
                onSelected: (selected) {
                  // Using your preferred block-style if
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
                  onPanUpdate: (details) => _handleTouch(details.localPosition, allEntries),
                  onTapDown: (details) => _handleTouch(details.localPosition, allEntries),
                  child: Container(
                    height: 350,
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12)),
                    child: CustomPaint(painter: TideGraphPainter(allEntries, _hoverIndex, dayBoundaries)),
                  ),
                ),
                if (_hoverIndex != null && _hoverIndex! < allEntries.length)
                  _buildTideTooltip(allEntries[_hoverIndex!]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleTouch(Offset localPosition, List<dynamic> entries) {
    double chartWidth = MediaQuery.of(context).size.width - 20;
    double stepX = chartWidth / (entries.length - 1);
    int index = (localPosition.dx / stepX).round().clamp(0, entries.length - 1);
    setState(() => _hoverIndex = index);
  }

  Widget _buildTideTooltip(dynamic entry) {
    final date = DateTime.parse(entry['dateTime']);
    final height = entry['height'].toStringAsFixed(2);
    return Positioned(
      top: 60,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: BorderRadius.circular(8)),
        child: Text("${DateFormat('h:mm a').format(date)} | $height m",
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
    const double maxH = 4.0; 
    const double topPad = 50.0;

    // Day/Night and Date Labels
    for (var boundary in dayBoundaries) {
      double x = boundary['startIndex'] * stepX;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), Paint()..color = Colors.black12);
      TextPainter(text: TextSpan(text: boundary['label'], style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
        textDirection: ui.TextDirection.ltr)..layout()..paint(canvas, Offset(x + 8, 15));
    }

    final path = Path();
    final fill = Path();
    double getY(h) => size.height - (h / maxH * (size.height - topPad));
    
    path.moveTo(0, getY(entries[0]['height']));
    fill.moveTo(0, size.height);
    fill.lineTo(0, getY(entries[0]['height']));

    for (int i = 0; i < entries.length - 1; i++) {
      double x1 = i * stepX, x2 = (i + 1) * stepX;
      double y1 = getY(entries[i]['height']), y2 = getY(entries[i + 1]['height']);
      path.cubicTo((x1 + x2) / 2, y1, (x1 + x2) / 2, y2, x2, y2);
      fill.cubicTo((x1 + x2) / 2, y1, (x1 + x2) / 2, y2, x2, y2);
    }
    fill.lineTo(size.width, size.height);
    fill.close();

    canvas.drawPath(fill, Paint()..color = Colors.blue.withOpacity(0.2));
    canvas.drawPath(path, Paint()..color = Colors.blue.shade700..strokeWidth = 3..style = PaintingStyle.stroke);

    if (hoverIndex != null) {
      double hX = hoverIndex! * stepX;
      double hY = getY(entries[hoverIndex!]['height']);
      canvas.drawLine(Offset(hX, topPad), Offset(hX, size.height), Paint()..color = Colors.blueAccent);
      canvas.drawCircle(Offset(hX, hY), 6, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(hX, hY), 6, Paint()..color = Colors.blue..style = PaintingStyle.stroke..strokeWidth = 2);
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
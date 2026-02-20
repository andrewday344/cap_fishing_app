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
  if (widget.forecastData['swell'] != null && widget.forecastData['swell']['days'] != null) {
    var days = widget.forecastData['swell']['days'] as List;
    int limit = _daysToShow > days.length ? days.length : _daysToShow;

    for (int i = 0; i < limit; i++) {
      var dayData = days[i];
      dayBoundaries.add({
        'startIndex': allEntries.length,
        'label': DateFormat('E d MMM').format(DateTime.parse(dayData['dateTime'])),
      });
      allEntries.addAll(dayData['entries']);
    }
  }
} catch (e) {
  return const Scaffold(body: Center(child: Text("Swell data loading error...")));
}

if (allEntries.isEmpty) {
  return Scaffold(
    appBar: AppBar(title: const Text("Seacliff Sea & Swell")),
    body: const Center(child: Text("No Swell data found. check API call.")),
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
              onPanUpdate: (details) => _handleTouch(details.localPosition, allEntries),
              onTapDown: (details) => _handleTouch(details.localPosition, allEntries),
              child: Container(
                height: 400,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white, 
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomPaint(
                  painter: SwellGraphPainter(allEntries, _hoverIndex, dayBoundaries),
                ),
              ),
            ),
            if (_hoverIndex != null && _hoverIndex! < allEntries.length)
              _buildSwellTooltip(allEntries[_hoverIndex!]),
          ],
        ),
      ),
    ],
  ),
);
}

void _handleTouch(Offset localPosition, List<dynamic> entries) {
if (entries.isEmpty) return;
double chartWidth = MediaQuery.of(context).size.width - 20;
double stepX = chartWidth / (entries.length > 1 ? entries.length - 1 : 1);
int index = (localPosition.dx / stepX).round().clamp(0, entries.length - 1);
setState(() => _hoverIndex = index);
}

Widget _buildSwellTooltip(dynamic entry) {
final date = DateTime.parse(entry['dateTime']);
final height = (entry['height'] ?? 0.0).toStringAsFixed(1);
final period = entry['period'] ?? '--';
final dir = entry['directionText'] ?? '--';

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
      "${DateFormat('h:mm a').format(date)} | Swell: ${height}m (${period}s) $dir",
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
    ),
  ),
);
}
}

class SwellGraphPainter extends CustomPainter {
final List<dynamic> entries;
final int? hoverIndex;
final List<Map<String, dynamic>> dayBoundaries;

SwellGraphPainter(this.entries, this.hoverIndex, this.dayBoundaries);

@override
void paint(Canvas canvas, Size size) {
if (entries.length < 2) return;

final double stepX = size.width / (entries.length - 1);
const double maxH = 4.0; 
const double topPad = 60.0;
const double arrowY = 360.0;

double getY(dynamic h) {
  final double val = (h is num) ? h.toDouble() : 0.0;
  return size.height - (val / maxH * (size.height - topPad - 40));
}

for (var boundary in dayBoundaries) {
  double x = boundary['startIndex'] * stepX;
  canvas.drawLine(Offset(x, 0), Offset(x, size.height), Paint()..color = Colors.black12);
  TextPainter(
    text: TextSpan(text: boundary['label'], style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold)),
    textDirection: ui.TextDirection.ltr,
  )..layout()..paint(canvas, Offset(x + 8, 20));
}

final swellPath = Path();
swellPath.moveTo(0, getY(entries[0]['height']));

for (int i = 0; i < entries.length - 1; i++) {
  double x1 = i * stepX;
  double x2 = (i + 1) * stepX;
  double y1 = getY(entries[i]['height']);
  double y2 = getY(entries[i+1]['height']);
  swellPath.cubicTo((x1 + x2) / 2, y1, (x1 + x2) / 2, y2, x2, y2);

  if (i % 4 == 0) {
    _drawArrow(canvas, Offset(x1, arrowY), entries[i]['direction'] ?? '');
  }
}

canvas.drawPath(swellPath, Paint()..color = Colors.blue.shade900..strokeWidth = 3..style = PaintingStyle.stroke);

if (hoverIndex != null && hoverIndex! < entries.length) {
  double hX = hoverIndex! * stepX;
  canvas.drawLine(Offset(hX, topPad), Offset(hX, size.height), Paint()..color = Colors.black26);
  canvas.drawCircle(Offset(hX, getY(entries[hoverIndex!]['height'])), 5, Paint()..color = Colors.blue.shade900);
}
}

void _drawArrow(Canvas canvas, Offset pos, String dir) {
if (dir.isEmpty) return;
final double angle = _getAngle(dir);
canvas.save();
canvas.translate(pos.dx, pos.dy);
canvas.rotate(angle);
final p = Path()..moveTo(0, 5)..lineTo(0, -5)..moveTo(-3, -1)..lineTo(0, -5)..lineTo(3, -1);
canvas.drawPath(p, Paint()..color = Colors.blueGrey..style = PaintingStyle.stroke..strokeWidth = 1.5);
canvas.restore();
}

double _getAngle(String dir) {
Map<String, double> a = {'N': 0, 'NE': 0.78, 'E': 1.57, 'SE': 2.35, 'S': 3.14, 'SW': 3.92, 'W': 4.71, 'NW': 5.49};
return a[dir.toUpperCase().substring(0, 1)] ?? 0;
}

@override
bool shouldRepaint(CustomPainter oldDelegate) => true;
}
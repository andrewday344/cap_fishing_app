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
  return const Scaffold(body: Center(child: Text("Swell data loading...")));
}

if (allEntries.isEmpty) {
  return Scaffold(
    appBar: AppBar(title: const Text("Seacliff Sea & Swell")),
    body: const Center(child: Text("No Swell data found.")),
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
                height: 420,
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
      "${DateFormat('h:mm a').format(date)} | Swell: ${height}m (${period}s)",
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
const double maxH = 6.0; // Standard 6m scale
const double topPad = 60.0;
const double arrowY = 380.0;

double getY(dynamic h) {
  final double val = (h is num) ? h.toDouble() : 0.0;
  return size.height - (val / maxH * (size.height - topPad - 80));
}

// 1. Day/Night Background Shading
for (int i = 0; i < entries.length - 1; i++) {
  final hour = DateTime.parse(entries[i]['dateTime']).hour;
  if (hour < 6 || hour >= 18) {
    final rect = Rect.fromLTWH(i * stepX, topPad, stepX, size.height - topPad);
    canvas.drawRect(rect, Paint()..color = const Color(0xFFE2E8F0));
  }
}

// 2. Large Grid Lines (2m, 4m, 6m)
final gridPaint = Paint()..color = Colors.black12..strokeWidth = 1;
for (int i = 0; i <= 6; i += 2) {
  double y = getY(i.toDouble());
  canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
  TextPainter(
    text: TextSpan(text: "${i}m", style: const TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.bold)),
    textDirection: ui.TextDirection.ltr,
  )..layout()..paint(canvas, Offset(5, y - 14));
}

// 3. Wave Path with Gradient Fill
final path = Path();
final fillPath = Path();
path.moveTo(0, getY(entries[0]['height']));
fillPath.moveTo(0, size.height);
fillPath.lineTo(0, getY(entries[0]['height']));

for (int i = 0; i < entries.length - 1; i++) {
  double x1 = i * stepX, x2 = (i + 1) * stepX;
  double y1 = getY(entries[i]['height']), y2 = getY(entries[i+1]['height']);
  path.cubicTo((x1 + x2) / 2, y1, (x1 + x2) / 2, y2, x2, y2);
  fillPath.cubicTo((x1 + x2) / 2, y1, (x1 + x2) / 2, y2, x2, y2);
}
fillPath.lineTo(size.width, size.height);
fillPath.close();

final gradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Colors.blue.withValues(alpha: 0.4), Colors.blue.withValues(alpha: 0.01)],
).createShader(Rect.fromLTWH(0, topPad, size.width, size.height - topPad));

canvas.drawPath(fillPath, Paint()..shader = gradient);
canvas.drawPath(path, Paint()..color = const Color(0xFF1E293B)..strokeWidth = 3..style = PaintingStyle.stroke);

// 4. MUCH LARGER Direction Arrows
for (int i = 0; i < entries.length; i++) {
  if (i % 4 == 0) {
    _drawLargeArrow(canvas, Offset(i * stepX, arrowY), entries[i]['direction'] ?? '');
  }
}

// 5. MUCH LARGER Hover Marker
if (hoverIndex != null && hoverIndex! < entries.length) {
  double hX = hoverIndex! * stepX;
  double hY = getY(entries[hoverIndex!]['height']);
  canvas.drawCircle(Offset(hX, hY), 8, Paint()..color = Colors.white);
  canvas.drawCircle(Offset(hX, hY), 8, Paint()..color = Colors.blue.shade900..style = PaintingStyle.stroke..strokeWidth = 3);
}
}

void _drawLargeArrow(Canvas canvas, Offset pos, String dir) {
if (dir.isEmpty) return;
final double angle = _getAngle(dir);
canvas.save();
canvas.translate(pos.dx, pos.dy);
canvas.rotate(angle);
final p = Path()..moveTo(0, 10)..lineTo(0, -10)..moveTo(-5, -2)..lineTo(0, -10)..lineTo(5, -2);
canvas.drawPath(p, Paint()..color = Colors.blue.shade900..style = PaintingStyle.stroke..strokeWidth = 2.5);
canvas.restore();
}

double _getAngle(String dir) {
Map<String, double> a = {'N': 0, 'NE': 0.78, 'E': 1.57, 'SE': 2.35, 'S': 3.14, 'SW': 3.92, 'W': 4.71, 'NW': 5.49};
return a[dir.toUpperCase().substring(0, 1)] ?? 0;
}

@override
bool shouldRepaint(CustomPainter oldDelegate) => true;
}
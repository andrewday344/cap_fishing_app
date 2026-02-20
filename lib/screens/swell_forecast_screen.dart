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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> allEntries = [];
    List<Map<String, dynamic>> dayBoundaries = [];

    try {
      if (widget.forecastData['swell'] != null && widget.forecastData['swell']['days'] != null) {
        var daysList = widget.forecastData['swell']['days'];
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
      debugPrint("Swell Data Error: $e");
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        // Step 3 Fix: Teal arrow to go back
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.teal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Seacliff Sea & Swell",
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 15),
                _buildDaySelector(),
                const SizedBox(height: 15),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Stack(
                      children: [
                        GestureDetector(
                          onPanUpdate: (details) => allEntries.isNotEmpty ? _handleTouch(details.localPosition, allEntries) : null,
                          onTapDown: (details) => allEntries.isNotEmpty ? _handleTouch(details.localPosition, allEntries) : null,
                          child: Container(
                            height: double.infinity,
                            width: double.infinity,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CustomPaint(
                                painter: SwellGraphPainter(allEntries, _hoverIndex, dayBoundaries),
                              ),
                            ),
                          ),
                        ),
                        if (_hoverIndex != null && _hoverIndex! < allEntries.length) _buildSwellTooltip(allEntries[_hoverIndex!]),
                        if (allEntries.isEmpty) const Center(child: Text("Waiting for swell data...", style: TextStyle(color: Colors.grey))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _buildDaySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [1, 3, 5].map((day) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
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
    final double sea = (entry['seaHeight'] ?? 0.0).toDouble();
    final double swell = (entry['swellHeight'] ?? 0.0).toDouble();
    final int period = entry['swellPeriod'] ?? 0;

    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _tooltipItem("TIME", DateFormat('h:mm a').format(date)),
            _tooltipItem("SEA", "${sea.toStringAsFixed(1)}m"),
            _tooltipItem("SWELL", "${swell.toStringAsFixed(1)}m"),
            _tooltipItem("PER", "${period}s"),
          ],
        ),
      ),
    );
  }

  Widget _tooltipItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
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
const double maxWaveHeight = 4.0; 
const double topPad = 60.0;
const double arrowY = 340.0; // Position for arrows near the bottom

double getY(dynamic h) {
  final double val = (h is num) ? h.toDouble() : 0.0;
  return size.height - (val / maxWaveHeight * (size.height - topPad));
}

// 1. Day Boundaries & Date Labels
for (var boundary in dayBoundaries) {
  double x = boundary['startIndex'] * stepX;
  canvas.drawLine(Offset(x, 0), Offset(x, size.height), Paint()..color = Colors.black12);
  TextPainter(
    text: TextSpan(
      text: boundary['label'], 
      style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold)
    ),
    textDirection: ui.TextDirection.ltr,
  )..layout()..paint(canvas, Offset(x + 8, 20));
}

// 2. Wave Paths
final seaPath = Path();
final swellPath = Path();
seaPath.moveTo(0, getY(entries[0]['seaHeight']));
swellPath.moveTo(0, getY(entries[0]['swellHeight']));

for (int i = 0; i < entries.length - 1; i++) {
  double x1 = i * stepX;
  double x2 = (i + 1) * stepX;
  seaPath.cubicTo((x1 + x2) / 2, getY(entries[i]['seaHeight']), (x1 + x2) / 2, getY(entries[i+1]['seaHeight']), x2, getY(entries[i+1]['seaHeight']));
  swellPath.cubicTo((x1 + x2) / 2, getY(entries[i]['swellHeight']), (x1 + x2) / 2, getY(entries[i+1]['swellHeight']), x2, getY(entries[i+1]['swellHeight']));
  
  // 3. DRAW DIRECTION ARROWS (Every 3rd entry to keep it clean)
  if (i % 3 == 0) {
    _drawArrow(canvas, Offset(x1, arrowY), entries[i]['swellDir'] ?? '');
  }
}

canvas.drawPath(seaPath, Paint()..color = Colors.cyan.shade300..strokeWidth = 2..style = PaintingStyle.stroke);
canvas.drawPath(swellPath, Paint()..color = Colors.blue.shade900..strokeWidth = 3..style = PaintingStyle.stroke);

// 4. Hover Marker
if (hoverIndex != null && hoverIndex! < entries.length) {
  double hX = hoverIndex! * stepX;
  canvas.drawLine(Offset(hX, topPad), Offset(hX, size.height), Paint()..color = Colors.black26);
  canvas.drawCircle(Offset(hX, getY(entries[hoverIndex!]['seaHeight'])), 4, Paint()..color = Colors.cyan);
  canvas.drawCircle(Offset(hX, getY(entries[hoverIndex!]['swellHeight'])), 5, Paint()..color = Colors.blue.shade900);
}
}

void _drawArrow(Canvas canvas, Offset position, String dir) {
if (dir.isEmpty) return;

final double angle = _getAngle(dir);
canvas.save();
canvas.translate(position.dx, position.dy);
canvas.rotate(angle);

final arrowPaint = Paint()
  ..color = Colors.blueGrey.withValues(alpha: 0.6)
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1.5;

final path = Path()
  ..moveTo(0, 6)
  ..lineTo(0, -6)
  ..moveTo(-3, -2)
  ..lineTo(0, -6)
  ..lineTo(3, -2);

canvas.drawPath(path, arrowPaint);
canvas.restore();
}

double _getAngle(String dir) {
Map<String, double> angles = {
'N': 0, 'NNE': 0.39, 'NE': 0.78, 'ENE': 1.17,
'E': 1.57, 'ESE': 1.96, 'SE': 2.35, 'SSE': 2.74,
'S': 3.14, 'SSW': 3.53, 'SW': 3.92, 'WSW': 4.31,
'W': 4.71, 'WNW': 5.10, 'NW': 5.49, 'NNW': 5.89,
};
return angles[dir.toUpperCase()] ?? 0;
}

@override
bool shouldRepaint(CustomPainter oldDelegate) => true;
}
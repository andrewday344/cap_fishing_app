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
    if (entries.isEmpty) return;

    final double stepX = size.width / (entries.length > 1 ? entries.length - 1 : 1);
    const double maxWaveHeight = 4.0;
    const double topPad = 60.0;

    double getY(dynamic h) {
      double height = (h ?? 0.0).toDouble();
      return size.height - (height / maxWaveHeight * (size.height - topPad)).clamp(0, size.height);
    }

    for (var boundary in dayBoundaries) {
      double x = boundary['startIndex'] * stepX;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), Paint()..color = Colors.black.withValues(alpha: 0.05));

      TextPainter(
        text: TextSpan(text: boundary['label'], style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 10, fontWeight: FontWeight.bold)),
        textDirection: ui.TextDirection.ltr,
      )..layout()..paint(canvas, Offset(x + 8, 20));
    }

    if (entries.length >= 2) {
      final seaPath = Path();
      seaPath.moveTo(0, getY(entries[0]['seaHeight']));
      for (int i = 0; i < entries.length - 1; i++) {
        double x1 = i * stepX, x2 = (i + 1) * stepX;
        double y1 = getY(entries[i]['seaHeight']), y2 = getY(entries[i + 1]['seaHeight']);
        seaPath.cubicTo((x1 + x2) / 2, y1, (x1 + x2) / 2, y2, x2, y2);
      }
      canvas.drawPath(seaPath, Paint()..color = Colors.cyan.withValues(alpha: 0.4)..strokeWidth = 2..style = PaintingStyle.stroke);

      final swellPath = Path();
      swellPath.moveTo(0, getY(entries[0]['swellHeight']));
      for (int i = 0; i < entries.length - 1; i++) {
        double x1 = i * stepX, x2 = (i + 1) * stepX;
        double y1 = getY(entries[i]['swellHeight']), y2 = getY(entries[i + 1]['swellHeight']);
        swellPath.cubicTo((x1 + x2) / 2, y1, (x1 + x2) / 2, y2, x2, y2);
      }
      canvas.drawPath(swellPath, Paint()..color = const Color(0xFF0F172A)..strokeWidth = 3..style = PaintingStyle.stroke);
    }

    if (hoverIndex != null && hoverIndex! < entries.length) {
      double hX = hoverIndex! * stepX;
      double seaY = getY(entries[hoverIndex!]['seaHeight']);
      double swellY = getY(entries[hoverIndex!]['swellHeight']);

      canvas.drawLine(Offset(hX, 0), Offset(hX, size.height), Paint()..color = Colors.blue.withValues(alpha: 0.2)..strokeWidth = 1);
      canvas.drawCircle(Offset(hX, seaY), 4, Paint()..color = Colors.cyan);
      canvas.drawCircle(Offset(hX, swellY), 6, Paint()..color = const Color(0xFF0F172A));
      canvas.drawCircle(Offset(hX, swellY), 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

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
    if (widget.forecastData['tides'] == null || 
        widget.forecastData['tides']['days'] == null || 
        (widget.forecastData['tides']['days'] as List).isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Tide Forecast")),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.water_drop_outlined, size: 50, color: Colors.grey),
              SizedBox(height: 10),
              Text("No tide data available.", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Please check your internet or refresh.", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    List<dynamic> rawEntries = [];
    List<dynamic> allEntries = [];
    List<Map<String, dynamic>> dayBoundaries = [];

    try {
      int availableDays = (widget.forecastData['tides']['days'] as List).length;
      int daysToProcess = math.min(_daysToShow, availableDays);

      // 1. Gather the raw High/Low markers
      for (int i = 0; i < daysToProcess; i++) {
        rawEntries.addAll(widget.forecastData['tides']['days'][i]['entries']);
      }

      // 2. Generate 30-minute incremental points between High and Low
      for (int i = 0; i < rawEntries.length - 1; i++) {
        var current = rawEntries[i];
        var next = rawEntries[i + 1];

        DateTime t1 = DateTime.parse(current['dateTime']);
        double h1 = (current['height'] as num).toDouble();
        DateTime t2 = DateTime.parse(next['dateTime']);
        double h2 = (next['height'] as num).toDouble();

        // Add the exact High/Low marker
        allEntries.add(current);

        // Step forward in 30-minute increments
        DateTime step = t1.add(const Duration(minutes: 30));
        while (step.isBefore(t2)) {
          double interpHeight = _interpolateTideHeight(step, t1, h1, t2, h2);
          allEntries.add({
            'dateTime': step.toIso8601String(),
            'height': interpHeight,
            'isIncremental': true, // Flags that this is a generated point
          });
          step = step.add(const Duration(minutes: 30));
        }
      }
      
      // Add the final API marker
      if (rawEntries.isNotEmpty) {
        allEntries.add(rawEntries.last);
      }

      // 3. Calculate Day Boundaries based on the new expanded list
      String currentDay = "";
      for (int i = 0; i < allEntries.length; i++) {
        String dayStr = DateFormat('E d MMM').format(DateTime.parse(allEntries[i]['dateTime']));
        if (dayStr != currentDay) {
          dayBoundaries.add({'startIndex': i, 'label': dayStr});
          currentDay = dayStr;
        }
      }

    } catch (e) {
      return const Scaffold(body: Center(child: Text("Error parsing tide data")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Seacliff Tide Forecast", style: TextStyle(color: Colors.black87, fontSize: 18)),
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

  // --- THE MATH ENGINE: Cosine Interpolation ---
  double _interpolateTideHeight(DateTime target, DateTime t1, double h1, DateTime t2, double h2) {
    int totalMinutes = t2.difference(t1).inMinutes;
    int elapsedMinutes = target.difference(t1).inMinutes;
    
    if (totalMinutes == 0) return h1; // Prevent division by zero
    
    double fraction = elapsedMinutes / totalMinutes;
    
    // (1 - cos(pi * fraction)) / 2 creates a perfect S-curve wave between 0 and 1
    double wavePhase = (1 - math.cos(math.pi * fraction)) / 2;
    
    return h1 + (h2 - h1) * wavePhase;
  }

  void _handleTouch(Offset localPosition, List<dynamic> entries) {
    if (entries.isEmpty) return;
    double chartWidth = MediaQuery.of(context).size.width - 20;
    double stepX = chartWidth / (entries.length > 1 ? entries.length - 1 : 1);
    int index = (localPosition.dx / stepX).round().clamp(0, entries.length - 1);
    setState(() => _hoverIndex = index);
  }

  Widget _buildTideTooltip(dynamic entry) {
    final date = DateTime.parse(entry['dateTime']);
    final height = (entry['height'] as num).toDouble().toStringAsFixed(2);
    
    // Add a marker to show if it's an exact High/Low or an intermediate calculation
    bool isPeak = entry['isIncremental'] != true;
    
    return Positioned(
      top: 60,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8), 
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isPeak ? Colors.cyanAccent : Colors.transparent, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${DateFormat('h:mm a').format(date)} | $height m",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            if (isPeak)
              const Text("Peak High/Low Marker", style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
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

    for (var boundary in dayBoundaries) {
      double x = boundary['startIndex'] * stepX;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), Paint()..color = Colors.black12);
      TextPainter(
        text: TextSpan(text: boundary['label'], style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
        textDirection: ui.TextDirection.ltr
      )..layout()..paint(canvas, Offset(x + 8, 15));
    }

    final path = Path();
    final fill = Path();
    double getY(h) => size.height - (h / maxH * (size.height - topPad));
    
    path.moveTo(0, getY(entries[0]['height']));
    fill.moveTo(0, size.height);
    fill.lineTo(0, getY(entries[0]['height']));

    // We can just use lineTo now, because our math engine has already generated the S-curve curve mathematically!
    for (int i = 0; i < entries.length; i++) {
      double x = i * stepX;
      double y = getY(entries[i]['height']);
      path.lineTo(x, y);
      fill.lineTo(x, y);
    }
    
    fill.lineTo(size.width, size.height);
    fill.close();

    canvas.drawPath(fill, Paint()..color = Colors.blue.withValues(alpha: 0.2));
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
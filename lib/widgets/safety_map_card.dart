import 'package:flutter/material.dart';

class SafetyMapCard extends StatelessWidget {
  final double distanceInMeters;
  final String temp;
  final String? warning;
  final String windSpeed;

  const SafetyMapCard({
    super.key, 
    required this.distanceInMeters,
    required this.temp,
    this.warning,
    required this.windSpeed,
  });

  @override
  Widget build(BuildContext context) {
    double kms = distanceInMeters / 1000;
    bool isTooFar = kms > 3.7;
    bool hasWarning = warning != null && warning!.toLowerCase() != "nil" && warning!.isNotEmpty;

    return Column(
      children: [
        // 1. BRIDGE STATS ROW (Temp | Wind | Warning)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // TEMPERATURE
              _buildBridgeStat("TEMP", "$temp°C", Icons.thermostat, Colors.orange),
              
              // CENTRAL WIND SPEED
              Column(
                children: [
                  Text(
                    windSpeed,
                    style: const TextStyle(fontSize: 58, fontWeight: FontWeight.w900, height: 1.0),
                  ),
                  const Text("WIND KNOTS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ],
              ),

              // WARNINGS
              _buildBridgeStat(
                "STATUS", 
                hasWarning ? "WARNING" : "CLEAR", 
                hasWarning ? Icons.warning_amber_rounded : Icons.check_circle_outline, 
                hasWarning ? Colors.red : Colors.green,
                subText: hasWarning ? warning : "NIL",
              ),
            ],
          ),
        ),

        // 2. DISTANCE CARD (Your original logic)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isTooFar ? Colors.red.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isTooFar ? Colors.red : Colors.blue.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(
                isTooFar ? Icons.warning_amber_rounded : Icons.sailing,
                color: isTooFar ? Colors.red : Colors.blue,
                size: 40,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Distance to Seacliff Ramp", 
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text("${kms.toStringAsFixed(2)} km", 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Text(
                isTooFar ? "OUTSIDE RANGE" : "SAFE RANGE",
                style: TextStyle(
                  color: isTooFar ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBridgeStat(String label, String value, IconData icon, Color color, {String? subText}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(subText ?? label, style: const TextStyle(fontSize: 9, color: Colors.black45, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
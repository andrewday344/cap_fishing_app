import 'package:flutter/material.dart';

class SafetyMapCard extends StatelessWidget {
  final double distanceInMeters;
  final String temp;
  final String? warning;
  final String windSpeed;
  final String boatSpeed; // Added boat speed parameter

  const SafetyMapCard({
    super.key, 
    required this.distanceInMeters,
    required this.temp,
    this.warning,
    required this.windSpeed,
    required this.boatSpeed,
  });

  @override
  Widget build(BuildContext context) {
    double kms = distanceInMeters / 1000;
    bool isTooFar = kms > 3.7;
    bool hasWarning = warning != null && warning!.toLowerCase() != "nil" && warning!.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBridgeStat("TEMP", "$temp°C", Icons.thermostat, Colors.orange),
              
              // Central Wind Speed
              Column(
                children: [
                  Text(windSpeed, style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w900, height: 1.0)),
                  const Text("WIND KNOTS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ],
              ),

              // Boat Speed (Speedometer moved here)
              _buildBridgeStat("SPEED", "$boatSpeed kts", Icons.speed, Colors.blueAccent),
            ],
          ),
        ),
        
        // Status/Warning Bar
        if (hasWarning) 
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text("⚠️ $warning", style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
          ),

        // Distance Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isTooFar ? Colors.red.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isTooFar ? Colors.red : Colors.blue.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(isTooFar ? Icons.warning_amber_rounded : Icons.sailing, color: isTooFar ? Colors.red : Colors.blue, size: 32),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Distance to Seacliff Ramp", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text("${kms.toStringAsFixed(2)} km", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBridgeStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 8, color: Colors.black45, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
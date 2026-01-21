import 'package:flutter/material.dart';

class SafetyMapCard extends StatelessWidget {
  final double distanceInMeters;

  const SafetyMapCard({super.key, required this.distanceInMeters});

  @override
  Widget build(BuildContext context) {
    double kms = distanceInMeters / 1000;
    bool isTooFar = kms > 5.0; // Warning if > 5km from Seacliff

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTooFar ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isTooFar ? Colors.red : Colors.blue.shade100),
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
    );
  }
}
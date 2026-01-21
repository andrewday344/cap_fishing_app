import 'package:flutter/material.dart';

class TideCard extends StatelessWidget {
  const TideCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004E92), Color(0xFF000428)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            // FIX: Changed from .separated to .spaceBetween
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              Text("TIDE STATUS", style: TextStyle(color: Colors.white70, fontSize: 12)),
              Icon(Icons.trending_up, color: Colors.cyanAccent, size: 16),
            ],
          ),
          const SizedBox(height: 10),
          const Text("1.2m and Rising", 
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text("High Tide at 4:30 PM", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: 0.7, 
            backgroundColor: Colors.white12,
            color: Colors.cyanAccent,
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
        ],
      ),
    );
  }
}
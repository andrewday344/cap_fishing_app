import 'package:flutter/material.dart';
import '../models/fish_model.dart';

class FishGalleryScreen extends StatelessWidget {
  const FishGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SA Fish Gallery")),
      body: ListView.builder(
        itemCount: saFishGallery.length,
          itemBuilder: (context, index) {
            final fish = saFishGallery[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Visual Sticker/Badge
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: fish.statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.straighten, color: fish.statusColor),
                    ),
                    const SizedBox(width: 16),
                    // Fish Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fish.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.rule, size: 14, color: Colors.grey),
                              Text(" Min: ${fish.sizeLimit}", style: const TextStyle(color: Colors.grey)),
                              const SizedBox(width: 12),
                              const Icon(Icons.shopping_bag, size: 14, color: Colors.grey),
                              Text(" Bag: ${fish.bagLimit}", style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (fish.statusColor == Colors.red)
                      const Tooltip(message: "Closure in Place", child: Icon(Icons.warning, color: Colors.red)),
                  ],
                ),
              ),
            );
          },
      ),
    );
  }
}
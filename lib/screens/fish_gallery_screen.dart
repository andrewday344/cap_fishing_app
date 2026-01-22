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
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.phishing, color: Colors.blue),
              title: Text(fish.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Size: ${fish.sizeLimit} | Bag: ${fish.bagLimit}"),
              trailing: const Icon(Icons.chevron_right),
            ),
          );
        },
      ),
    );
  }
}
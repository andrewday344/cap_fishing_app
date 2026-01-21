import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/catch_model.dart';

class LogbookScreen extends StatelessWidget {
  const LogbookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Private Logbook"),
        backgroundColor: const Color(0xFF004E92),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Catch>>(
        // Fetch all catches from our private database
        future: DatabaseService.instance.readAllCatches(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No catches logged yet. Tight lines!"),
            );
          }

          final catches = snapshot.data!;

          return ListView.builder(
            itemCount: catches.length,
            itemBuilder: (context, index) {
              final item = catches[index];
              // Format the date string to be more readable
              final displayDate = item.date.split('T')[0]; 

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF004E92),
                    child: Icon(Icons.phishing, color: Colors.white),
                  ),
                  title: Text(
                    "${item.quantity} x ${item.species}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(item.notes.isEmpty ? "No notes" : item.notes),
                  trailing: Text(
                    displayDate,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
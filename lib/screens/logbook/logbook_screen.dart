import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../models/catch_model.dart';

class LogbookScreen extends StatefulWidget {
  const LogbookScreen({super.key});

  @override
  State<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends State<LogbookScreen> {
  late Future<List<Catch>> _logFuture;

  @override
  void initState() {
    super.initState();
    _refreshLog();
  }

  void _refreshLog() {
    setState(() {
      _logFuture = DatabaseService.instance.readAllCatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Your Private Logbook", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF004E92),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Catch>>(
        future: _logFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No catches logged yet. Tight lines!"));
          }

          final catches = snapshot.data!;

          return ListView.builder(
            itemCount: catches.length,
            itemBuilder: (context, index) {
              final item = catches[index];
              final date = DateTime.tryParse(item.date) ?? DateTime.now();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  onTap: () => _showCatchDetails(item),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF004E92),
                    child: Icon(Icons.phishing, color: Colors.white),
                  ),
                  title: Text(
                    "${item.quantity} x ${item.species}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(
                    "${DateFormat('E d MMM').format(date)} - ${item.notes.isEmpty ? 'No notes' : item.notes}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCatchDetails(Catch item) {
    final TextEditingController speciesController = TextEditingController(text: item.species);
    final TextEditingController qtyController = TextEditingController(text: item.quantity.toString());
    final TextEditingController notesController = TextEditingController(text: item.notes);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalContext) => Padding( // Using modalContext to be explicit
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("EDIT CATCH DATA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 15),
              TextField(
                controller: speciesController,
                decoration: const InputDecoration(labelText: "Species", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Quantity", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Notes", border: OutlineInputBorder()),
              ),
              
              const SizedBox(height: 25),
              const Text("WEATHER INTEL (READ ONLY)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 10),
              
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    _weatherRow(Icons.thermostat, "Temp", "${item.temp.toStringAsFixed(1)}°C"),
                    const Divider(),
                    _weatherRow(Icons.air, "Wind", "${item.wind.toStringAsFixed(1)} kts"),
                    const Divider(),
                    _weatherRow(Icons.tsunami, "Tide", item.tide),
                  ],
                ),
              ),
              
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: TextButton(onPressed: () => Navigator.pop(modalContext), child: const Text("Cancel")),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final updatedCatch = item.copy(
                          species: speciesController.text,
                          quantity: int.tryParse(qtyController.text) ?? item.quantity,
                          notes: notesController.text,
                        );
                        
                        await DatabaseService.instance.update(updatedCatch);
                        
                        // THE FIX: Check both the widget's mounted status and the context's status
                        if (!mounted || !modalContext.mounted) return;
                        
                        Navigator.pop(modalContext);
                        _refreshLog();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004E92), 
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Save Changes"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weatherRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Text("$label:", style: const TextStyle(color: Colors.black54)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}
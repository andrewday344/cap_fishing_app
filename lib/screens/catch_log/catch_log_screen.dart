import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/catch_model.dart';

class CatchLogScreen extends StatefulWidget {
  const CatchLogScreen({super.key});

  @override
  State<CatchLogScreen> createState() => _CatchLogScreenState();
}

class _CatchLogScreenState extends State<CatchLogScreen> {
  String? selectedSpecies;
  int quantity = 1;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _speciesController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // South Australian specific species list
  final List<Map<String, dynamic>> speciesList = [
    {'name': 'KG Whiting', 'icon': Icons.set_meal},
    {'name': 'Snapper', 'icon': Icons.set_meal_outlined},
    {'name': 'Calamari', 'icon': Icons.waves}, // Squid placeholder
    {'name': 'Blue Crab', 'icon': Icons.wb_sunny_outlined}, // Crab placeholder
    {'name': 'Garfish', 'icon': Icons.horizontal_rule},
    {'name': 'Other', 'icon': Icons.add},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Log Private Catch")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("What did you catch?", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            // 1. Species Selection Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: speciesList.length,
              itemBuilder: (context, index) {
                final species = speciesList[index];
                final isSelected = selectedSpecies == species['name'];
                return InkWell(
                  onTap: () => setState(() => selectedSpecies = species['name']),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.shade900 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade900),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(species['icon'], 
                            color: isSelected ? Colors.white : Colors.blue.shade900),
                        Text(species['name'], 
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.blue.shade900,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // 2. Quantity Selector
            const Text("How many?", style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                IconButton(onPressed: () => setState(() => quantity > 1 ? quantity-- : null), 
                    icon: const Icon(Icons.remove_circle_outline)),
                Text("$quantity", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => setState(() => quantity++), 
                    icon: const Icon(Icons.add_circle_outline)),
              ],
            ),

            const SizedBox(height: 20),

            // 3. Private Notes (Location nickname)
            const Text("Private Notes (Location, Bait, etc.)", 
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: "e.g. Near the Seacliff blocks, squid jag...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 30),

            // 4. Save Button
            ElevatedButton(
            onPressed: selectedSpecies == null ? null : () async {
                // 1. Prepare the data
                final newCatch = Catch(
                  species: _speciesController.text,
                  length: double.tryParse(_lengthController.text) ?? 0.0, // Ensure this is named 'length'
                  quantity: int.tryParse(_quantityController.text) ?? 1,
                  notes: _notesController.text,
                  date: DateTime.now().toString(),
                );

                // 2. Perform the async database operation
                await DatabaseService.instance.createCatch(newCatch);

                // 3. THE FIX: Guard against the async gap
                // If the user navigated away while the DB was working, stop here.
                if (!mounted) return;

                // 4. Safe to use context now
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                
                // Use ScaffoldMessenger safely
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Catch saved privately to your device."),
                    backgroundColor: Color(0xFF004E92),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: Colors.blue.shade900,
                foregroundColor: Colors.white,
              ),
              child: const Text("SAVE TO PRIVATE LOG"),
            ),
          ],
        ),
      ),
    );
  }
}
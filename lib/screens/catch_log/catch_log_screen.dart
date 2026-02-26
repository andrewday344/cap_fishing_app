import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart'; 
import '../../models/catch_model.dart';

class FishSpecies {
  final String name;
  bool isFavorite;
  final String pirsaInfo;

  FishSpecies({
    required this.name,
    this.isFavorite = false,
    this.pirsaInfo = "Check PIRSA for size/bag limits.",
  });
}

class LoggedCatch {
  final String speciesName;
  final int quantity;
  final String notes;
  final DateTime timestamp;
  final Map<String, dynamic> environmentalData;

  LoggedCatch({
    required this.speciesName,
    required this.quantity,
    required this.notes,
    required this.timestamp,
    required this.environmentalData,
  });
}

class CatchLogScreen extends StatefulWidget {
  final Map<String, dynamic>? currentWeatherData;
  const CatchLogScreen({super.key, this.currentWeatherData});

  @override
  State<CatchLogScreen> createState() => _CatchLogScreenState();
}

class _CatchLogScreenState extends State<CatchLogScreen> {
  final List<LoggedCatch> _sessionCatches = [];
  final TextEditingController _qtyController = TextEditingController(text: "1");
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _customFishController = TextEditingController();
  
  FishSpecies? _selectedSpecies;

  // Updated SA Species List for 2026
  final List<FishSpecies> _allSpecies = [
    FishSpecies(name: "King George Whiting", isFavorite: true, pirsaInfo: "Min: 32cm (East of 136°E) | Bag: 10"),
    FishSpecies(name: "Snapper", isFavorite: true, pirsaInfo: "Strict zone closures apply. Check PIRSA."),
    FishSpecies(name: "Squid (Calamari)", isFavorite: true, pirsaInfo: "Bag: 15 per person | Boat: 45."),
    FishSpecies(name: "Blue Swimmer Crab", isFavorite: true, pirsaInfo: "Min: 11cm | Bag: 20."),
    FishSpecies(name: "Garfish", isFavorite: false, pirsaInfo: "Min: 23cm | Bag: 30."),
    FishSpecies(name: "Mulloway", isFavorite: false, pirsaInfo: "Min: 46cm (Check Coorong specs)"),
  ];

  void _addCatchToSession() {
    if (_selectedSpecies == null) return;

    // Snapshot of conditions at time of catch for your future Notification Engine
    final Map<String, dynamic> snapShot = {
      'temp': widget.currentWeatherData?['temp'] ?? 0,
      'wind': widget.currentWeatherData?['windKnots'] ?? 0,
      'tide': widget.currentWeatherData?['nextTide'] ?? 'Unknown',
    };

    setState(() {
      _sessionCatches.add(LoggedCatch(
        speciesName: _selectedSpecies!.name,
        quantity: int.tryParse(_qtyController.text) ?? 1,
        notes: _notesController.text,
        timestamp: DateTime.now(),
        environmentalData: snapShot,
      ));
      
      _selectedSpecies = null;
      _qtyController.text = "1";
      _notesController.clear();
    });
  }

  // Finalizes the session and saves each record to Hive (Browser Storage)
  void _saveSession() async {
    for (var log in _sessionCatches) {
      final newCatch = Catch(
        species: log.speciesName,
        quantity: log.quantity,
        notes: log.notes,
        date: log.timestamp.toIso8601String(),
        temp: (log.environmentalData['temp'] as num).toDouble(),
        wind: (log.environmentalData['wind'] as num).toDouble(),
        tide: log.environmentalData['tide'],
      );
      
      await DatabaseService.instance.saveCatch(newCatch);
    }
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Session saved to your private logs.")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Session Log", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSpeciesSelector(),
                  const SizedBox(height: 20),
                  _buildQtyAndNotes(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _selectedSpecies == null ? null : _addCatchToSession,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: const Color(0xFF004E92),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("ADD TO TODAY'S LOG"),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            alignment: Alignment.centerLeft,
            child: Text("TODAY'S CATCHES (${_sessionCatches.length})", 
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
          Expanded(
            flex: 3,
            child: _sessionCatches.isEmpty 
              ? const Center(child: Text("No catches added yet today."))
              : ListView.builder(
                  itemCount: _sessionCatches.length,
                  itemBuilder: (context, index) {
                    final item = _sessionCatches[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.set_meal)),
                        title: Text("${item.quantity} x ${item.speciesName}"),
                        subtitle: Text("${DateFormat('h:mm a').format(item.timestamp)} - ${item.notes.isEmpty ? 'No notes' : item.notes}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => setState(() => _sessionCatches.removeAt(index)),
                        ),
                      ),
                    );
                  },
                ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: _sessionCatches.isEmpty ? null : _saveSession,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 65),
                backgroundColor: const Color(0xFF004E92),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("FINISH & SAVE SESSION", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeciesSelector() {
    return GestureDetector(
      onTap: () => _showSpeciesPicker(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.blue),
            const SizedBox(width: 15),
            Text(_selectedSpecies?.name ?? "Find Species...", 
              style: TextStyle(fontSize: 18, color: _selectedSpecies == null ? Colors.grey : Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyAndNotes() {
    return Column(
      children: [
        Row(
          children: [
            const Text("QTY: ", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.zero),
              ),
            ),
            const SizedBox(width: 20),
            const Expanded(child: Text("Notes (e.g. Depth, Bait)")),
          ],
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _notesController,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: "Enter details (e.g. 'off Seacliff reef')...",
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  void _showSpeciesPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                const SizedBox(width: 40, height: 5, child: DecoratedBox(decoration: BoxDecoration(color: Colors.black12))),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: _allSpecies.length + 1,
                    itemBuilder: (context, i) {
                      if (i == _allSpecies.length) return _buildAddCustomTile(setModalState);
                      final fish = _allSpecies[i];
                      return ListTile(
                        title: Text(fish.name),
                        subtitle: Text(fish.pirsaInfo, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                        trailing: Icon(fish.isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                        onTap: () {
                          setState(() => _selectedSpecies = fish);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddCustomTile(Function setModalState) {
    return Column(
      children: [
        const Divider(),
        TextField(
          controller: _customFishController,
          decoration: const InputDecoration(hintText: "Add custom species...", border: OutlineInputBorder()),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            if (_customFishController.text.isNotEmpty) {
              final newFish = FishSpecies(name: _customFishController.text, isFavorite: true);
              setState(() {
                _allSpecies.add(newFish);
                _selectedSpecies = newFish;
              });
              Navigator.pop(context);
            }
          },
          child: const Text("ADD NEW SPECIES"),
        ),
      ],
    );
  }
}
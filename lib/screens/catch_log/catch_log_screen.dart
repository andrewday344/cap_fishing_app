//import '../../models/catch_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

class CatchLogScreen extends StatefulWidget {
  const CatchLogScreen({super.key});

  @override
  State<CatchLogScreen> createState() => _CatchLogScreenState();
}

class _CatchLogScreenState extends State<CatchLogScreen> {
  final TextEditingController _quantityController = TextEditingController(text: "1");
  final TextEditingController _customFishController = TextEditingController();
  
  FishSpecies? _selectedSpecies;
  DateTime _selectedDate = DateTime.now();

  // --- SA TOP 10 & INITIAL SPECIES LIST ---
  final List<FishSpecies> _allSpecies = [
    FishSpecies(name: "King George Whiting", isFavorite: true, pirsaInfo: "Min: 32cm (East of 136°E) | Bag: 10"),
    FishSpecies(name: "Snapper", isFavorite: true, pirsaInfo: "CURRENT CLOSURE: Check PIRSA for zones."),
    FishSpecies(name: "Squid (Calamari)", isFavorite: true, pirsaInfo: "Bag: 15 per person."),
    FishSpecies(name: "Blue Swimmer Crab", isFavorite: true, pirsaInfo: "Min: 11cm | Bag: 20."),
    FishSpecies(name: "Garfish", isFavorite: false, pirsaInfo: "Min: 23cm | Bag: 30."),
    FishSpecies(name: "Australian Salmon", isFavorite: false, pirsaInfo: "Min: 21cm | Bag: 20."),
    FishSpecies(name: "Mulloway", isFavorite: false, pirsaInfo: "Min: 46cm (check zone) | Bag: 2-5."),
    FishSpecies(name: "Flathead", isFavorite: false, pirsaInfo: "Min: 30cm | Bag: 10."),
    FishSpecies(name: "Snook", isFavorite: false, pirsaInfo: "Min: 45cm | Bag: 20."),
    FishSpecies(name: "Tommie Ruff", isFavorite: false, pirsaInfo: "Bag: 60."),
  ];

  @override
  Widget build(BuildContext context) {
    // Sort so favorites appear at the top
    _allSpecies.sort((a, b) => (b.isFavorite ? 1 : 0).compareTo(a.isFavorite ? 1 : 0));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Record Private Catch", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("WHAT DID YOU CATCH?", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 10),
            
            // 1. SPECIES SELECTOR TILE
            GestureDetector(
              onTap: () => _showSpeciesPicker(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.set_meal, color: Colors.blue, size: 30),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        _selectedSpecies?.name ?? "Select Species...",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _selectedSpecies == null ? Colors.black38 : Colors.black87,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 30),
                  ],
                ),
              ),
            ),

            // 2. PIRSA INFO BOX (Dynamic based on selection)
            if (_selectedSpecies != null) ...[
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedSpecies!.pirsaInfo,
                        style: const TextStyle(fontSize: 13, color: Colors.brown, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 25),
            
            // 3. QUANTITY SELECTOR
            const Text("HOW MANY?", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 10),
            Row(
              children: [
                _qtyBtn(Icons.remove, () => _updateQty(-1)),
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                ),
                _qtyBtn(Icons.add, () => _updateQty(1)),
              ],
            ),

            const SizedBox(height: 30),

            // 4. DATE/TIME SELECTOR
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Date of Catch", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(DateFormat('EEEE, MMM d, yyyy').format(_selectedDate)),
              trailing: const Icon(Icons.calendar_month, color: Colors.blue),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
            ),

            const SizedBox(height: 40),

            // 5. SAVE BUTTON
            ElevatedButton(
              onPressed: _selectedSpecies == null ? null : () => _saveCatch(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004E92),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 70),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("SAVE TO LOGBOOK", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _qtyBtn(IconData icon, VoidCallback tap) {
    return IconButton(
      onPressed: tap,
      icon: Icon(icon, size: 40, color: Colors.blue),
    );
  }

  void _updateQty(int delta) {
    int current = int.tryParse(_quantityController.text) ?? 0;
    if (current + delta >= 0) {
      setState(() => _quantityController.text = (current + delta).toString());
    }
  }

  void _showSpeciesPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  const Text("Select Species", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _allSpecies.length + 1,
                      itemBuilder: (context, i) {
                        if (i == _allSpecies.length) {
                          return _buildAddCustomTile(setModalState);
                        }
                        final fish = _allSpecies[i];
                        return ListTile(
                          leading: Icon(Icons.set_meal, color: fish.isFavorite ? Colors.red : Colors.grey),
                          title: Text(fish.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          trailing: IconButton(
                            icon: Icon(fish.isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                            onPressed: () {
                              setState(() => fish.isFavorite = !fish.isFavorite);
                              setModalState(() {}); // Refresh modal list
                            },
                          ),
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
        );
      },
    );
  }

  Widget _buildAddCustomTile(Function setModalState) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 40),
      child: Column(
        children: [
          const Divider(),
          const Text("Can't find your fish?", style: TextStyle(fontStyle: FontStyle.italic)),
          const SizedBox(height: 10),
          TextField(
            controller: _customFishController,
            decoration: const InputDecoration(
              hintText: "Enter custom species name",
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.add_circle_outline),
            ),
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
            child: const Text("ADD & SET AS FAVORITE"),
          ),
        ],
      ),
    );
  }

  void _saveCatch() {
    // This will eventually link to the Notification Module logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Logged ${_quantityController.text} x ${_selectedSpecies!.name}!")),
    );
    Navigator.pop(context);
  }
}

import 'package:flutter/material.dart';

class _GalleryFish {
  final String name;
  final String scientificName;
  final String sizeLimit;
  final String bagLimit;
  final String boatLimit;
  final String rules;
  final Color themeColor;
  final IconData icon;

  _GalleryFish({
    required this.name,
    required this.scientificName,
    required this.sizeLimit,
    required this.bagLimit,
    required this.boatLimit,
    required this.rules,
    required this.themeColor,
    required this.icon,
  });
}

class FishGalleryScreen extends StatefulWidget {
  const FishGalleryScreen({super.key});

  @override
  State<FishGalleryScreen> createState() => _FishGalleryScreenState();
}

class _FishGalleryScreenState extends State<FishGalleryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<_GalleryFish> _filteredFishes = [];

  // Pre-loaded with South Australian (PIRSA) limits
  final List<_GalleryFish> _allFishes = [
    _GalleryFish(
      name: "King George Whiting",
      scientificName: "Sillaginodes punctatus",
      sizeLimit: "32 cm", // 30cm West of 136°E, 32cm East
      bagLimit: "10",
      boatLimit: "30",
      rules: "Measured from tip of snout to tip of the tail. Different size limits apply west of longitude 136°E (30cm).",
      themeColor: Colors.amber.shade700,
      icon: Icons.set_meal,
    ),
    _GalleryFish(
      name: "Snapper",
      scientificName: "Chrysophrys auratus",
      sizeLimit: "CLOSED",
      bagLimit: "0",
      boatLimit: "0",
      rules: "Currently subject to strict closures in the Spencer Gulf, West Coast, and Gulf St Vincent. Catch and release only in closed zones. Heavy fines apply.",
      themeColor: Colors.red.shade700,
      icon: Icons.phishing,
    ),
    _GalleryFish(
      name: "Southern Calamari (Squid)",
      scientificName: "Sepioteuthis australis",
      sizeLimit: "No Limit",
      bagLimit: "15",
      boatLimit: "45",
      rules: "No minimum size limit. Bag and boat limits apply to combined catch of cuttlefish and calamari.",
      themeColor: Colors.deepPurple,
      icon: Icons.water_drop,
    ),
    _GalleryFish(
      name: "Blue Swimmer Crab",
      scientificName: "Portunus armatus",
      sizeLimit: "11 cm",
      bagLimit: "20",
      boatLimit: "60",
      rules: "Measured across the carapace from side to side. Females with external eggs must be returned to the water immediately.",
      themeColor: Colors.blue.shade700,
      icon: Icons.bug_report, // Closest default icon for a crab
    ),
    _GalleryFish(
      name: "Southern Garfish",
      scientificName: "Hyporhamphus melanochir",
      sizeLimit: "23 cm",
      bagLimit: "30",
      boatLimit: "90",
      rules: "Measured from the tip of the upper jaw to the tip of the upper half of the tail.",
      themeColor: Colors.teal,
      icon: Icons.set_meal_outlined,
    ),
    _GalleryFish(
      name: "Mulloway",
      scientificName: "Argyrosomus japonicus",
      sizeLimit: "46 cm",
      bagLimit: "2",
      boatLimit: "6",
      rules: "Measured from tip of snout to tip of tail. Coorong limits may vary.",
      themeColor: Colors.blueGrey,
      icon: Icons.set_meal,
    ),
    _GalleryFish(
      name: "Flathead (All Species)",
      scientificName: "Platycephalus spp.",
      sizeLimit: "30 cm",
      bagLimit: "10",
      boatLimit: "30",
      rules: "Combined limit applies to all flathead species.",
      themeColor: Colors.brown,
      icon: Icons.set_meal,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredFishes = _allFishes;
    _searchController.addListener(_filterFishes);
  }

  void _filterFishes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFishes = _allFishes.where((fish) {
        return fish.name.toLowerCase().contains(query) || 
               fish.scientificName.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("SA Size & Bag Limits", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search species (e.g., Whiting, Crab)...",
                prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // Fish List
          Expanded(
            child: _filteredFishes.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filteredFishes.length,
                    itemBuilder: (context, index) {
                      final fish = _filteredFishes[index];
                      return _buildFishCard(fish);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFishCard(_GalleryFish fish) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: fish.themeColor.withAlpha(30),
          child: Icon(fish.icon, color: fish.themeColor),
        ),
        title: Text(fish.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(fish.scientificName, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          
          // Limit Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLimitBadge("Size Limit", fish.sizeLimit, fish.sizeLimit == "CLOSED" ? Colors.red : Colors.blueGrey),
              _buildLimitBadge("Bag Limit", fish.bagLimit, Colors.green.shade700),
              _buildLimitBadge("Boat Limit", fish.boatLimit, Colors.teal),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Rules / Notes
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    fish.rules,
                    style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withAlpha(50)),
          ),
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No species found for '${_searchController.text}'",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
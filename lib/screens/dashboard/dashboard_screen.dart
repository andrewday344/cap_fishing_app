import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/safety_item_model.dart';
import '../safety/safety_equipment_screen.dart'; // Import your new screen
// ... existing imports (Wind, Tide, Swell, CatchLog, Logbook)

class DashboardScreen extends StatefulWidget {
  final bool isInshore;
  const DashboardScreen({super.key, required this.isInshore});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Existing weather/location variables...
  List<SafetyItem> _safetyGear = [];

  @override
  void initState() {
    super.initState();
    _loadSafetyStatus();
    // ... your existing init code
  }

  Future<void> _loadSafetyStatus() async {
    final gear = await DatabaseService.instance.getAllSafetyItems();
    setState(() => _safetyGear = gear);
  }

  @override
  Widget build(BuildContext context) {
    // Check if anything is expired or expiring soon
    final expiredCount = _safetyGear.where((item) => item.daysUntilExpiry < 0).length;
    final warningCount = _safetyGear.where((item) => item.daysUntilExpiry >= 0 && item.daysUntilExpiry < 30).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("SEACLIFF FISHING", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _loadSafetyStatus()),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- MODULE 1: SAFETY SUMMARY (Dynamic) ---
            _buildSafetySummaryCard(expiredCount, warningCount),
            const SizedBox(height: 20),

            // --- MODULE 2: NAVIGATION HUB ---
            _buildSectionHeader("ENVIRONMENT"),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _NavIconTile(label: "Wind", icon: Icons.air, color: Colors.blue, onTap: () {}),
                _NavIconTile(label: "Tides", icon: Icons.tsunami, color: Colors.blueAccent, onTap: () {}),
                _NavIconTile(label: "Swell", icon: Icons.waves, color: Colors.indigo, onTap: () {}),
              ],
            ),
            
            const SizedBox(height: 20),
            _buildSectionHeader("MY FISHING"),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                _NavLargeTile(label: "Record Catch", sub: "Private Log", icon: Icons.add_circle, color: Colors.green, onTap: () {}),
                _NavLargeTile(label: "Logbook", sub: "History & Intel", icon: Icons.history, color: Colors.orange, onTap: () {}),
              ],
            ),

            const SizedBox(height: 20),
            _buildSectionHeader("VESSEL & SAFETY"),
            _NavLargeTile(
              label: "Safety Equipment", 
              sub: "Track Expiry Dates", 
              icon: Icons.shield, 
              color: const Color(0xFF004E92), 
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SafetyEquipmentScreen())).then((_) => _loadSafetyStatus()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetySummaryCard(int expired, int warning) {
    Color cardColor = Colors.green.shade600;
    String text = "All systems clear";
    IconData icon = Icons.check_circle;

    if (expired > 0) {
      cardColor = Colors.red.shade700;
      text = "$expired ITEMS EXPIRED";
      icon = Icons.error;
    } else if (warning > 0) {
      cardColor = Colors.orange.shade700;
      text = "$warning items expiring soon";
      icon = Icons.warning;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
        BoxShadow(
          color: cardColor.withValues(alpha: 0.3), // Updated to modern Flutter syntax
          blurRadius: 10, 
          offset: const Offset(0, 4)
        )
      ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("VESSEL READINESS", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                Text(text, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Align(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey))),
    );
  }
}

// --- HELPER UI WIDGETS ---

class _NavIconTile extends StatelessWidget {
  final String label; final IconData icon; final Color color; final VoidCallback onTap;
  const _NavIconTile({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color), const SizedBox(height: 5), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
      ),
    );
  }
}

class _NavLargeTile extends StatelessWidget {
  final String label, sub; final IconData icon; final Color color; final VoidCallback onTap;
  const _NavLargeTile({required this.label, required this.sub, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
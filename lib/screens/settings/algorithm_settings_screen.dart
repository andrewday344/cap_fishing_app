import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AlgorithmSettingsScreen extends StatefulWidget {
  const AlgorithmSettingsScreen({super.key});

  @override
  State<AlgorithmSettingsScreen> createState() => _AlgorithmSettingsScreenState();
}

class _AlgorithmSettingsScreenState extends State<AlgorithmSettingsScreen> {
  late Box _settingsBox;

  // Default Tolerances
  double _windTolerance = 5.0; // +/- knots
  double _swellTolerance = 0.3; // +/- meters
  bool _requireTideMatch = true; // Must be same tide phase (Incoming/Outgoing)
  double _minimumMatchScore = 80.0; // 0-100%

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('settings');
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _windTolerance = _settingsBox.get('alg_wind_tol', defaultValue: 5.0);
      _swellTolerance = _settingsBox.get('alg_swell_tol', defaultValue: 0.3);
      _requireTideMatch = _settingsBox.get('alg_tide_match', defaultValue: true);
      _minimumMatchScore = _settingsBox.get('alg_min_score', defaultValue: 80.0);
    });
  }

  Future<void> _saveSettings() async {
    await _settingsBox.put('alg_wind_tol', _windTolerance);
    await _settingsBox.put('alg_swell_tol', _swellTolerance);
    await _settingsBox.put('alg_tide_match', _requireTideMatch);
    await _settingsBox.put('alg_min_score', _minimumMatchScore);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Algorithm Tolerances Saved"), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Smart Match Settings"),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "CONDITIONS ARE PERFECT: ENGINE",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.1),
            ),
            const SizedBox(height: 10),
            const Text(
              "Define how strict the app should be when matching tomorrow's forecast against your successful past catches.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 30),

            _buildSectionCard(
              title: "Minimum Match Confidence",
              valueText: "${_minimumMatchScore.toInt()}%",
              child: Slider(
                value: _minimumMatchScore,
                min: 50,
                max: 100,
                divisions: 10,
                activeColor: Colors.blue,
                onChanged: (v) => setState(() => _minimumMatchScore = v),
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionCard(
              title: "Wind Speed Tolerance",
              valueText: "+/- ${_windTolerance.toStringAsFixed(1)} kts",
              child: Slider(
                value: _windTolerance,
                min: 0,
                max: 15,
                divisions: 30,
                activeColor: Colors.lightBlue,
                onChanged: (v) => setState(() => _windTolerance = v),
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionCard(
              title: "Swell Height Tolerance",
              valueText: "+/- ${_swellTolerance.toStringAsFixed(1)} m",
              child: Slider(
                value: _swellTolerance,
                min: 0.0,
                max: 1.5,
                divisions: 15,
                activeColor: Colors.cyan,
                onChanged: (v) => setState(() => _swellTolerance = v),
              ),
            ),
            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.black12)),
              child: SwitchListTile(
                title: const Text("Require Tide Phase Match", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text("Incoming must match Incoming", style: TextStyle(fontSize: 12)),
                value: _requireTideMatch,
                activeThumbColor: Colors.blue,
                onChanged: (v) => setState(() => _requireTideMatch = v),
              ),
            ),

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: const Color(0xFF004E92),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("SAVE ENGINE SETTINGS", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required String valueText, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.black12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(valueText, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
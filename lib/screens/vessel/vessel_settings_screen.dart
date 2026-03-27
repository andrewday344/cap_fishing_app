import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/vessel_profile.dart';

class VesselSettingsScreen extends StatefulWidget {
  const VesselSettingsScreen({super.key});

  @override
  State<VesselSettingsScreen> createState() => _VesselSettingsScreenState();
}

class _VesselSettingsScreenState extends State<VesselSettingsScreen> {
  late Box<VesselProfile> _vesselBox;
  double _currentLength = 4.8; // The SA legal threshold
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vesselBox = Hive.box<VesselProfile>('vessel_profile');
    
    // Load existing boat if it exists
    final existing = _vesselBox.get('my_boat');
    if (existing != null) {
      _currentLength = existing.length;
      _nameController.text = existing.name;
    }
  }

  void _saveProfile() {
    final profile = VesselProfile(
      name: _nameController.text.isEmpty ? "My Boat" : _nameController.text,
      length: _currentLength,
    );
    _vesselBox.put('my_boat', profile);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Vessel Profile Saved")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Vessel Profile", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("VESSEL NAME", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: "Enter boat name...",
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 30),
            Text("VESSEL LENGTH: ${_currentLength.toStringAsFixed(1)}m", 
                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: Slider(
                value: _currentLength,
                min: 2.0,
                max: 12.0,
                divisions: 100,
                activeColor: Colors.blue,
                label: "${_currentLength.toStringAsFixed(1)}m",
                onChanged: (val) => setState(() => _currentLength = val),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Note: Vessels under 4.8m in South Australia require lifejackets to be worn at all times.",
              style: TextStyle(color: Colors.blueGrey, fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("SAVE PROFILE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
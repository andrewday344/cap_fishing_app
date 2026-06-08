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
  
  final _nameController = TextEditingController();
  final _regoController = TextEditingController();
  final _hpController = TextEditingController();
  
  double _length = 4.8;
  double _windThreshold = 30.0;
  final double _swellThreshold = 0.5;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _vesselBox = Hive.box<VesselProfile>('vessel_profile');
  }

  Future<void> _saveVessel({int? index}) async {
    final String cleanName = _nameController.text.trim();
    final newVessel = VesselProfile(
      name: cleanName.isEmpty ? "Unnamed Boat" : cleanName,
      length: _length,
      registration: _regoController.text.trim(),
      engineHp: int.tryParse(_hpController.text.trim()) ?? 0,
      windIncreaseThreshold: _windThreshold,
      swellIncreaseThreshold: _swellThreshold,
      notificationsEnabled: _notificationsEnabled,
    );

    try {
      if (index != null) {
        await _vesselBox.putAt(index, newVessel);
      } else {
        await _vesselBox.add(newVessel);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vessel Saved"), backgroundColor: Colors.green));
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) Navigator.pop(context, true); 
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text("Fleet & Safety Settings"), elevation: 0),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16.0), child: Text("MY FLEET", style: Theme.of(context).textTheme.labelLarge))),
          ValueListenableBuilder(
            valueListenable: _vesselBox.listenable(),
            builder: (context, Box<VesselProfile> box, _) {
              if (box.isEmpty) return const SliverToBoxAdapter(child: Center(child: Text("No vessels added yet.")));
              return SliverList(delegate: SliverChildBuilderDelegate((context, index) {
                final boat = box.getAt(index);
                return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: ListTile(leading: const Icon(Icons.directions_boat, color: Colors.blue), title: Text(boat?.name ?? ""), subtitle: Text("${boat?.length.toStringAsFixed(1)}m | ${boat?.registration}"), trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => box.deleteAt(index))));
              }, childCount: box.length));
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 40),
                  const Text("ADD NEW VESSEL", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildTextField(_nameController, "Vessel Name"),
                  const SizedBox(height: 12),
                  Row(children: [Expanded(child: _buildTextField(_regoController, "Registration")), const SizedBox(width: 12), Expanded(child: _buildTextField(_hpController, "Engine HP", isNumber: true))]),
                  const SizedBox(height: 25),
                  Text("Vessel Length: ${_length.toStringAsFixed(1)}m"),
                  Slider(value: _length, min: 2, max: 12, divisions: 100, activeColor: Colors.blue, thumbColor: Colors.blue, onChanged: (v) => setState(() => _length = v)),
                  const SizedBox(height: 25),
                  _buildThresholdSlider(label: "Wind Increase Alert (%)", value: _windThreshold, min: 10, max: 100, onChanged: (v) => setState(() => _windThreshold = v)),
                  SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text("Sunrise/Sunset Warnings"), value: _notificationsEnabled, activeTrackColor: Colors.blue.withAlpha(100), activeThumbColor: Colors.blue, onChanged: (v) => setState(() => _notificationsEnabled = v)),
                  const SizedBox(height: 30),
                  ElevatedButton(onPressed: _saveVessel, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: const Color(0xFF004E92), foregroundColor: Colors.white), child: const Text("SAVE TO FLEET")),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) => TextField(controller: controller, keyboardType: isNumber ? TextInputType.number : TextInputType.text, decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))));
  Widget _buildThresholdSlider({required String label, required double value, required double min, required double max, required Function(double) onChanged}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("$label: ${value.toStringAsFixed(1)}"), Slider(value: value, min: min, max: max, activeColor: Colors.blueAccent, thumbColor: Colors.blueAccent, onChanged: onChanged)]);
}
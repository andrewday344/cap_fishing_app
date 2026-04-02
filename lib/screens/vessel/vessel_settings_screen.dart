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
  
  // Controllers for the "Add/Edit" form
  final _nameController = TextEditingController();
  final _regoController = TextEditingController();
  final _hpController = TextEditingController();
  
  double _length = 4.8;
  double _windThreshold = 30.0;
  double _swellThreshold = 0.5;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _vesselBox = Hive.box<VesselProfile>('vessel_profile');
  }

  void _saveVessel({int? index}) {
    final newVessel = VesselProfile(
      name: _nameController.text.isEmpty ? "Unnamed Boat" : _nameController.text,
      length: _length,
      registration: _regoController.text,
      engineHp: int.tryParse(_hpController.text) ?? 0,
      windIncreaseThreshold: _windThreshold,
      swellIncreaseThreshold: _swellThreshold,
      notificationsEnabled: _notificationsEnabled,
    );

    // Save to Hive
    if (index != null) {
      _vesselBox.putAt(index, newVessel);
    } else {
      _vesselBox.add(newVessel);
    }

    // FEEDBACK & AUTO-RETURN
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Vessel Added to Fleet"))
    );

    // THE FIX: Wait a tiny bit for Hive to finish writing, then go back
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) Navigator.pop(context); 
    });
  

    _clearForm();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fleet Updated")));
  }

  void _clearForm() {
    _nameController.clear();
    _regoController.clear();
    _hpController.clear();
    _length = 4.8;
    _windThreshold = 30.0;
    _swellThreshold = 0.5;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text("Fleet & Safety Settings")),
      body: CustomScrollView(
        slivers: [
          // 1. THE FLEET LIST
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("MY FLEET", style: Theme.of(context).textTheme.labelLarge),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: _vesselBox.listenable(),
            builder: (context, Box<VesselProfile> box, _) {
              if (box.isEmpty) {
                return const SliverToBoxAdapter(child: Center(child: Text("No vessels added yet.")));
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final boat = box.getAt(index);
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.directions_boat, color: Colors.blue),
                        title: Text(boat?.name ?? ""),
                        subtitle: Text("${boat?.length}m | ${boat?.registration}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => setState(() => box.deleteAt(index)),
                        ),
                      ),
                    );
                  },
                  childCount: box.length,
                ),
              );
            },
          ),

          // 2. ADD NEW VESSEL FORM
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 40),
                  const Text("ADD/EDIT VESSEL", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildTextField(_nameController, "Vessel Name"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_regoController, "Registration")),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(_hpController, "Engine HP", isNumber: true)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text("Vessel Length: ${_length.toStringAsFixed(1)}m"),
                  Slider(
                    value: _length,
                    min: 2, max: 12, divisions: 100,
                    onChanged: (v) => setState(() => _length = v),
                  ),
                  
                  const Divider(height: 40),
                  const Text("SAFETY THRESHOLDS (NOTIFICATIONS)", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  _buildThresholdSlider(
                    label: "Wind Increase Alert (%)",
                    value: _windThreshold,
                    min: 10, max: 100,
                    onChanged: (v) => setState(() => _windThreshold = v),
                  ),
                  _buildThresholdSlider(
                    label: "Swell Increase Alert (meters)",
                    value: _swellThreshold,
                    min: 0.1, max: 2.0,
                    onChanged: (v) => setState(() => _swellThreshold = v),
                  ),
                  
                  SwitchListTile(
                    title: const Text("Sunrise/Sunset Warnings"),
                    subtitle: const Text("Advise against launching in the dark"),
                    value: _notificationsEnabled,
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                  ),
                  
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _saveVessel(),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("SAVE TO FLEET"),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildThresholdSlider({required String label, required double value, required double min, required double max, required Function(double) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ${value.toStringAsFixed(1)}"),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import '../../models/checklist_item_model.dart';

class PreLaunchScreen extends StatefulWidget {
  const PreLaunchScreen({super.key});

  @override
  State<PreLaunchScreen> createState() => _PreLaunchScreenState();
}

class _PreLaunchScreenState extends State<PreLaunchScreen> {
  // Initial list of tasks specific to SA boaters
  final List<ChecklistItem> _items = [
    ChecklistItem(id: '1', task: "Bungs installed and tight", category: "VESSEL"),
    ChecklistItem(id: '2', task: "Battery switch ON", category: "VESSEL"),
    ChecklistItem(id: '3', task: "Fuel levels checked", category: "VESSEL"),
    ChecklistItem(id: '4', task: "VHF Radio / Sea Rescue Log-on", category: "SAFETY"),
    ChecklistItem(id: '5', task: "Flares & EPIRB accessible", category: "SAFETY"),
    ChecklistItem(id: '6', task: "Lifejackets ready", category: "SAFETY"),
    ChecklistItem(id: '7', task: "Trailer lights disconnected", category: "TRAILER"),
    ChecklistItem(id: '8', task: "Winch & Safety chain check", category: "TRAILER"),
  ];

  double get _progress => _items.where((i) => i.isCompleted).length / _items.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Pre-Launch Check", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                // FIXED: Using a standard for loop instead of .forEach
                for (var item in _items) {
                  item.isCompleted = false;
                }
              });
            },
            child: const Text("RESET"),
          )
        ],
      ),
      body: Column(
        children: [
          _buildProgressHeader(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _items[index];
                return _buildCheckTile(item);
              },
            ),
          ),
          _buildLaunchButton(),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Launch Readiness", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("${(_progress * 100).toInt()}%"),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey.shade200,
            color: _progress == 1.0 ? Colors.green : Colors.blue,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckTile(ChecklistItem item) {
    return GestureDetector(
      onTap: () => setState(() => item.isCompleted = !item.isCompleted),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.isCompleted ? Colors.green.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isCompleted ? Colors.green.withValues(alpha: 0.3) : Colors.black12,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              item.isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
              color: item.isCompleted ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.category, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade400)),
                  Text(item.task, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: item.isCompleted ? Colors.grey : Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaunchButton() {
    final bool isReady = _progress == 1.0;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: isReady ? () => Navigator.pop(context) : null,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 60),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(isReady ? "READY TO LAUNCH" : "COMPLETE ALL CHECKS", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
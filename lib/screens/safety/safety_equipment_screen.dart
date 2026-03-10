import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/safety_item_model.dart';
import '../../services/database_service.dart';

class SafetyEquipmentScreen extends StatefulWidget {
  const SafetyEquipmentScreen({super.key});

  @override
  State<SafetyEquipmentScreen> createState() => _SafetyEquipmentScreenState();
}

class _SafetyEquipmentScreenState extends State<SafetyEquipmentScreen> {
  List<SafetyItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await DatabaseService.instance.getAllSafetyItems();
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  void _showAddDialog({SafetyItem? existingItem}) {
    final nameController = TextEditingController(text: existingItem?.name);
    DateTime selectedDate = existingItem?.expiryDate ?? DateTime.now().add(const Duration(days: 365));
    String category = existingItem?.category ?? 'Flares';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingItem == null ? "Add Safety Gear" : "Edit Gear"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Item Name (e.g. Red Hand Flares)"),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  initialValue: category, // Use initialValue instead of value in newer Flutter versions
                  items: ['Flares', 'EPIRB', 'Fire Extinguisher', 'Lifejacket', 'Other']
                      .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => category = val!),
                  decoration: const InputDecoration(labelText: "Category"),
                ),
                const SizedBox(height: 20),
                ListTile(
                  title: const Text("Expiry Date"),
                  subtitle: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2040),
                    );
                    if (picked != null) setDialogState(() => selectedDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                
                final newItem = SafetyItem(
                  id: existingItem?.id ?? const Uuid().v4(),
                  name: nameController.text,
                  expiryDate: selectedDate,
                  category: category,
                );

                await DatabaseService.instance.saveSafetyItem(newItem);
                _loadItems();
               if (context.mounted) Navigator.pop(context); // Ensures the screen still exists before closing
              },
              child: const Text("SAVE GEAR"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Safety Equipment"),
        backgroundColor: const Color(0xFF004E92),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return _buildGearCard(item);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        label: const Text("ADD GEAR"),
        icon: const Icon(Icons.add_moderator),
        backgroundColor: const Color(0xFF004E92),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text("No gear tracked yet.", style: TextStyle(fontSize: 18, color: Colors.grey)),
          const Text("Add your flares or EPIRB to get started."),
        ],
      ),
    );
  }

  Widget _buildGearCard(SafetyItem item) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: item.statusColor.withValues(alpha: 0.5), width: 2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: item.statusColor.withValues(alpha: 0.1),
          child: Icon(Icons.security, color: item.statusColor),
        ),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Category: ${item.category}"),
            const SizedBox(height: 4),
            Text(
              item.daysUntilExpiry < 0 
                ? "EXPIRED" 
                : "Expires in ${item.daysUntilExpiry} days",
              style: TextStyle(color: item.statusColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          onSelected: (value) async {
            if (value == 'edit') {
              _showAddDialog(existingItem: item);
            } else if (value == 'delete') {
              await DatabaseService.instance.deleteSafetyItem(item.id);
              _loadItems();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text("Edit")),
            const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/vessel_log_model.dart';
import '../../services/database_service.dart';

class VesselLogScreen extends StatefulWidget {
  const VesselLogScreen({super.key});

  @override
  State<VesselLogScreen> createState() => _VesselLogScreenState();
}

class _VesselLogScreenState extends State<VesselLogScreen> {
  List<VesselLog> _logs = [];
  
  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await DatabaseService.instance.getAllVesselLogs();
    setState(() => _logs = logs);
  }

  double get _currentHours => _logs.isEmpty ? 0.0 : _logs.first.engineHours;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vessel Maintenance & Fuel")),
      body: Column(
        children: [
          _buildHoursHeader(),
          Expanded(
            child: _logs.isEmpty 
              ? const Center(child: Text("No logs yet. Start by adding engine hours."))
              : ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, i) => _buildLogTile(_logs[i]),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLogDialog(),
        label: const Text("ADD LOG", style: TextStyle(color: Colors.white, fontSize: 20)),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF004E92),
      ),
    );
  }

  Widget _buildHoursHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      color: const Color(0xFF004E92),
      child: Column(
        children: [
          const Text("TOTAL ENGINE HOURS", style: TextStyle(color: Colors.white70, fontSize: 12)),
          Text("${_currentHours.toStringAsFixed(1)} hrs", 
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLogTile(VesselLog log) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          log.isServiceRecord ? Icons.build : Icons.local_gas_station,
          color: log.isServiceRecord ? Colors.orange : Colors.blue,
        ),
        title: Text(log.isServiceRecord ? "Service Recorded" : "${log.fuelAdded}L Fuel Added"),
        subtitle: Text("${DateFormat('dd MMM yyyy').format(log.date)} • ${log.engineHours} hrs"),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  void _showAddLogDialog() {
    final hoursController = TextEditingController(text: _currentHours.toString());
    final fuelController = TextEditingController();
    bool isService = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Log Entry"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Current Engine Hours"),
              ),
              const SizedBox(height: 10),
              if (!isService) TextField(
                controller: fuelController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Fuel Added (Litres)"),
              ),
              SwitchListTile(
                title: const Text("Is this a Service?"),
                value: isService,
                onChanged: (val) => setDialogState(() => isService = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () async {
                final log = VesselLog(
                  id: const Uuid().v4(),
                  date: DateTime.now(),
                  engineHours: double.tryParse(hoursController.text) ?? _currentHours,
                  fuelAdded: double.tryParse(fuelController.text) ?? 0.0,
                  isServiceRecord: isService,
                );
                await DatabaseService.instance.saveVesselLog(log);
                _loadLogs();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("SAVE"),
            )
          ],
        ),
      ),
    );
  }
}
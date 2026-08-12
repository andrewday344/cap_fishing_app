import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:hive_flutter/hive_flutter.dart';

// IMPORTANT: Import your actual CatchLog model here when ready
// import '../models/catch_log_model.dart'; 

class CsvImportService {
  static Future<void> importCatchHistory(BuildContext context) async {
    try {
      // 1. Pick the CSV file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true, 
      );

      if (result == null || result.files.isEmpty) return; // User canceled the picker

      if (!context.mounted) return;

      // 2. Read the file data safely across platforms
      final PlatformFile file = result.files.first;
      String csvString = '';

      if (kIsWeb) {
        // Web requires reading directly from bytes
        if (file.bytes != null) {
          csvString = utf8.decode(file.bytes!);
        }
      } else {
        // Mobile/Desktop can read directly from the file path
        if (file.path != null) {
          csvString = await File(file.path!).readAsString();
        }
      }

      // --- LINTER FIX: Check mounted again because we just 'await'ed the file read above ---
      if (!context.mounted) return;

      if (csvString.isEmpty) throw Exception("File is empty or corrupted.");

      // 3. Parse the CSV
      List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);

      if (rows.length <= 1) {
         _showMessage(context, "File contains no valid catch data.", Colors.orange);
         return;
      }

      // 4. Process Rows (Skipping the Header row at index 0)
      int importedCount = 0;
      
      // Box catchBox = Hive.box('catches_v2'); 
      Map<dynamic, dynamic> batchData = {};

      for (int i = 1; i < rows.length; i++) {
        var row = rows[i];
        if (row.isEmpty || row.length < 5) continue; // Skip incomplete or empty rows

        try {
          /* 
          // UNCOMMENT AND MAP TO YOUR ACTUAL CATCHLOG MODEL
          final newCatch = CatchLog(
            id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
            date: DateTime.parse(row[0].toString()),
            location: row[1].toString(),
            species: row[2].toString(),
            windSpeed: double.tryParse(row[3].toString()) ?? 0.0,
            tidePhase: row[4].toString(),
          );
          
          batchData[newCatch.id] = newCatch;
          */
          
          importedCount++;
        } catch (e) {
          debugPrint("Skipped row $i due to parsing error: $e");
        }
      }

      // 5. Write all records to Hive in one massive commit
      if (batchData.isNotEmpty) {
        // await catchBox.putAll(batchData); 
      }

      if (context.mounted) {
        _showMessage(context, "✅ Successfully imported $importedCount catches!", Colors.green.shade700);
      }

    } catch (e) {
      debugPrint("Import failed: $e");
      if (context.mounted) {
        _showMessage(context, "Error importing file: $e", Colors.red);
      }
    }
  }

  static void _showMessage(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }
}
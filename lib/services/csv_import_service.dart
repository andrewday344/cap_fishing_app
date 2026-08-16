import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

// 👇 Import your models and database service 👇
import '../models/catch_model.dart';
import '../services/database_service.dart';

class CsvImportService {
  static Future<void> importCatchHistory(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return; // User canceled

      if (!context.mounted) return;

      final PlatformFile file = result.files.first;
      String csvString = '';

      if (kIsWeb) {
        if (file.bytes != null) {
          csvString = utf8.decode(file.bytes!);
        }
      } else {
        if (file.path != null) {
          csvString = await File(file.path!).readAsString();
        }
      }

      if (!context.mounted) return;

      if (csvString.isEmpty) throw Exception("File is empty or corrupted.");

      List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);
      
      if (rows.length <= 1) {
         _showMessage(context, "File contains no valid catch data.", Colors.orange);
         return;
      }

      int importedCount = 0;

      // Skip the Header row (index 0) and process the data
      for (int i = 1; i < rows.length; i++) {
        var row = rows[i];
        
        // We need at least a Date and a Species to make a valid log
        if (row.isEmpty || row.length < 2) continue; 

        try {
          // Safely map the CSV columns to your Catch model
          final newCatch = Catch(
            date: row[0].toString(),
            species: row[1].toString(),
            quantity: row.length > 2 ? (int.tryParse(row[2].toString()) ?? 1) : 1,
            notes: row.length > 3 ? row[3].toString() : "",
            temp: row.length > 4 ? (double.tryParse(row[4].toString()) ?? 0.0) : 0.0,
            wind: row.length > 5 ? (double.tryParse(row[5].toString()) ?? 0.0) : 0.0,
            tide: row.length > 6 ? row[6].toString() : "Unknown",
          );
          
          // Send it directly to your existing database service!
          await DatabaseService.instance.saveCatch(newCatch);
          importedCount++;
          
        } catch (e) {
          debugPrint("Skipped row $i due to parsing error: $e");
        }
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
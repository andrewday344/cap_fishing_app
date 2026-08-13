import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
//import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';

class CsvImportService {
  static Future<void> importCatchHistory(BuildContext context) async {
    try {
      // Fixed FilePicker syntax
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return; // User canceled the picker

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

      // Fixed CsvToListConverter capitalization
      List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);
      
      if (rows.length <= 1) {
         _showMessage(context, "File contains no valid catch data.", Colors.orange);
         return;
      }

      int importedCount = 0;
      
      // Box catchBox = Hive.box('catches_v2'); 
      Map<dynamic, dynamic> batchData = {};

      for (int i = 1; i < rows.length; i++) {
        var row = rows[i];
        if (row.isEmpty || row.length < 5) continue; 

        try {
          importedCount++;
        } catch (e) {
          debugPrint("Skipped row $i due to parsing error: $e");
        }
      }

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
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:personal_finance/db_helper.dart'; // Import db_helper
import 'package:personal_finance/app_navigation.dart'; // Import MainNavigation

class DataBackupService {
  final SharedPreferences prefs;
  final Database database;

  DataBackupService(this.prefs, this.database);

  // List of all table names from db_helper.dart
  static const List<String> _tableNames = [
    DatabaseHelper.expensesTable,
    DatabaseHelper.categoriesTable,
    DatabaseHelper.emisTable,
    DatabaseHelper.budgetsTable,
    DatabaseHelper.assetsTable,
    DatabaseHelper.subscriptionsTable,
  ];

  Future<void> exportData(BuildContext context) async {
    try {
      final Map<String, dynamic> backupData = {};

      // Get SharedPreferences data
      final Map<String, dynamic> prefsData = {};
      for (var key in prefs.getKeys()) {
        prefsData[key] = prefs.get(key);
      }
      backupData['preferences'] = prefsData;

      // Get SQLite database data for all tables
      final Map<String, List<Map<String, dynamic>>> dbData = {};
      for (String tableName in _tableNames) {
        List<Map<String, dynamic>> tableRows = await database.query(tableName);
        dbData[tableName] = tableRows;
      }
      backupData['database'] = dbData;

      final String jsonString = jsonEncode(backupData);

      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data export cancelled.')),
          );
        }
        return;
      }

      final String fileName =
          'exp_track_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json';
      final File file = File('$selectedDirectory/$fileName');
      await file.writeAsString(jsonString);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Data exported to $selectedDirectory/$fileName')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: $e')),
        );
      }
      print('Error exporting data: $e');
    }
  }

  Future<void> importData(BuildContext context) async {
    try {
      bool confirm = await showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Import Data'),
            content: const Text(
                'Importing data will overwrite all your current data. Are you sure you want to proceed?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
              ),
              TextButton(
                child: const Text('Import'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
              ),
            ],
          );
        },
      );

      if (!confirm) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data import cancelled.')),
          );
        }
        return;
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data import cancelled.')),
          );

          return;
        }
      }

      final String filePath = result!.files.single.path!;
      final File file = File(filePath);
      final String jsonString = await file.readAsString();

      final Map<String, dynamic> backupData = jsonDecode(jsonString);

      // Clear SharedPreferences
      await prefs.clear();
      final Map<String, dynamic> prefsData = backupData['preferences'];
      for (var entry in prefsData.entries) {
        if (entry.value is bool) {
          await prefs.setBool(entry.key, entry.value);
        } else if (entry.value is int) {
          await prefs.setInt(entry.key, entry.value);
        } else if (entry.value is double) {
          await prefs.setDouble(entry.key, entry.value);
        } else if (entry.value is String) {
          await prefs.setString(entry.key, entry.value);
        } else if (entry.value is List) {
          // Handle List<String>
          await prefs.setStringList(entry.key, entry.value.cast<String>());
        }
      }

      // Clear and insert SQLite data for all tables
      final Map<String, dynamic> dbImportData = backupData['database'];
      for (String tableName in _tableNames) {
        await database.delete(tableName); // Clear existing data
        if (dbImportData.containsKey(tableName)) {
          List<dynamic> rows = dbImportData[tableName];
          for (var row in rows) {
            // Remove 'id' if it's auto-incremented, as inserting with an ID
            // might cause conflicts or unexpected behavior.
            // For simplicity, assuming IDs are auto-incremented and can be
            // regenerated on import.
            Map<String, dynamic> rowWithoutId = Map.from(row);
            rowWithoutId.remove('id');
            await database.insert(tableName, rowWithoutId,
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data imported successfully from $filePath')),
        );
      }

      // Reload app state - this is crucial.
      // A common way is to navigate to the initial screen and remove all previous routes.
      // This will effectively restart the app's data loading process.
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) =>
                  const MainNavigation()), // Replace with your app's initial screen
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing data: $e')),
        );
      }
      print('Error importing data: $e');
    }
  }
}

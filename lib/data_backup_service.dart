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
    DatabaseHelper.incomeTable,
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
                'Importing data will merge with your current data. Existing entries will be updated, and new entries will be added. Are you sure you want to proceed?'),
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

      final Map<String, dynamic> prefsData = backupData['preferences'];
      for (var entry in prefsData.entries) {
        // Only update if the imported value is not null and not an empty string (for String types)
        if (entry.value != null && !(entry.value is String && (entry.value as String).isEmpty)) {
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
      }

      // Import SQLite data for all tables
      final Map<String, dynamic> dbImportData = backupData['database'];
      for (String tableName in _tableNames) {
        if (dbImportData.containsKey(tableName)) {
          // Get current table columns to handle schema changes
          final List<Map<String, dynamic>> tableInfo =
              await database.rawQuery('PRAGMA table_info($tableName)');
          final List<String> columnNames =
              tableInfo.map((e) => e['name'] as String).toList();

          List<dynamic> rows = dbImportData[tableName];
          for (var row in rows) {
            Map<String, dynamic> importedRow = Map.from(row);

            // Filter out columns not present in the current table schema
            importedRow.removeWhere((key, value) => !columnNames.contains(key));

            if (importedRow.containsKey('id') && importedRow['id'] != null) {
              final int id = importedRow['id'];
              // Check if record with this ID already exists
              final List<Map<String, dynamic>> existingRecords =
                  await database.query(
                tableName,
                where: 'id = ?',
                whereArgs: [id],
              );

              if (existingRecords.isNotEmpty) {
                // Merge existing data with imported data
                Map<String, dynamic> existingRecord = existingRecords.first;
                Map<String, dynamic> mergedData = Map.from(existingRecord);

                importedRow.forEach((key, value) {
                  // Only update if the imported value is not null and not empty (for String)
                  if (value != null && !(value is String && value.isEmpty)) {
                    mergedData[key] = value;
                  }
                });
                await database.update(
                  tableName,
                  mergedData,
                  where: 'id = ?',
                  whereArgs: [id],
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              } else {
                // If ID exists in imported data but not in current DB, insert it
                await database.insert(tableName, importedRow,
                    conflictAlgorithm: ConflictAlgorithm.replace);
              }
            } else {
              // If no 'id' in imported row, it's a new record, insert it
              // Remove 'id' key if it exists but is null, to let DB auto-assign
              importedRow.remove('id');
              await database.insert(tableName, importedRow,
                  conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data imported successfully from $filePath')),
        );

        final shouldRestart = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Import Complete'),
            content: const Text(
                'Data has been imported successfully. Please restart the application for changes to take full effect.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Later'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Restart Now'),
              ),
            ],
          ),
        );

        if (shouldRestart == true) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainNavigation()),
            (Route<dynamic> route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Import successful. Restart when ready.')),
          );
        }
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

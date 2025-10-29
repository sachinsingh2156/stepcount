import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stepcounter/services/database_helper.dart';

class ExportService {
  static final ExportService instance = ExportService._init();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  ExportService._init();

  /// Export all step data to CSV format
  Future<String?> exportToCSV() async {
    try {
      // Get all daily step data
      final allData = await _databaseHelper.getAllDailyData();

      if (allData.isEmpty) {
        return null; // No data to export
      }

      // Create CSV data
      final csvRows = <List<dynamic>>[
        // Header row
        [
          'Date',
          'Steps',
          'Distance (km)',
          'Calories',
          'Activity Time (minutes)',
        ],
      ];

      // Add data rows
      for (final data in allData) {
        csvRows.add([
          _formatDate(data.date),
          data.steps,
          data.distance.toStringAsFixed(2),
          data.calories.toStringAsFixed(2),
          data.activityTime.toStringAsFixed(2),
        ]);
      }

      // Convert to CSV string
      final csvString = const ListToCsvConverter().convert(csvRows);

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'step_counter_export_$timestamp.csv';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      // Write CSV to file
      await file.writeAsString(csvString);

      return filePath;
    } catch (e) {
      print('Error exporting to CSV: $e');
      return null;
    }
  }

  /// Export data and share it
  Future<bool> exportAndShareCSV() async {
    try {
      final filePath = await exportToCSV();

      if (filePath == null) {
        return false; // No data to export
      }

      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Step Counter Data Export',
        text: 'Step Counter Data Export - ${DateTime.now().toString().split(' ')[0]}',
      );

      return true;
    } catch (e) {
      print('Error sharing CSV: $e');
      return false;
    }
  }

  /// Export data to a specific directory (for saving directly)
  Future<String?> exportToCSVFile(String fileName) async {
    try {
      final csvFilePath = await exportToCSV();
      if (csvFilePath == null) {
        return null;
      }

      final sourceFile = File(csvFilePath);
      
      // Get downloads or documents directory
      Directory? targetDirectory;
      if (Platform.isAndroid) {
        // On Android, use external storage Downloads directory
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // Navigate to Downloads folder
          targetDirectory = Directory('${externalDir.path.replaceAll('/Android/data/com.example.stepcounter/files', '')}/Download');
        } else {
          targetDirectory = await getApplicationDocumentsDirectory();
        }
      } else {
        targetDirectory = await getApplicationDocumentsDirectory();
      }

      if (!await targetDirectory.exists()) {
        await targetDirectory.create(recursive: true);
      }

      final targetPath = '${targetDirectory.path}/$fileName';
      
      // Copy file to target location
      await sourceFile.copy(targetPath);
      
      return targetPath;
    } catch (e) {
      print('Error exporting to file: $e');
      return null;
    }
  }

  /// Format date for CSV
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get summary statistics for export
  Future<Map<String, dynamic>> getExportSummary() async {
    final allData = await _databaseHelper.getAllDailyData();
    
    if (allData.isEmpty) {
      return {
        'totalDays': 0,
        'totalSteps': 0,
        'totalDistance': 0.0,
        'totalCalories': 0.0,
      };
    }

    final totalSteps = allData.fold<int>(0, (sum, d) => sum + d.steps);
    final totalDistance = allData.fold<double>(0.0, (sum, d) => sum + d.distance);
    final totalCalories = allData.fold<double>(0.0, (sum, d) => sum + d.calories);

    return {
      'totalDays': allData.length,
      'totalSteps': totalSteps,
      'totalDistance': totalDistance,
      'totalCalories': totalCalories,
      'averageSteps': totalSteps / allData.length,
      'averageDistance': totalDistance / allData.length,
      'averageCalories': totalCalories / allData.length,
    };
  }
}


import 'package:flutter/material.dart';
import '../models/step_data.dart';
import '../services/settings_manager.dart';
import '../services/step_counter_service.dart';
import '../services/export_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsManager _settingsManager = SettingsManager.instance;
  final StepCounterService _service = StepCounterService.instance;
  final ExportService _exportService = ExportService.instance;
  
  bool _isExporting = false;
  
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _strideController = TextEditingController();
  final TextEditingController _thresholdController = TextEditingController();
  
  UserSettings _currentSettings = UserSettings();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsManager.loadSettings();
    setState(() {
      _currentSettings = settings;
      _heightController.text = settings.height.toStringAsFixed(1);
      _weightController.text = settings.weight.toStringAsFixed(1);
      _strideController.text = settings.strideLength?.toStringAsFixed(1) ?? '';
      _thresholdController.text = settings.stepThreshold.toStringAsFixed(1);
    });
  }

  Future<void> _saveSettings() async {
    final newSettings = UserSettings(
      height: double.tryParse(_heightController.text) ?? 170.0,
      weight: double.tryParse(_weightController.text) ?? 70.0,
      strideLength: double.tryParse(_strideController.text),
      stepThreshold: double.tryParse(_thresholdController.text) ?? 9.0,
      smoothingFactor: _currentSettings.smoothingFactor,
    );

    await _service.updateSettings(newSettings);
    await _settingsManager.saveSettings(newSettings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved!')),
      );
    }
  }

  void _autoCalculateStride() {
    final height = double.tryParse(_heightController.text) ?? 170.0;
    final stride = height * 0.415; // 41.5% of height
    setState(() {
      _strideController.text = stride.toStringAsFixed(1);
    });
  }

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Show summary dialog first
      final summary = await _exportService.getExportSummary();
      
      if (summary['totalDays'] == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No data to export. Start walking to collect data!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Confirm export
      final shouldExport = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Days: ${summary['totalDays']}'),
              Text('Total Steps: ${summary['totalSteps']}'),
              Text('Total Distance: ${summary['totalDistance'].toStringAsFixed(2)} km'),
              Text('Total Calories: ${summary['totalCalories'].toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              const Text(
                'Export all step data to CSV file?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Export'),
            ),
          ],
        ),
      );

      if (shouldExport == true) {
        final success = await _exportService.exportAndShareCSV();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Data exported successfully! Check your sharing options.'
                    : 'Export failed. Please try again.',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Height
          TextField(
            controller: _heightController,
            decoration: const InputDecoration(
              labelText: 'Height (cm)',
              hintText: 'Enter your height',
              prefixIcon: Icon(Icons.height),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // Weight
          TextField(
            controller: _weightController,
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              hintText: 'Enter your weight',
              prefixIcon: Icon(Icons.monitor_weight),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => _autoCalculateStride(),
          ),
          const SizedBox(height: 16),

          // Stride Length
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _strideController,
                  decoration: const InputDecoration(
                    labelText: 'Stride Length (cm)',
                    hintText: 'Auto-calculated',
                    prefixIcon: Icon(Icons.straighten),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _autoCalculateStride,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Auto'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Current stride: ${_currentSettings.strideLengthInMeters * 100} cm (${_currentSettings.strideLengthInMeters} m)',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),

          // Step Threshold
          TextField(
            controller: _thresholdController,
            decoration: const InputDecoration(
              labelText: 'Step Detection Threshold',
              hintText: '9.0 (m/s²)',
              prefixIcon: Icon(Icons.tune),
              border: OutlineInputBorder(),
              helperText: 'Lower values = more sensitive detection',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 32),

          // Info Card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About These Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Height and weight are used to calculate stride length and estimate calories burned.',
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• You can override stride length manually or use the auto-calculate feature.',
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• Step detection threshold affects sensitivity. Lower values detect more steps but may include false positives.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Export Data Section
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.file_download, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Export Data',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Export all your step counter data to CSV format. You can share it via email, cloud storage, or save it on your device.',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isExporting ? null : _exportData,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.file_download),
                      label: Text(_isExporting ? 'Exporting...' : 'Export to CSV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _strideController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }
}


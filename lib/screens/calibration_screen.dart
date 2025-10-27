import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/step_detector.dart';
import '../services/settings_manager.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  final StepDetector _stepDetector = StepDetector();
  final SettingsManager _settingsManager = SettingsManager.instance;
  
  StreamSubscription<AccelerometerEvent>? _subscription;
  
  int _detectedSteps = 0;
  bool _isCalibrating = false;

  @override
  void dispose() {
    _subscription?.cancel();
    _stepDetector.reset();
    super.dispose();
  }

  void _startCalibration() {
    setState(() {
      _isCalibrating = true;
      _detectedSteps = 0;
      _stepDetector.reset();
    });

    _subscription?.cancel();
    _subscription = accelerometerEventStream().listen((event) {
      if (_stepDetector.processAccelerometerData(event.x, event.y, event.z)) {
        setState(() {
          _detectedSteps++;
        });

        if (_detectedSteps >= 10) {
          _completeCalibration();
        }
      }
    });
  }

  void _stopCalibration() {
    _subscription?.cancel();
    setState(() {
      _isCalibrating = false;
    });
  }

  Future<void> _completeCalibration() async {
    _stopCalibration();
    
    // Calculate stride length (assuming user walked 10 steps)
    final distance = 10.0; // Distance in meters (user walked)
    final calculatedStride = (distance / _detectedSteps) * 100; // in cm

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Calibration Complete!'),
          content: Text(
            'Detected $_detectedSteps steps.\n\n'
            'Calculated stride length: ${calculatedStride.toStringAsFixed(1)} cm',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _saveCalibration(calculatedStride),
              child: const Text('Save'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _saveCalibration(double strideLength) async {
    final settings = await _settingsManager.loadSettings();
    final newSettings = settings.copyWith(strideLength: strideLength);
    
    await _settingsManager.saveSettings(newSettings);
    
    if (mounted) {
      Navigator.of(context).pop(); // Close dialog
      Navigator.of(context).pop(); // Go back to home
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calibration saved!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calibration'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              const Icon(
                Icons.fit_screen,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 32),
              const Text(
                'Walk 10 Steps',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Place your phone in your pocket and walk naturally for 10 steps.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              
              // Step Counter
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Colors.blue,
                    width: 4,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_detectedSteps',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Text(
                        'steps',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              
              // Instructions
              if (!_isCalibrating)
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Instructions:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('1. Hold phone in your hand or place in pocket'),
                        Text('2. Press Start'),
                        Text('3. Walk naturally for 10 steps'),
                        Text('4. The app will calculate your stride length'),
                      ],
                    ),
                  ),
                ),
              
              if (_isCalibrating)
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Walk now...'),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 32),
              
              // Action Button
              if (!_isCalibrating)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startCalibration,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Calibration'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _stopCalibration,
                    icon: const Icon(Icons.stop),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}


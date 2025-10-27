import 'dart:math' as math;
import '../models/step_data.dart';

/// Step detection algorithm using accelerometer data
class StepDetector {
  // Configuration parameters
  final double stepThreshold;
  final double smoothingFactor;
  final int minStepInterval; // minimum milliseconds between steps
  final int windowSize;

  // State variables
  double _previousMagnitude = 0.0;
  double _smoothedMagnitude = 0.0;
  DateTime _lastStepTime = DateTime.now();
  bool _wasAscending = false;
  
  // Peak detection
  double _lastPeak = 0.0;
  double _baseline = 9.81; // Normal gravity baseline
  
  // Acceleration history for chart
  final List<double> _accelerationHistory = [];
  final int _maxHistoryLength = 100;

  StepDetector({
    this.stepThreshold = 9.0,
    this.smoothingFactor = 0.8,
    this.minStepInterval = 300, // 300ms
    this.windowSize = 5,
  });

  /// Process accelerometer data and detect steps
  bool processAccelerometerData(double x, double y, double z) {
    final now = DateTime.now();
    
    // Calculate magnitude
    final magnitude = math.sqrt(x * x + y * y + z * z);
    
    // Add to history for chart
    _accelerationHistory.add(magnitude);
    if (_accelerationHistory.length > _maxHistoryLength) {
      _accelerationHistory.removeAt(0);
    }
    
    // Apply low-pass filter
    _smoothedMagnitude = smoothingFactor * _smoothedMagnitude + 
                         (1 - smoothingFactor) * magnitude;
    
    // Update baseline (running average for stationary detection)
    _baseline = 0.99 * _baseline + 0.01 * _smoothedMagnitude;
    
    final bool stepDetected = _detectStep(_smoothedMagnitude, now);
    _previousMagnitude = _smoothedMagnitude;
    
    return stepDetected;
  }

  /// Peak-based step detection algorithm
  bool _detectStep(double magnitude, DateTime now) {
    // Check minimum step interval
    final timeSinceLastStep = now.difference(_lastStepTime).inMilliseconds;
    if (timeSinceLastStep < minStepInterval) {
      return false;
    }

    // Check if device is actually moving (not just sensor noise)
    if (!_isDeviceMoving()) {
      return false;
    }

    // Track if we were ascending
    if (_previousMagnitude < magnitude) {
      _wasAscending = true;
    } else if (_previousMagnitude > magnitude && _wasAscending) {
      // We found a peak
      _lastPeak = _previousMagnitude;
      _wasAscending = false;
    }

    // For a valid step, we need:
    // 1. A significant peak above the threshold
    // 2. The magnitude to come back down after the peak
    // 3. The descent to cross below a valley threshold
    if (!_wasAscending && magnitude < _previousMagnitude) {
      // We're descending after a peak
      if (_lastPeak > stepThreshold && magnitude < (stepThreshold - 1.0)) {
        // Valid step: peaked above threshold AND descended below (threshold - 1.0)
        _lastStepTime = now;
        _lastPeak = 0.0;
        _wasAscending = false;
        return true;
      }
    }

    return false;
  }

  /// Check if device is actually moving (not stationary)
  bool _isDeviceMoving() {
    if (_accelerationHistory.length < 20) {
      return false;
    }

    // Get recent acceleration values
    final recent = _accelerationHistory.length > 30
        ? _accelerationHistory.sublist(_accelerationHistory.length - 30)
        : _accelerationHistory;

    // Calculate variance to detect movement
    final mean = recent.reduce((a, b) => a + b) / recent.length;
    final variance = recent.map((v) => math.pow(v - mean, 2))
                        .reduce((a, b) => a + b) / recent.length;
    final stdDev = math.sqrt(variance);

    // Device is considered moving if std deviation > 0.5 m/s²
    // This filters out stationary sensor noise
    return stdDev > 0.5;
  }

  /// Classify motion state based on acceleration patterns
  MotionState classifyMotion() {
    if (_accelerationHistory.length < 10) {
      return MotionState.idle;
    }

    // Calculate statistics from recent acceleration
    final recent = _accelerationHistory.length > 30 
        ? _accelerationHistory.sublist(_accelerationHistory.length - 30)
        : _accelerationHistory;
    
    final mean = recent.reduce((a, b) => a + b) / recent.length;
    final variance = recent.map((v) => (v - mean) * (v - mean))
                        .reduce((a, b) => a + b) / recent.length;
    final stdDev = math.sqrt(variance);

    // Simple classification rules
    if (mean < 9.5) {
      return MotionState.idle;
    } else if (stdDev < 2.0 && mean > 10.5 && mean < 15.0) {
      return MotionState.walking;
    } else if (stdDev > 2.5 && mean > 15.0) {
      return MotionState.running;
    } else {
      return MotionState.walking;
    }
  }

  /// Get current acceleration history for chart
  List<double> get accelerationHistory => List.unmodifiable(_accelerationHistory);

  /// Reset the detector state
  void reset() {
    _previousMagnitude = 0.0;
    _smoothedMagnitude = 0.0;
    _lastStepTime = DateTime.now();
    _wasAscending = false;
    _lastPeak = 0.0;
    _baseline = 9.81;
    _accelerationHistory.clear();
  }

  /// Update configuration
  void updateConfig({
    double? stepThreshold,
    double? smoothingFactor,
    int? minStepInterval,
  }) {
    // Note: Dart doesn't support updating final fields after construction
    // This is a limitation. In a production app, you'd recreate the detector.
  }
}


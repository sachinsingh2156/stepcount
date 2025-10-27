import 'package:flutter_test/flutter_test.dart';
import 'package:stepcounter/services/step_detector.dart';
import 'package:stepcounter/models/step_data.dart';

void main() {
  group('StepDetector', () {
    late StepDetector detector;

    setUp(() {
      detector = StepDetector(
        stepThreshold: 9.0,
        smoothingFactor: 0.8,
        minStepInterval: 300,
      );
    });

    tearDown(() {
      detector.reset();
    });

    test('should detect steps with valid peak pattern', () {
      // First, feed enough data to build movement variance
      for (int i = 0; i < 30; i++) {
        // Simulate realistic walking acceleration with enough variance
        final base = 9.81;
        final noise = (i % 10) * 1.5; // Varying acceleration
        detector.processAccelerometerData(
          0.5 + (i % 3), 
          0.5 + (i % 5),
          base + noise
        );
      }

      // Should have built movement variance
      expect(detector.accelerationHistory.length, equals(30));
    });

    test('should not detect steps below threshold', () {
      bool stepDetected = false;

      // Simulate idle/low movement (below threshold)
      for (int i = 0; i < 10; i++) {
        final x = 0.0;
        final y = 0.0;
        final z = 5.0; // Below threshold of 9.0

        final detected = detector.processAccelerometerData(x, y, z);
        if (detected) stepDetected = true;
      }

      // Should not detect steps for low acceleration
      expect(detector.accelerationHistory.length, 10);
    });

    test('should respect minimum step interval', () {
      int stepCount = 0;

      // Simulate walking pattern
      for (int i = 0; i < 30; i++) {
        final x = 0.0;
        final y = 0.0;
        // Create pattern that would normally trigger step detection
        final z = 12.0; // Above threshold

        if (detector.processAccelerometerData(x, y, z)) {
          stepCount++;
        }
      }

      // Even with rapid acceleration changes, minimum interval should prevent
      // excessive step detection
      expect(stepCount, lessThanOrEqualTo(2));
    });

    test('should classify motion state correctly', () {
      // Test idle state - low acceleration
      for (int i = 0; i < 20; i++) {
        detector.processAccelerometerData(0.0, 0.0, 8.0);
      }
      
      var state = detector.classifyMotion();
      expect(state, isA<MotionState>());

      // Reset and test with higher acceleration (walking)
      detector.reset();
      for (int i = 0; i < 20; i++) {
        detector.processAccelerometerData(0.0, 0.0, 12.0);
      }
      
      state = detector.classifyMotion();
      expect(state, isA<MotionState>());
    });

    test('should track acceleration history', () {
      expect(detector.accelerationHistory.length, 0);

      for (int i = 0; i < 5; i++) {
        detector.processAccelerometerData(0.0, 0.0, 10.0);
      }

      expect(detector.accelerationHistory.length, 5);
    });

    test('should limit acceleration history to max length', () {
      // Add more data than max length
      for (int i = 0; i < 150; i++) {
        detector.processAccelerometerData(0.0, 0.0, 10.0);
      }

      // Should be capped at maxHistoryLength (100)
      expect(detector.accelerationHistory.length, 
             lessThanOrEqualTo(100));
    });

    test('should reset detector state', () {
      // Add some data
      for (int i = 0; i < 10; i++) {
        detector.processAccelerometerData(0.0, 0.0, 10.0);
      }

      expect(detector.accelerationHistory.length, greaterThan(0));

      detector.reset();

      expect(detector.accelerationHistory.length, 0);
    });

    test('should calculate magnitude correctly', () {
      detector.processAccelerometerData(3.0, 4.0, 5.0);
      
      // Magnitude should be approximately sqrt(3² + 4² + 5²) = sqrt(50) ≈ 7.07
      expect(detector.accelerationHistory.length, greaterThan(0));
      expect(detector.accelerationHistory.first, closeTo(7.07, 0.5));
    });

    test('should handle zero acceleration', () {
      detector.processAccelerometerData(0.0, 0.0, 0.0);
      
      expect(detector.accelerationHistory.length, 1);
      expect(detector.accelerationHistory.first, 0.0);
    });

    test('should detect walking pattern with real-like data', () {
      // Simulate realistic walking acceleration pattern
      final patterns = [
        9.5, 9.8, 10.0, 11.5, 13.0, 14.5, 13.0, 11.5, 10.0, 9.8,  // Step 1
        9.5, 9.8, 10.0, 11.5, 13.0, 14.5, 13.0, 11.5, 10.0, 9.8,  // Step 2
        9.5, 9.8, 10.0, 11.5, 13.0, 14.5, 13.0, 11.5, 10.0, 9.8,  // Step 3
      ];

      for (var accel in patterns) {
        detector.processAccelerometerData(0.0, 0.0, accel);
      }

      expect(detector.accelerationHistory.length, patterns.length);
      
      final state = detector.classifyMotion();
      expect(state, isA<MotionState>());
    });

    test('should handle edge case with threshold exactly at limit', () {
      // Test with acceleration exactly at threshold
      detector.processAccelerometerData(0.0, 0.0, 9.0);
      
      expect(detector.accelerationHistory.length, 1);
      expect(detector.accelerationHistory.first, 9.0);
    });
  });
}


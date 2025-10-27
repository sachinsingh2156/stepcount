import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/step_data.dart';
import 'step_detector.dart';
import 'database_helper.dart';
import 'settings_manager.dart';

class StepCounterService {
  static final StepCounterService instance = StepCounterService._init();
  StepCounterService._init();

  // Core components
  final StepDetector _stepDetector = StepDetector();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final SettingsManager _settingsManager = SettingsManager.instance;

  // Stream subscriptions
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  Timer? _periodicSaveTimer;

  // Current state
  int _currentSteps = 0;
  UserSettings _settings = UserSettings();
  MotionState _motionState = MotionState.idle;
  
  // State update callbacks
  Function(int steps)? onStepsUpdated;
  Function(MotionState state)? onMotionStateUpdated;
  Function(List<double> acceleration)? onAccelerationUpdated;

  DateTime _sessionStartTime = DateTime.now();
  String _currentDate = DateTime.now().toIso8601String().split('T')[0];

  bool _isRunning = false;

  // Getters
  bool get isRunning => _isRunning;
  int get currentSteps => _currentSteps;
  MotionState get motionState => _motionState;
  UserSettings get settings => _settings;

  /// Initialize and load settings
  Future<void> initialize() async {
    await _settingsManager.init();
    _settings = await _settingsManager.loadSettings();
    
    // Create new detector with user settings
    // Update config would be implemented here
    
    await _loadTodayData();
    _startPeriodicSave();
  }

  /// Start listening to sensors and detecting steps
  Future<void> start() async {
    if (_isRunning) return;
    
    _isRunning = true;
    _sessionStartTime = DateTime.now();
    _checkDateChanged();

    _accelerometerSubscription = accelerometerEventStream().listen(
      _handleAccelerometerEvent,
      onError: (error) {
        print('Accelerometer error: $error');
      },
    );
  }

  /// Stop listening to sensors
  void stop() {
    _isRunning = false;
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _periodicSaveTimer?.cancel();
  }

  /// Handle accelerometer data
  void _handleAccelerometerEvent(AccelerometerEvent event) {
    final stepDetected = _stepDetector.processAccelerometerData(
      event.x,
      event.y,
      event.z,
    );

    if (stepDetected) {
      _currentSteps++;
      onStepsUpdated?.call(_currentSteps);
      _saveToMemory(); // Cache for batch save
    }

    // Update motion state
    final newState = _stepDetector.classifyMotion();
    if (newState != _motionState) {
      _motionState = newState;
      onMotionStateUpdated?.call(_motionState);
    }

    // Update acceleration for chart
    final history = _stepDetector.accelerationHistory;
    if (history.isNotEmpty) {
      onAccelerationUpdated?.call(List.from(history));
    }
  }

  /// Start periodic save to database
  void _startPeriodicSave() {
    _periodicSaveTimer?.cancel();
    _periodicSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _saveToDatabase();
    });
  }

  /// Save current data to database
  Future<void> _saveToDatabase() async {
    if (_currentSteps == 0) return;

    try {
      final todayData = await _databaseHelper.getTodayData();
      
      final updatedData = (todayData != null)
          ? todayData.copyWith(
              steps: (todayData.steps + _currentSteps),
              distance: _calculateDistance(todayData.steps + _currentSteps),
              calories: _calculateCalories(todayData.steps + _currentSteps),
              activityTime: _calculateActivityTime(),
            )
          : DailyStepData(
              id: 0,
              date: DateTime.now(),
              steps: _currentSteps,
              distance: _calculateDistance(_currentSteps),
              calories: _calculateCalories(_currentSteps),
              activityTime: _calculateActivityTime(),
            );

      await _databaseHelper.insertOrUpdateDailySteps(updatedData);
    } catch (e) {
      print('Error saving to database: $e');
    }
  }

  /// Save to memory cache (for quick access)
  void _saveToMemory() {
    // In-memory updates are already handled
  }

  /// Load today's data from database
  Future<void> _loadTodayData() async {
    try {
      final todayData = await _databaseHelper.getTodayData();
      if (todayData != null) {
        _currentSteps = todayData.steps;
        onStepsUpdated?.call(_currentSteps);
      } else {
        _currentSteps = 0;
      }
    } catch (e) {
      print('Error loading today data: $e');
      _currentSteps = 0;
    }
  }

  /// Check if date has changed
  void _checkDateChanged() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (today != _currentDate) {
      // Reset for new day
      _currentDate = today;
      _resetForNewDay();
    }
  }

  /// Reset counters for a new day
  void _resetForNewDay() {
    _currentSteps = 0;
    onStepsUpdated?.call(0);
  }

  /// Calculate distance in km
  double _calculateDistance(int steps) {
    return steps * _settings.strideLengthInMeters / 1000;
  }

  /// Calculate calories burned
  double _calculateCalories(int steps) {
    // Simple calorie estimation: ~0.04 calories per step
    return steps * 0.04;
  }

  /// Calculate activity time in minutes
  double _calculateActivityTime() {
    if (_currentSteps == 0) return 0.0;
    
    final duration = DateTime.now().difference(_sessionStartTime);
    return duration.inSeconds / 60.0;
  }

  /// Reset current steps
  void resetSteps() {
    _currentSteps = 0;
    _stepDetector.reset();
    _sessionStartTime = DateTime.now();
    onStepsUpdated?.call(0);
  }

  /// Update settings
  Future<void> updateSettings(UserSettings newSettings) async {
    _settings = newSettings;
    await _settingsManager.saveSettings(newSettings);
    
    // Note: Detector config can't be updated dynamically
    // Would need to recreate the detector
  }

  /// Get today's stats
  Future<Map<String, dynamic>> getTodayStats() async {
    final todayData = await _databaseHelper.getTodayData();
    
    return {
      'steps': todayData?.steps ?? _currentSteps,
      'distance': todayData?.distance ?? _calculateDistance(_currentSteps),
      'calories': todayData?.calories ?? _calculateCalories(_currentSteps),
      'motionState': _motionState,
    };
  }

  /// Dispose resources
  void dispose() {
    stop();
    _periodicSaveTimer?.cancel();
    _databaseHelper.close();
  }
}


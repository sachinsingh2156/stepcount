/// Models for step counter data
class DailyStepData {
  final int id;
  final DateTime date;
  final int steps;
  final double distance; // in km
  final double calories;
  final double activityTime; // in minutes

  DailyStepData({
    required this.id,
    required this.date,
    required this.steps,
    required this.distance,
    required this.calories,
    required this.activityTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'steps': steps,
      'distance': distance,
      'calories': calories,
      'activityTime': activityTime,
    };
  }

  factory DailyStepData.fromMap(Map<String, dynamic> map) {
    return DailyStepData(
      id: map['id'] as int,
      date: DateTime.parse(map['date'] as String),
      steps: map['steps'] as int,
      distance: map['distance'] as double,
      calories: map['calories'] as double,
      activityTime: map['activityTime'] as double,
    );
  }

  DailyStepData copyWith({
    int? id,
    DateTime? date,
    int? steps,
    double? distance,
    double? calories,
    double? activityTime,
  }) {
    return DailyStepData(
      id: id ?? this.id,
      date: date ?? this.date,
      steps: steps ?? this.steps,
      distance: distance ?? this.distance,
      calories: calories ?? this.calories,
      activityTime: activityTime ?? this.activityTime,
    );
  }
}

/// Motion state classification
enum MotionState {
  idle,
  walking,
  running,
}

/// User settings
class UserSettings {
  final double height; // in cm
  final double weight; // in kg
  final double? strideLength; // in cm (null for auto-calculated)
  final double stepThreshold;
  final double smoothingFactor;

  UserSettings({
    this.height = 170.0,
    this.weight = 70.0,
    this.strideLength,
    this.stepThreshold = 9.0, // m/s²
    this.smoothingFactor = 0.8,
  });

  double get strideLengthInMeters {
    if (strideLength != null) {
      return strideLength! / 100;
    }
    // Auto-calculate based on height (approximate formula)
    return height * 0.415 / 100; // 41.5% of height in meters
  }

  Map<String, dynamic> toMap() {
    return {
      'height': height,
      'weight': weight,
      'strideLength': strideLength,
      'stepThreshold': stepThreshold,
      'smoothingFactor': smoothingFactor,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      height: map['height'] as double,
      weight: map['weight'] as double,
      strideLength: map['strideLength'] as double?,
      stepThreshold: map['stepThreshold'] as double,
      smoothingFactor: map['smoothingFactor'] as double,
    );
  }

  UserSettings copyWith({
    double? height,
    double? weight,
    double? strideLength,
    double? stepThreshold,
    double? smoothingFactor,
  }) {
    return UserSettings(
      height: height ?? this.height,
      weight: weight ?? this.weight,
      strideLength: strideLength ?? this.strideLength,
      stepThreshold: stepThreshold ?? this.stepThreshold,
      smoothingFactor: smoothingFactor ?? this.smoothingFactor,
    );
  }
}


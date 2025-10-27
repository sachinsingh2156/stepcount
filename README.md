# Smart Step Counter (Pedometer)

A modern Flutter mobile application for Android that provides real-time step detection using accelerometer data processing and motion classification.

## Features

- **Real-time Step Detection**: Using accelerometer sensor data with advanced peak detection algorithm
- **Low-pass Filtering**: Smooths acceleration data to reduce noise and false positives
- **Live Motion Classification**: Identifies idle, walking, and running states
- **Real-time Charts**: Visual acceleration magnitude display with `fl_chart`
- **Persistence**: Daily step data stored locally using SQLite
- **Settings Management**: Configurable height, weight, and stride length with auto-calculation
- **Calibration Mode**: Walk 10 steps to automatically calibrate your stride length
- **Background Counting**: Android foreground service for step counting when app is backgrounded
- **Modern UI**: Material Design 3 with beautiful, responsive layouts

## Tech Stack

- **Framework**: Flutter (Stable)
- **Language**: Dart
- **Sensors**: `sensors_plus` for accelerometer data
- **Charts**: `fl_chart` for data visualization
- **Database**: `sqflite` for local storage
- **Permissions**: `permission_handler` for Android permissions
- **Background Service**: `flutter_background_service` for background step counting
- **Min SDK**: Android 23 (Android 6.0 Marshmallow)

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── step_data.dart        # Data models (DailyStepData, MotionState, UserSettings)
├── services/
│   ├── step_detector.dart    # Core step detection algorithm
│   ├── step_counter_service.dart  # Main service managing sensors and data
│   ├── database_helper.dart  # SQLite database operations
│   └── settings_manager.dart # User preferences storage
└── screens/
    ├── home_screen.dart      # Main UI with step counter and charts
    ├── settings_screen.dart  # User settings configuration
    └── calibration_screen.dart # Stride length calibration
test/
├── step_detector_test.dart   # Unit tests for step detection
└── database_helper_test.dart # Unit tests for database operations
```

## Algorithm

### Step Detection Algorithm

1. **Accelerometer Data Processing**
   - Listen to accelerometer stream from `sensors_plus`
   - Calculate magnitude: `M = sqrt(x² + y² + z²)`

2. **Low-pass Filtering**
   - Apply smoothing: `filtered = α * prev + (1 - α) * current`
   - Default `α = 0.8` (configurable)

3. **Peak-based Detection**
   - Detect acceleration peaks that exceed threshold (default: 9.0 m/s²)
   - Enforce minimum step interval (default: 300ms)
   - Use valley-to-peak pattern recognition

4. **Motion Classification**
   - **Idle**: Mean acceleration < 9.5 m/s²
   - **Walking**: Mean 10.5-15.0 m/s², low variance (< 2.0)
   - **Running**: Mean > 15.0 m/s², high variance (> 2.5)

## Setup Instructions

### Prerequisites

- Flutter SDK 3.9.2 or higher
- Android Studio or VS Code with Flutter extensions
- Android device or emulator (API 23+)

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd stepcounter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## Android Configuration

### Required Permissions

The app requires the following Android permissions (already configured in `AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-feature android:name="android.hardware.sensor.accelerometer" android:required="true" />
```

### Android Manifest Changes

The following service configuration is required for background step counting:

```xml
<service
    android:name="id.flutter.flutter_background_service.BackgroundService"
    android:foregroundServiceType="activityRecognition"
    android:exported="false" />
```

### Min SDK Configuration

Minimum SDK is set to 23 (Android 6.0) in `android/app/build.gradle.kts`:

```kotlin
minSdk = 23
```

## Usage

### First Time Setup

1. **Launch the app** - The app will request necessary permissions
2. **Configure settings** - Tap the settings icon to set your height and weight
3. **Calibrate** - Use the calibration button to walk 10 steps for accurate stride length
4. **Start counting** - Press the Start button to begin step detection

### Main Features

- **Live Step Count**: Shows real-time step count, distance, and calories
- **Motion State Indicator**: Displays current activity state (idle/walking/running)
- **Acceleration Chart**: Real-time visualization of acceleration magnitude
- **Settings**: Configure height, weight, stride length, and detection sensitivity
- **Calibration**: Automatic stride length calculation by walking 10 steps

### Background Operation

The app runs as a foreground service on Android, allowing step counting to continue when the app is minimized or locked. A persistent notification is shown while counting is active.

## Testing

The project includes comprehensive unit tests:

### Run All Tests

```bash
flutter test
```

### Run Specific Test Files

```bash
flutter test test/step_detector_test.dart
flutter test test/database_helper_test.dart
```

### Test Coverage

- ✅ Step detection algorithm with various acceleration patterns
- ✅ Database CRUD operations
- ✅ Edge cases (zero acceleration, threshold limits)
- ✅ Motion state classification
- ✅ Data persistence and retrieval

## Build Instructions

### Debug Build

```bash
flutter build apk --debug
```

### Release Build

```bash
flutter build apk --release
```

### Build Output

The APK will be generated in `build/app/outputs/flutter-apk/app-release.apk`

## Algorithm Parameters

### Configurable Settings

- **Step Threshold**: Minimum acceleration for step detection (default: 9.0 m/s²)
- **Smoothing Factor**: Low-pass filter coefficient α (default: 0.8)
- **Min Step Interval**: Minimum time between steps in milliseconds (default: 300ms)

These can be adjusted in the Settings screen.

## Database Schema

```sql
CREATE TABLE daily_steps (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL UNIQUE,
    steps INTEGER NOT NULL,
    distance REAL NOT NULL,
    calories REAL NOT NULL,
    activityTime REAL NOT NULL
);
```

## Troubleshooting

### Permission Issues

If step counting doesn't work:
1. Check that ACTIVITY_RECOGNITION permission is granted
2. On Android 11+, go to Settings → Apps → Step Counter → Permissions
3. Enable "Physical Activity" permission

### No Step Detection

1. Ensure the app has sensor permissions
2. Try recalibrating your stride length
3. Adjust the step threshold in settings (lower = more sensitive)
4. Check that the device has an accelerometer sensor

### App Not Working in Background

1. Ensure the app has foreground service permissions
2. Check that battery optimization is disabled for the app
3. Verify the app appears in "Running services" when backgrounded

## Future Enhancements

- [ ] iOS support with CoreMotion integration
- [ ] Machine learning model for improved accuracy (TFLite)
- [ ] Historical data visualization (weekly/monthly charts)
- [ ] Goal setting and achievement badges
- [ ] Social features and leaderboards
- [ ] Wearable device integration
- [ ] GPS tracking for route mapping

## License

This project is open source and available for personal use.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgments

- Flutter team for the excellent framework
- sensors_plus for sensor access
- fl_chart for beautiful charts
- sqflite for local database support

---

**Note**: This app requires a physical Android device with an accelerometer sensor to function properly. Emulators may not provide accurate step detection.

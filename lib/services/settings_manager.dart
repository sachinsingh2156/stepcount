import 'package:shared_preferences/shared_preferences.dart';
import '../models/step_data.dart';

class SettingsManager {
  static final SettingsManager instance = SettingsManager._init();
  SharedPreferences? _prefs;

  SettingsManager._init();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveSettings(UserSettings settings) async {
    await _checkPrefs();
    await _prefs!.setDouble('height', settings.height);
    await _prefs!.setDouble('weight', settings.weight);
    await _prefs!.setDouble('strideLength', settings.strideLength ?? 0.0);
    await _prefs!.setDouble('stepThreshold', settings.stepThreshold);
    await _prefs!.setDouble('smoothingFactor', settings.smoothingFactor);
  }

  Future<UserSettings> loadSettings() async {
    await _checkPrefs();
    
    final height = _prefs!.getDouble('height') ?? 170.0;
    final weight = _prefs!.getDouble('weight') ?? 70.0;
    final strideLength = _prefs!.getDouble('strideLength');
    final stepThreshold = _prefs!.getDouble('stepThreshold') ?? 9.0;
    final smoothingFactor = _prefs!.getDouble('smoothingFactor') ?? 0.8;

    return UserSettings(
      height: height,
      weight: weight,
      strideLength: strideLength == 0.0 ? null : strideLength,
      stepThreshold: stepThreshold,
      smoothingFactor: smoothingFactor,
    );
  }

  Future<void> _checkPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
}


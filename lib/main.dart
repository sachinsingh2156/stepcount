import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Request necessary permissions
  await _requestPermissions();
  
  runApp(const SmartStepCounterApp());
}

Future<void> _requestPermissions() async {
  // Request activity recognition permission for Android
  await Permission.activityRecognition.request();
  
  // Request sensors permission for Android 12+
  await Permission.sensors.request();
}

class SmartStepCounterApp extends StatelessWidget {
  const SmartStepCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Step Counter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

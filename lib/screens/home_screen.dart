import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/step_data.dart';
import '../services/step_counter_service.dart';
import 'settings_screen.dart';
import 'calibration_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StepCounterService _service = StepCounterService.instance;
  
  int _steps = 0;
  double _distance = 0.0;
  double _calories = 0.0;
  MotionState _motionState = MotionState.idle;
  List<double> _accelerationHistory = [];
  
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _service.initialize();
    
    // Set up callbacks
    _service.onStepsUpdated = (steps) {
      setState(() => _steps = steps);
    };
    
    _service.onMotionStateUpdated = (state) {
      setState(() => _motionState = state);
    };
    
    _service.onAccelerationUpdated = (history) {
      setState(() => _accelerationHistory = history);
    };
    
    // Load initial data
    setState(() {
      _steps = _service.currentSteps;
      _motionState = _service.motionState;
      _isRunning = _service.isRunning;
    });
    
    await _updateStats();
  }

  Future<void> _updateStats() async {
    final stats = await _service.getTodayStats();
    setState(() {
      _distance = stats['distance'] as double;
      _calories = stats['calories'] as double;
      _motionState = stats['motionState'] as MotionState;
    });
  }

  void _toggleCounter() async {
    if (_isRunning) {
      _service.stop();
    } else {
      await _service.start();
    }
    setState(() {
      _isRunning = _service.isRunning;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Step Counter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateToSettings(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _updateStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Motion State Indicator
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getMotionStateColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getMotionStateIcon(),
                      size: 32,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _getMotionStateText(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Step Counter Card
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        '$_steps',
                        style: const TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Text(
                        'Steps',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard('Distance', '${_distance.toStringAsFixed(2)} km'),
                          _buildStatCard('Calories', '${_calories.toStringAsFixed(0)}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Acceleration Chart
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Acceleration',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: _buildAccelerationChart(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Control Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _toggleCounter,
                        icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                        label: Text(_isRunning ? 'Pause' : 'Start'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRunning ? Colors.orange : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _service.resetSteps,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCalibration(),
        child: const Icon(Icons.fit_screen),
        tooltip: 'Calibrate',
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildAccelerationChart() {
    if (_accelerationHistory.isEmpty) {
      return const Center(
        child: Text('No data yet. Start walking!'),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _generateSpots(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 2,
            dotData: FlDotData(show: false),
          ),
        ],
        minY: _calculateMinY(),
        maxY: _calculateMaxY(),
      ),
    );
  }

  List<FlSpot> _generateSpots() {
    return _accelerationHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
  }

  double _calculateMinY() {
    if (_accelerationHistory.isEmpty) return 0;
    return (_accelerationHistory.reduce((a, b) => a < b ? a : b) - 2).clamp(0, double.infinity);
  }

  double _calculateMaxY() {
    if (_accelerationHistory.isEmpty) return 20;
    return _accelerationHistory.reduce((a, b) => a > b ? a : b) + 2;
  }

  Color _getMotionStateColor() {
    switch (_motionState) {
      case MotionState.idle:
        return Colors.grey;
      case MotionState.walking:
        return Colors.green;
      case MotionState.running:
        return Colors.red;
    }
  }

  IconData _getMotionStateIcon() {
    switch (_motionState) {
      case MotionState.idle:
        return Icons.pause_circle_outline;
      case MotionState.walking:
        return Icons.directions_walk;
      case MotionState.running:
        return Icons.directions_run;
    }
  }

  String _getMotionStateText() {
    switch (_motionState) {
      case MotionState.idle:
        return 'Idle';
      case MotionState.walking:
        return 'Walking';
      case MotionState.running:
        return 'Running';
    }
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    ).then((_) => setState(() {}));
  }

  void _navigateToCalibration() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CalibrationScreen()),
    );
  }
}


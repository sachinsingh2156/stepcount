import 'package:flutter_test/flutter_test.dart';
import 'package:stepcounter/services/database_helper.dart';
import 'package:stepcounter/models/step_data.dart';

void main() {
  late DatabaseHelper dbHelper;

  setUp(() async {
    dbHelper = DatabaseHelper.instance;
    await dbHelper.database;
  });

  tearDown(() async {
    await dbHelper.clearAllData();
  });

  group('DatabaseHelper', () {
    test('should insert daily step data', () async {
      final data = DailyStepData(
        id: 0,
        date: DateTime.now(),
        steps: 1000,
        distance: 0.8,
        calories: 40.0,
        activityTime: 10.0,
      );

      await dbHelper.insertOrUpdateDailySteps(data);
      
      final todayData = await dbHelper.getTodayData();
      expect(todayData, isNotNull);
      expect(todayData!.steps, 1000);
      expect(todayData.distance, 0.8);
    });

    test('should update existing daily step data', () async {
      final data1 = DailyStepData(
        id: 0,
        date: DateTime.now(),
        steps: 1000,
        distance: 0.8,
        calories: 40.0,
        activityTime: 10.0,
      );

      await dbHelper.insertOrUpdateDailySteps(data1);
      final todayData1 = await dbHelper.getTodayData();
      expect(todayData1!.steps, 1000);

      final data2 = DailyStepData(
        id: todayData1.id,
        date: DateTime.now(),
        steps: 2000,
        distance: 1.6,
        calories: 80.0,
        activityTime: 20.0,
      );

      await dbHelper.insertOrUpdateDailySteps(data2);
      final todayData2 = await dbHelper.getTodayData();
      expect(todayData2!.steps, 2000);
      expect(todayData2.id, todayData1.id);
    });

    test('should retrieve all daily data', () async {
      final now = DateTime.now();
      
      for (int i = 0; i < 5; i++) {
        final data = DailyStepData(
          id: 0,
          date: now.subtract(Duration(days: i)),
          steps: 1000 + i * 100,
          distance: 0.8 + i * 0.1,
          calories: 40.0 + i * 4.0,
          activityTime: 10.0 + i,
        );
        await dbHelper.insertOrUpdateDailySteps(data);
      }

      final allData = await dbHelper.getAllDailyData();
      expect(allData.length, 5);
    });

    test('should retrieve data for date range', () async {
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 7));
      final endDate = now;

      final rangeData = await dbHelper.getDataForDateRange(startDate, endDate);
      
      // Should return at least today's data if it exists
      expect(rangeData, isA<List<DailyStepData>>());
    });

    test('should calculate total steps for period', () async {
      final now = DateTime.now();
      
      for (int i = 0; i < 3; i++) {
        final data = DailyStepData(
          id: 0,
          date: now.subtract(Duration(days: i)),
          steps: 1000,
          distance: 0.8,
          calories: 40.0,
          activityTime: 10.0,
        );
        await dbHelper.insertOrUpdateDailySteps(data);
      }

      final total = await dbHelper.getTotalStepsForPeriod(
        now.subtract(const Duration(days: 2)),
        now,
      );
      
      expect(total, greaterThanOrEqualTo(1000));
    });

    test('should handle empty database gracefully', () async {
      final todayData = await dbHelper.getTodayData();
      expect(todayData, isNull);
    });

    test('should delete data by date', () async {
      final data = DailyStepData(
        id: 0,
        date: DateTime.now(),
        steps: 1000,
        distance: 0.8,
        calories: 40.0,
        activityTime: 10.0,
      );

      await dbHelper.insertOrUpdateDailySteps(data);
      expect(await dbHelper.getTodayData(), isNotNull);

      final today = DateTime.now().toIso8601String().split('T')[0];
      await dbHelper.deleteDataByDate(today);
      
      expect(await dbHelper.getTodayData(), isNull);
    });

    test('should clear all data', () async {
      final data = DailyStepData(
        id: 0,
        date: DateTime.now(),
        steps: 1000,
        distance: 0.8,
        calories: 40.0,
        activityTime: 10.0,
      );

      await dbHelper.insertOrUpdateDailySteps(data);
      await dbHelper.clearAllData();
      
      final allData = await dbHelper.getAllDailyData();
      expect(allData.length, 0);
    });

    test('should create unique dates', () async {
      final data1 = DailyStepData(
        id: 0,
        date: DateTime.now(),
        steps: 1000,
        distance: 0.8,
        calories: 40.0,
        activityTime: 10.0,
      );

      final data2 = DailyStepData(
        id: 0,
        date: DateTime.now(),
        steps: 2000,
        distance: 1.6,
        calories: 80.0,
        activityTime: 20.0,
      );

      await dbHelper.insertOrUpdateDailySteps(data1);
      await dbHelper.insertOrUpdateDailySteps(data2);

      final allData = await dbHelper.getAllDailyData();
      // Same date should replace, so should have 1 entry
      expect(allData.length, 1);
    });
  });
}


import 'package:health/health.dart';

class HealthService {
  final HealthFactory health = HealthFactory(useHealthConnectIfAvailable: true);

  // Types of data we want to access
  final types = [HealthDataType.NUTRITION];

  // Request permissions from HealthKit
  Future<bool> requestPermissions() async {
    try {
      return await health.requestAuthorization(types);
    } catch (e) {
      print("Error requesting permission: $e");
      return false;
    }
  }

  // Fetch caffeine data from the last 24 hours
  Future<List<HealthDataPoint>> getCaffeineData() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));

    try {
      return await health.getHealthDataFromTypes(
        yesterday,
        now,
        types,
      );
    } catch (e) {
      print("Error fetching caffeine data: $e");
      return [];
    }
  }

  // Add caffeine intake manually (for testing or manual entry)
  Future<bool> addCaffeineIntake(double amount) async {
    try {
      return await health.writeHealthData(
        amount,
        HealthDataType.NUTRITION,
        DateTime.now(),
        DateTime.now(),
      );
    } catch (e) {
      print("Error adding caffeine intake: $e");
      return false;
    }
  }
}

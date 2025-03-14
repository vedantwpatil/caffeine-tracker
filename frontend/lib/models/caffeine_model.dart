import 'dart:math';
import "package:fl_chart/fl_chart.dart";

class CaffeineIntake {
  final DateTime time;
  final double amount; // mg

  CaffeineIntake(this.time, this.amount);
}

class CaffeineModel {
  List<CaffeineIntake> intakes = [];

  // Caffeine half-life (approximately 5.7 hours)
  final double halfLifeHours = 5.7;

  // Calculate decay factor from half-life
  double get decayFactor => 0.5 / halfLifeHours;

  // Add a new caffeine intake
  void addIntake(DateTime time, double amount) {
    intakes.add(CaffeineIntake(time, amount));
    // Sort intakes by time (oldest first)
    intakes.sort((a, b) => a.time.compareTo(b.time));
  }

  // Calculate current caffeine level
  double getCurrentLevel() {
    return calculateLevelAt(DateTime.now());
  }

  // Calculate caffeine level at a specific time
  double calculateLevelAt(DateTime time) {
    double totalCaffeine = 0;

    for (var intake in intakes) {
      // Skip future intakes
      if (intake.time.isAfter(time)) continue;

      // Calculate hours elapsed since intake
      double hoursElapsed = time.difference(intake.time).inMinutes / 60;

      // Apply exponential decay: amount * 0.5^(hours/halfLife)
      double remainingCaffeine =
          intake.amount * pow(0.5, hoursElapsed / halfLifeHours);

      totalCaffeine += remainingCaffeine;
    }

    return totalCaffeine;
  }

  // Generate data points for a caffeine curve over time
  List<FlSpot> generateCurvePrediction(int hoursAhead) {
    List<FlSpot> dataPoints = [];
    final now = DateTime.now();

    // Generate points at 15-minute intervals
    for (int i = 0; i <= hoursAhead * 4; i++) {
      final timePoint = now.add(Duration(minutes: i * 15));
      final level = calculateLevelAt(timePoint);
      dataPoints.add(FlSpot(i / 4, level)); // Convert to hours for x-axis
    }

    return dataPoints;
  }

  // Calculate optimal time for next caffeine intake (when level drops below threshold)
  DateTime getOptimalNextIntakeTime(double threshold) {
    final now = DateTime.now();

    // Check every 15 minutes for the next 24 hours
    for (int i = 1; i <= 24 * 4; i++) {
      final checkTime = now.add(Duration(minutes: i * 15));
      final level = calculateLevelAt(checkTime);

      if (level < threshold) {
        return checkTime;
      }
    }

    // Default to 24 hours if level doesn't drop below threshold
    return now.add(const Duration(hours: 24));
  }

  // Calculate optimal bedtime (when caffeine drops below sleep threshold)
  DateTime getOptimalBedtime(double sleepThreshold) {
    return getOptimalNextIntakeTime(sleepThreshold);
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:health/health.dart';
import 'package:provider/provider.dart';
import '../models/caffeine_model.dart';
import '../services/health_service.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _caffeineController = TextEditingController();
  final HealthService _healthService = HealthService();
  final CaffeineModel _caffeineModel = CaffeineModel();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final permissionGranted = await _healthService.requestPermissions();
    if (permissionGranted) {
      await _loadCaffeineData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Health permissions denied')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadCaffeineData() async {
    final caffeineData = await _healthService.getCaffeineData();

    // Clear existing data
    _caffeineModel.intakes.clear();

    // Add each data point to the model
    for (var dataPoint in caffeineData) {
      // For filtering caffeine data
      if (dataPoint.type == HealthDataType.NUTRITION) {
        if (dataPoint.value is NutritionHealthValue) {
          var nutritionValue = dataPoint.value as NutritionHealthValue;
          if (nutritionValue.name == 'caffeine') {
            // Handle caffeine data here
            double caffeineAmount = nutritionValue.numericValue;
          }
        }
      }
    }

    setState(() {});
  }

  Future<void> _addCaffeineIntake() async {
    if (_caffeineController.text.isEmpty) return;

    final amount = double.tryParse(_caffeineController.text);
    if (amount == null || amount <= 0) return;

    // Add to HealthKit
    final success = await _healthService.addCaffeineIntake(amount);

    if (success) {
      // Add to our model
      _caffeineModel.addIntake(DateTime.now(), amount);
      _caffeineController.clear();
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add caffeine intake')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLevel = _caffeineModel.getCurrentLevel();
    final optimalNextIntake =
        _caffeineModel.getOptimalNextIntakeTime(50); // 50mg threshold
    final optimalBedtime =
        _caffeineModel.getOptimalBedtime(30); // 30mg sleep threshold

    return Scaffold(
      appBar: AppBar(
        title: Text('Caffeine Tracker'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Caffeine Levels
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Caffeine Level',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${currentLevel.toStringAsFixed(1)} mg',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: _getCaffeineColor(currentLevel),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Caffeine Chart
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Predicted Caffeine Levels',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: _buildCaffeineChart(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Recommendations
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recommendations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          ListTile(
                            leading: Icon(Icons.coffee),
                            title: Text('Optimal next caffeine intake'),
                            subtitle: Text(
                              _formatDateTime(optimalNextIntake),
                            ),
                          ),
                          ListTile(
                            leading: Icon(Icons.bed),
                            title: Text('Optimal bedtime'),
                            subtitle: Text(
                              _formatDateTime(optimalBedtime),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Add Caffeine Form
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Caffeine Intake',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _caffeineController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Caffeine amount (mg)',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _addCaffeineIntake,
                                child: Text('Add'),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Common amounts: Coffee (95mg), Espresso (63mg), Tea (47mg)',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCaffeineChart() {
    final predictionData = _caffeineModel.generateCurvePrediction(12);

    if (predictionData.isEmpty) {
      return Center(child: Text('No data available'));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value % 2 == 0) {
                  return Text('${value.toInt()}h');
                }
                return Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: predictionData,
            isCurved: true,
            color: Colors.brown,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.brown.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCaffeineColor(double level) {
    if (level > 300) return Colors.red;
    if (level > 200) return Colors.orange;
    if (level > 100) return Colors.green;
    return Colors.blue;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

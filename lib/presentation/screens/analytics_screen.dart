import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/models/fuel_log_model.dart';
import '../../data/models/service_log_model.dart';
import '../../core/services/vehicle_service.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/premium_background.dart';

class AnalyticsScreen extends StatefulWidget {
  final Vehicle vehicle;

  const AnalyticsScreen({super.key, required this.vehicle});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<FuelLog> _fuelLogs = [];
  List<ServiceLog> _serviceLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final service = Provider.of<VehicleService>(context, listen: false);
    if (widget.vehicle.id != null) {
      final fuels = await service.getFuelLogs(widget.vehicle.id!);
      final services = await service.getServiceLogs(widget.vehicle.id!);
      setState(() {
        _fuelLogs = fuels;
        _serviceLogs = services;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Analytics'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primaryLight,
            labelColor: AppColors.primaryLight,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Fuel'),
              Tab(text: 'Service'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildFuelAnalytics(),
                  _buildServiceAnalytics(),
                ],
              ),
      ),
    );
  }

  Widget _buildFuelAnalytics() {
    if (_fuelLogs.isEmpty) {
      return const Center(child: Text('No fuel logs available'));
    }

    // Calculate Average Mileage
    double totalDistance = 0;
    double totalFuel = 0;
    // Simple mileage calc: (Last Odo - First Odo) / Total Fuel (excluding first fill if needed, but keeping simple)
    // Actually, accurate mileage needs pairs. Let's do simple Total Odo / Total Liters for lifecycle or 
    // just map efficiency if logs have it. 
    // Let's assume user enters odometer. 
    // We can compute distance between consecutive logs.
    
    // Sort by odometer
    _fuelLogs.sort((a, b) => a.odometer.compareTo(b.odometer));

    double totalCost = _fuelLogs.fold(0, (sum, item) => sum + item.totalCost);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // KPI Cards
          Row(
            children: [
              Expanded(child: _buildKPICard('Total Logs', '${_fuelLogs.length}')),
              const SizedBox(width: 12),
              Expanded(child: _buildKPICard('Total Cost', '\$${totalCost.toStringAsFixed(0)}')),
            ],
          ),
          const SizedBox(height: 24),

          // Fuel Price Trend
          const Text('Fuel Price Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: GlassCard(
              padding: const EdgeInsets.only(right: 24, left: 12, top: 24, bottom: 12),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _fuelLogs.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.pricePerLiter);
                      }).toList(),
                      isCurved: true,
                      color: AppColors.primaryLight,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: AppColors.primaryLight.withOpacity(0.1)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildServiceAnalytics() {
    if (_serviceLogs.isEmpty) {
      return const Center(child: Text('No service logs available'));
    }

    double totalCost = _serviceLogs.fold(0, (sum, item) => sum + item.cost);
    
    // Group by type
    final Map<String, double> costByType = {};
    for (var log in _serviceLogs) {
      costByType[log.serviceType] = (costByType[log.serviceType] ?? 0) + log.cost;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildKPICard('Total Service Cost', '\$${totalCost.toStringAsFixed(0)}'),
          const SizedBox(height: 24),
          
          const Text('Cost Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: GlassCard(
              child: PieChart(
                PieChartData(
                  sections: costByType.entries.map((e) {
                    final isLarge = e.value / totalCost > 0.2;
                    return PieChartSectionData(
                      value: e.value,
                      title: '${e.key}\n${(e.value/totalCost*100).toStringAsFixed(0)}%',
                      radius: isLarge ? 100 : 80,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      color: Colors.primaries[costByType.keys.toList().indexOf(e.key) % Colors.primaries.length],
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildKPICard(String label, String value) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
        ],
      ),
    );
  }
}

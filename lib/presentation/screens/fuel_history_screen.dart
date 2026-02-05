import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/vehicle_service.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/models/fuel_log_model.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/premium_background.dart';
import '../widgets/premium_app_bar.dart';
import '../widgets/glass_card.dart';
import 'add_fuel_screen.dart';

class FuelHistoryScreen extends StatefulWidget {
  final Vehicle vehicle;

  const FuelHistoryScreen({super.key, required this.vehicle});

  @override
  State<FuelHistoryScreen> createState() => _FuelHistoryScreenState();
}

class _FuelHistoryScreenState extends State<FuelHistoryScreen> {
  List<FuelLog> _logs = [];
  bool _isLoading = true;
  double _averageMileage = 0;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final service = Provider.of<VehicleService>(context, listen: false);
    final logs = await service.getFuelLogs(widget.vehicle.id!);
    
    // Logic same as before
    double totalDist = 0;
    double totalLitters = 0;
    
    final sortedLogs = List<FuelLog>.from(logs)..sort((a, b) => a.odometer.compareTo(b.odometer));
    
    for (int i = 0; i < sortedLogs.length - 1; i++) {
      final current = sortedLogs[i+1];
      final previous = sortedLogs[i];
      final dist = current.odometer - previous.odometer;
      totalDist += dist;
      totalLitters += current.liters;
    }

    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
        _averageMileage = totalDist > 0 && totalLitters > 0 ? totalDist / totalLitters : 0;
      });
    }
  }

  void _addFuel() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFuelScreen(vehicle: widget.vehicle),
      ),
    );

    if (result == true) {
      _loadLogs();
    }
  }

  void _deleteLog(int id) async {
    final service = Provider.of<VehicleService>(context, listen: false);
    await service.deleteFuelLog(id);
    _loadLogs();
  }

  String _calculateEfficiency(int index) {
      if (index >= _logs.length - 1) return '-';

      final current = _logs[index];
      final previous = _logs[index + 1];

      final dist = current.odometer - previous.odometer;
      if (dist <= 0) return '-'; 
      
      final efficiency = dist / current.liters;
      return '${efficiency.toStringAsFixed(1)}';
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PremiumAppBar(title: '${widget.vehicle.name} Fuel Logs'),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_logs.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GlassCard(
                        borderRadius: 24,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text('Average Mileage', style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(
                                  '${_averageMileage.toStringAsFixed(1)} km/L',
                                  style: TextStyle(
                                    fontSize: 28, 
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).textTheme.titleLarge?.color,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().scale(curve: Curves.easeOutBack),
                    ),
      
                  Expanded(
                    child: _logs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_gas_station_rounded, size: 64, color: Colors.grey.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text(
                                'No Fuel Logs Yet',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.withOpacity(0.7)),
                              ),
                              const SizedBox(height: 8),
                              Text('Log refills to track mileage.', style: TextStyle(color: Colors.grey.withOpacity(0.5))),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            final log = _logs[index];
                            final efficiency = _calculateEfficiency(index);
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GlassCard(
                                borderRadius: 16,
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                            color: AppColors.primaryLight.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12)
                                        ),
                                        child: Icon(Icons.water_drop_rounded, color: AppColors.primaryLight)
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            log.date,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${log.odometer} km • ${log.liters} L',
                                            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7), fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                            Text(
                                                NumberFormat.currency(symbol: '\$').format(log.totalCost),
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            if (efficiency != '-')
                                                Container(
                                                    margin: const EdgeInsets.only(top: 4),
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                        color: AppColors.success.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: AppColors.success.withOpacity(0.2))
                                                    ),
                                                    child: Text('$efficiency km/L', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success))
                                                )
                                        ],
                                    ),
                                    const SizedBox(width: 8),
                                    PopupMenuButton(
                                      icon: Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey.withOpacity(0.7)),
                                      color: Theme.of(context).cardColor,
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_rounded, color: AppColors.error, size: 20),
                                              const SizedBox(width: 8),
                                              Text('Delete', style: TextStyle(color: AppColors.error)),
                                            ],
                                          ),
                                          onTap: () => _deleteLog(log.id!),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(delay: (index * 50).ms).slideX(),
                            );
                          },
                        ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addFuel,
          backgroundColor: AppColors.accentLight,
          foregroundColor: Colors.white,
          elevation: 8,
          child: const Icon(Icons.add_rounded, size: 32),
        ).animate().scale(delay: 500.ms),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/services/vehicle_service.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/models/fuel_log_model.dart';
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
    
    // Calculate Average Mileage
    double totalDist = 0;
    double totalLitters = 0;
    
    // We need logs sorted by odometer (asc) to calculate correctly
    // But logs are sorted by date desc currently.
    final sortedLogs = List<FuelLog>.from(logs)..sort((a, b) => a.odometer.compareTo(b.odometer));
    
    for (int i = 0; i < sortedLogs.length - 1; i++) {
      final current = sortedLogs[i+1];
      final previous = sortedLogs[i];
      
      final dist = current.odometer - previous.odometer;
      
      // Mileage is distance covered ON the fuel filled previously?
      // Or simply: Distance covered / Fuel consumed.
      // Usually: Fill up to full. Next fill up to full. (Current Odo - Last Odo) / Current Liters.
      // Simplified here: Total Distance / Total Fuel (excluding start/end edge cases)
      // Let's use individual efficiency: (Current Odo - Previous Odo) / Current Liters (assuming tank filled)
      
      // Simplified for "Average": Total Distance / Total Liters Consumed
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
      // Current log is at index. Previous log (chronologically before) is at index + 1 (since sorted DESC date)
      if (index >= _logs.length - 1) return '-';

      final current = _logs[index];
      final previous = _logs[index + 1];

      final dist = current.odometer - previous.odometer;
      if (dist <= 0) return '-'; 
      
      final efficiency = dist / current.liters;
      return '${efficiency.toStringAsFixed(1)} km/L';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.vehicle.name} Fuel Logs'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_logs.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    child: Column(
                      children: [
                        Text(
                          'Average Efficiency',
                          style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_averageMileage.toStringAsFixed(1)} km/L',
                          style: TextStyle(
                            fontSize: 32, 
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: _logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_gas_station, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No Fuel Logs Yet',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            const Text('Log refills to track mileage.'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          final efficiency = _calculateEfficiency(index);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        log.date,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${log.odometer} km',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 24),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${log.liters} L'),
                                      Text(
                                        NumberFormat.currency(symbol: '\$').format(log.totalCost),
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: efficiency == '-' 
                                          ? Colors.grey[200] 
                                          : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      efficiency,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: efficiency == '-' 
                                            ? Colors.grey 
                                            : Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton(
                                    icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: const Row(
                                          children: [
                                            Icon(Icons.delete, color: Colors.red, size: 20),
                                            SizedBox(width: 8),
                                            Text('Delete', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                        onTap: () => _deleteLog(log.id!),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFuel,
        child: const Icon(Icons.add),
      ),
    );
  }
}

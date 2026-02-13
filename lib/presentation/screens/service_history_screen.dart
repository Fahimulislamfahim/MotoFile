import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/vehicle_service.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/models/service_log_model.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/premium_background.dart';
import '../widgets/premium_app_bar.dart';
import '../widgets/glass_card.dart';
import 'add_service_screen.dart';

class ServiceHistoryScreen extends StatefulWidget {
  final Vehicle vehicle;

  const ServiceHistoryScreen({super.key, required this.vehicle});

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  List<ServiceLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final service = Provider.of<VehicleService>(context, listen: false);
    final logs = await service.getServiceLogs(widget.vehicle.id!);
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  void _addService() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddServiceScreen(vehicle: widget.vehicle),
      ),
    );

    if (result == true) {
      _loadLogs();
    }
  }
  
  void _deleteLog(int id) async {
    final service = Provider.of<VehicleService>(context, listen: false);
    await service.deleteServiceLog(id);
    _loadLogs();
  }

  IconData _getServiceIcon(String type) {
    if (type.toLowerCase().contains('oil')) return Icons.oil_barrel_rounded;
    if (type.toLowerCase().contains('tire')) return Icons.tire_repair_rounded;
    if (type.toLowerCase().contains('brake')) return Icons.car_crash_rounded;
    if (type.toLowerCase().contains('battery')) return Icons.battery_charging_full_rounded;
    return Icons.build_circle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PremiumAppBar(title: '${widget.vehicle.name} Service'),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _logs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 64, color: Colors.grey.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'No Service Logs Yet',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.withOpacity(0.7)),
                        ),
                        const SizedBox(height: 8),
                        Text('Track your maintenance here.', style: TextStyle(color: Colors.grey.withOpacity(0.5))),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return RepaintBoundary(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12)
                                  ),
                                  child: Icon(_getServiceIcon(log.serviceType), color: AppColors.primaryLight)
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        log.serviceType,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${log.date} • ${log.odometer} km',
                                        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7), fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                     Text(
                                       NumberFormat.currency(symbol: '\$').format(log.cost),
                                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                     ),
                                     IconButton(
                                        icon: Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error.withOpacity(0.7)),
                                        onPressed: () {
                                           showDialog(
                                             context: context,
                                             builder: (ctx) => AlertDialog(
                                                 backgroundColor: Theme.of(context).cardColor,
                                                 title: const Text('Delete Log?'),
                                                 content: const Text('This cannot be undone.'),
                                                 actions: [
                                                   TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                                   TextButton(onPressed: () { Navigator.pop(ctx); _deleteLog(log.id!); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                                 ]
                                             )
                                           );
                                        },
                                     )
                                  ],
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: (index < 10 ? index * 50 : 500).ms).slideX(),
                        ),
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addService,
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 32),
        ).animate().scale(delay: 500.ms),
      ),
    );
  }
}

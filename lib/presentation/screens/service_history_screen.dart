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
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          borderRadius: 20,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    log.serviceType,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  Text(
                                    log.date,
                                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7), fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.speed_rounded, size: 16, color: AppColors.primaryLight),
                                  const SizedBox(width: 4),
                                  Text('${log.odometer} km'),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentLight.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.accentLight.withOpacity(0.2))
                                    ),
                                    child: Text(
                                      '${NumberFormat.currency(symbol: '\$').format(log.cost)}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.accentLight,
                                          fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              if (log.notes != null && log.notes!.isNotEmpty) ...[
                                Divider(height: 24, color: Theme.of(context).dividerColor.withOpacity(0.1)),
                                Text(
                                  log.notes!,
                                  style: TextStyle(fontStyle: FontStyle.italic, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8)),
                                ),
                              ],
                               Row(
                                 mainAxisAlignment: MainAxisAlignment.end,
                                 children: [
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
                               )
                            ],
                          ),
                        ).animate().fadeIn(delay: (index * 50).ms).slideX(),
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addService,
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add_rounded, size: 32),
        ).animate().scale(delay: 500.ms),
      ),
    );
  }
}

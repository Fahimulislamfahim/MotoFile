import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/services/vehicle_service.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/models/service_log_model.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.vehicle.name} Service History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No Service Logs Yet',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      const Text('Track your maintenance here.'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  log.serviceType,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  log.date,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.speed, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text('${log.odometer} km'),
                                const Spacer(),
                                Text(
                                  '${NumberFormat.currency(symbol: '\$').format(log.cost)}', // Using $ for generic currency
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 16),
                                ),
                              ],
                            ),
                            if (log.notes != null && log.notes!.isNotEmpty) ...[
                              const Divider(height: 24),
                              Text(
                                log.notes!,
                                style: const TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ],
                            
                            // Align delete button to the right
                             Row(
                               mainAxisAlignment: MainAxisAlignment.end,
                               children: [
                                 TextButton.icon(
                                   onPressed: () {
                                     showDialog(
                                       context: context,
                                       builder: (context) => AlertDialog(
                                         title: const Text('Delete Log?'),
                                         content: const Text('This cannot be undone.'),
                                         actions: [
                                           TextButton(
                                             onPressed: () => Navigator.pop(context), 
                                             child: const Text('Cancel')
                                           ),
                                           TextButton(
                                             onPressed: () {
                                               Navigator.pop(context);
                                               _deleteLog(log.id!);
                                             }, 
                                             child: const Text('Delete', style: TextStyle(color: Colors.red))
                                           ),
                                         ],
                                       )
                                     );
                                   },
                                   icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                   label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                 )
                               ],
                             )
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addService,
        child: const Icon(Icons.add),
      ),
    );
  }
}

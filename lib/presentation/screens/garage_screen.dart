import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/vehicle_service.dart';
import '../../data/models/vehicle_model.dart';
import 'add_vehicle_screen.dart';
import 'service_history_screen.dart';
import 'fuel_history_screen.dart';
import 'reminders_screen.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VehicleService>(context, listen: false).loadVehicles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VehicleService>(
      builder: (context, service, _) {
        if (service.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (service.vehicles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.motorcycle, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No Vehicles Added',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Add your bike or car to get started.'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddEditVehicleScreen()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Vehicle'),
                ),
              ],
            ),
          );
        }

        // For now, let's show the first vehicle. 
        // In future, we can add a switcher if multiple vehicles exist.
        final vehicle = service.vehicles.first; 

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          vehicle.type == 'Car' ? Icons.directions_car : Icons.two_wheeler,
                          size: 40,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle.name,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${vehicle.make} ${vehicle.model} (${vehicle.year})',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEditVehicleScreen(vehicle: vehicle),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Identity Grid
              const Text('Identity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildInfoCard(context, 'License Plate', vehicle.licensePlate, Icons.pin),
                  _buildInfoCard(context, 'Color', vehicle.color, Icons.palette),
                  _buildInfoCard(context, 'VIN / Chassis', vehicle.vin, Icons.fingerprint),
                  _buildInfoCard(context, 'Engine No.', vehicle.engineNumber, Icons.engineering),
                ],
              ),
              const SizedBox(height: 24),

              // Specs Section
              const Text('Specifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
               Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    _buildSpecRole(context, 'Tyre Pressure', vehicle.tyrePressure ?? 'N/A', Icons.air),
                    const Divider(height: 1),
                    _buildSpecRole(context, 'Engine Oil', vehicle.oilType ?? 'N/A', Icons.opacity),
                    const Divider(height: 1),
                    _buildSpecRole(context, 'Fuel Capacity', vehicle.fuelCapacity != null ? '${vehicle.fuelCapacity} L' : 'N/A', Icons.local_gas_station),
                  ],
                ),
              ),

              if (vehicle.notes != null && vehicle.notes!.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Text(vehicle.notes!),
                  ),
                ),
              ],
              
              const SizedBox(height: 30),
              // Future: Service History
              Center(
                 child: OutlinedButton.icon(
                   onPressed: () {
                     Navigator.push(
                       context,
                       MaterialPageRoute(
                         builder: (context) => ServiceHistoryScreen(vehicle: vehicle),
                       ),
                     );
                   },
                   icon: const Icon(Icons.history),
                   label: const Text('View Service History'), 
                 ),
              ),
              const SizedBox(height: 12),
               Center(
                 child: OutlinedButton.icon(
                   onPressed: () {
                     Navigator.push(
                       context,
                       MaterialPageRoute(
                         builder: (context) => FuelHistoryScreen(vehicle: vehicle),
                       ),
                     );
                   },
                   icon: const Icon(Icons.local_gas_station),
                   label: const Text('Fuel Tracker'), 
                 ),
              ),
              const SizedBox(height: 12),
               Center(
                 child: OutlinedButton.icon(
                   onPressed: () {
                     Navigator.push(
                       context,
                       MaterialPageRoute(
                         builder: (context) => RemindersScreen(vehicle: vehicle),
                       ),
                     );
                   },
                   icon: const Icon(Icons.notifications_active),
                   label: const Text('Maintenance Reminders'), 
                 ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(
                  value, 
                  style: const TextStyle(fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRole(BuildContext context, String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(label),
      trailing: Text(
        value, 
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}

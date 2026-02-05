import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/vehicle_service.dart';
import '../../data/models/vehicle_model.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/glass_card.dart';
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
                GlassCard(
                  padding: const EdgeInsets.all(32),
                  borderRadius: 200, // Circular
                  child: Icon(Icons.two_wheeler_rounded, size: 64, color: AppColors.primaryLight.withOpacity(0.5)),
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                Text(
                  'No Vehicles Added',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Add your bike or car to get started.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddEditVehicleScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    shadowColor: AppColors.primaryLight.withOpacity(0.4),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Vehicle'),
                ).animate().shimmer(delay: 1.seconds, duration: 1.seconds),
              ],
            ),
          );
        }

        final vehicle = service.vehicles.first; 

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Bottom padding for nav/fab
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              GlassCard(
                borderRadius: 28,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryLight.withOpacity(0.2), width: 2),
                        boxShadow: [
                          BoxShadow(color: AppColors.primaryLight.withOpacity(0.2), blurRadius: 20)
                        ]
                      ),
                      child: Icon(
                        vehicle.type == 'Car' ? Icons.directions_car_rounded : Icons.two_wheeler_rounded,
                        size: 40,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${vehicle.make} ${vehicle.model} (${vehicle.year})',
                            style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded),
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
              ).animate().slideY(begin: -0.2, end: 0, duration: 500.ms),
              
              const SizedBox(height: 24),

              // Identity Grid
              const Text('Identity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)).animate().fadeIn().moveX(),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildInfoCard(context, 'License Plate', vehicle.licensePlate, Icons.pin_outlined),
                  _buildInfoCard(context, 'Color', vehicle.color, Icons.palette_outlined),
                  _buildInfoCard(context, 'VIN / Chassis', vehicle.vin, Icons.fingerprint),
                  _buildInfoCard(context, 'Engine No.', vehicle.engineNumber, Icons.engineering_outlined),
                ],
              ),
              const SizedBox(height: 24),

              // Specs Section
              const Text('Specifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)).animate().fadeIn(delay: 200.ms).moveX(),
              const SizedBox(height: 12),
               GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 8),
                borderRadius: 20,
                child: Column(
                  children: [
                    _buildSpecRole(context, 'Tyre Pressure', vehicle.tyrePressure ?? 'N/A', Icons.air_rounded),
                    Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.1)),
                    _buildSpecRole(context, 'Engine Oil', vehicle.oilType ?? 'N/A', Icons.opacity_rounded),
                    Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.1)),
                    _buildSpecRole(context, 'Fuel Capacity', vehicle.fuelCapacity != null ? '${vehicle.fuelCapacity} L' : 'N/A', Icons.local_gas_station_rounded),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

              if (vehicle.notes != null && vehicle.notes!.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                GlassCard(
                  borderRadius: 20,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Text(vehicle.notes!),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Actions
              GlassCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    _buildActionRow(context, 'Service History', Icons.history_rounded, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceHistoryScreen(vehicle: vehicle)));
                    }),
                    Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.1)),
                    _buildActionRow(context, 'Fuel Tracker', Icons.local_gas_station_rounded, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => FuelHistoryScreen(vehicle: vehicle)));
                    }),
                    Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.1)),
                    _buildActionRow(context, 'Maintenance Reminders', Icons.notifications_active_rounded, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => RemindersScreen(vehicle: vehicle)));
                    }),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(BuildContext context, String label, String value, IconData icon) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 16,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryLight),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7))),
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
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)
        ),
        child: Icon(icon, color: AppColors.primaryLight, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Text(
        value, 
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.accentLight.withOpacity(0.2), AppColors.primaryLight.withOpacity(0.1)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.accentLight, size: 22),
              ),
              const SizedBox(width: 16),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

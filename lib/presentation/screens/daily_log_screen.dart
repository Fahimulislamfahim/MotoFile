import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/vehicle_service.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/models/daily_log_model.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/premium_background.dart';
import '../widgets/premium_app_bar.dart';
import '../widgets/glass_card.dart';

class DailyLogScreen extends StatefulWidget {
  final Vehicle vehicle;

  const DailyLogScreen({super.key, required this.vehicle});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  late List<DateTime> _dates;
  late ScrollController _scrollController;
  DateTime _selectedDate = DateTime.now();
  
  List<DailyLog> _logs = [];
  bool _isLoading = true;

  final _odoController = TextEditingController();
  final _fuelController = TextEditingController();

  DailyLog? _currentLog;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    // Generate dates: 60 days past, 15 days future
    _dates = List.generate(75, (index) => today.subtract(Duration(days: 60 - index)));
    
    // Approximate scroll position to center "today" (index 60)
    // We will adjust it in a post frame callback
    _scrollController = ScrollController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Each date item is roughly 64 wide + 16 padding = 80
        final screenWidth = MediaQuery.of(context).size.width;
        _scrollController.jumpTo((60 * 76.0) - (screenWidth / 2) + 38);
      }
      _loadLogs();
    });
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final service = Provider.of<VehicleService>(context, listen: false);
    _logs = await service.getDailyLogs(widget.vehicle.id!);
    
    // Sort ascending by date
    _logs.sort((a, b) => a.date.compareTo(b.date));
    
    _populateFieldsForSelectedDate();
    setState(() => _isLoading = false);
  }

  void _populateFieldsForSelectedDate() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    try {
      _currentLog = _logs.firstWhere((log) => log.date == dateStr);
      _odoController.text = _currentLog!.odometer.toString();
      _fuelController.text = _currentLog!.fuelAdded != null ? _currentLog!.fuelAdded.toString() : '';
    } catch (e) {
      _currentLog = null;
      _odoController.clear();
      _fuelController.clear();
    }
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _populateFieldsForSelectedDate();
  }

  void _selectDateAndScroll(DateTime date) {
    setState(() {
      _selectedDate = date;
      _dates = List.generate(75, (index) => date.subtract(Duration(days: 60 - index)));
    });
    _populateFieldsForSelectedDate();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final screenWidth = MediaQuery.of(context).size.width;
        _scrollController.animateTo(
          (60 * 76.0) - (screenWidth / 2) + 38,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _goToToday() {
    _selectDateAndScroll(DateTime.now());
  }

  Future<void> _openDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primaryLight,
              onPrimary: Colors.white,
              surface: Theme.of(context).cardColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _selectDateAndScroll(picked);
    }
  }

  Future<void> _saveLog() async {
    final odoText = _odoController.text;
    final fuelText = _fuelController.text;

    if (odoText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter odometer reading')),
      );
      return;
    }

    final odometer = int.tryParse(odoText) ?? 0;
    final fuelAdded = fuelText.isNotEmpty ? double.tryParse(fuelText) : null;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final isToday = dateStr == DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // Only capture time if they are editing/adding today's log, or optionally handle past times. Let's just capture current time.
    final timeStr = DateFormat('HH:mm:ss').format(DateTime.now());

    final log = DailyLog(
      id: _currentLog?.id,
      vehicleId: widget.vehicle.id!,
      date: dateStr,
      time: timeStr,
      odometer: odometer,
      fuelAdded: fuelAdded,
    );

    final service = Provider.of<VehicleService>(context, listen: false);
    await service.saveDailyLog(log);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Daily log saved!')),
    );
    
    _loadLogs(); // Reload data
  }

  int _calculateDistanceForSelectedDay() {
    if (_currentLog == null) return 0;
    
    // Find the closest log before the selected date
    final selectedLogIndex = _logs.indexOf(_currentLog!);
    if (selectedLogIndex > 0) {
      final prevLog = _logs[selectedLogIndex - 1];
      return _currentLog!.odometer - prevLog.odometer;
    }
    return 0; // if no previous log found
  }

  double? _calculateMileageForSelectedDay() {
    if (_currentLog == null || _currentLog!.fuelAdded == null || _currentLog!.fuelAdded! <= 0) return null;
    
    final dist = _calculateDistanceForSelectedDay();
    if (dist <= 0) return null;
    
    return dist / _currentLog!.fuelAdded!;
  }

  @override
  Widget build(BuildContext context) {
    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now());

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PremiumAppBar(title: 'Daily Log & Calendar'),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: _openDatePicker,
                            icon: Icon(Icons.calendar_month_rounded, color: AppColors.primaryLight),
                            label: Text(
                              DateFormat('MMMM yyyy').format(_selectedDate),
                              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          TextButton(
                            onPressed: _goToToday,
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.primaryLight.withOpacity(0.1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: Text('Today', style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    // Calendar Strip
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: _dates.length,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final date = _dates[index];
                          final isSelected = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(_selectedDate);
                          final isCurrentDay = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(DateTime.now());
                          final hasLog = _logs.any((l) => l.date == DateFormat('yyyy-MM-dd').format(date));

                          return GestureDetector(
                            onTap: () => _selectDate(date),
                            child: Container(
                              width: 60,
                              margin: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? AppColors.primaryLight 
                                    : (isCurrentDay ? AppColors.primaryLight.withOpacity(0.2) : Theme.of(context).cardColor.withOpacity(0.5)),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isCurrentDay && !isSelected 
                                      ? AppColors.primaryLight 
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(color: AppColors.primaryLight.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))
                                ] : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('MMM').format(date).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('d').format(date),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('E').format(date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected ? Colors.white70 : Colors.grey,
                                    ),
                                  ),
                                  if (hasLog)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected ? Colors.white : AppColors.accentLight,
                                      ),
                                    )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ).animate().fadeIn().slideX(begin: 0.1),

                    const SizedBox(height: 32),

                    // Inputs
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GlassCard(
                        borderRadius: 32,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isToday ? "Today's Log" : "Log for ${DateFormat('MMMM d, yyyy').format(_selectedDate)}",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (_currentLog != null && _currentLog!.time != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.withOpacity(0.8)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Last saved at: ${_formatTime(_currentLog!.time!)}',
                                    style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 24),
                            // Odometer Input
                            TextField(
                              controller: _odoController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Odometer (km)',
                                prefixIcon: Icon(Icons.speed_rounded, color: AppColors.primaryLight),
                                filled: true,
                                fillColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Fuel Input (Optional)
                            TextField(
                              controller: _fuelController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Fuel Added (Liters) - Optional',
                                prefixIcon: Icon(Icons.local_gas_station_rounded, color: AppColors.accentLight),
                                filled: true,
                                fillColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _saveLog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryLight,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 8,
                                ),
                                icon: const Icon(Icons.save_rounded),
                                label: const Text('Save Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    ),

                    const SizedBox(height: 24),

                    // Analytics Section
                    if (_currentLog != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GlassCard(
                          borderRadius: 32,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.analytics_rounded, color: AppColors.success),
                                  const SizedBox(width: 8),
                                  Text("Daily Analytics", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem('Distance', '${_calculateDistanceForSelectedDay()} km', Icons.route_rounded, AppColors.primaryLight),
                                  _buildStatItem('Mileage', _calculateMileageForSelectedDay() != null ? '${_calculateMileageForSelectedDay()!.toStringAsFixed(1)} km/L' : 'N/A', Icons.eco_rounded, AppColors.success),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 14)),
      ],
    );
  }

  String _formatTime(String timeStr) {
    try {
      final parsedTime = DateFormat('HH:mm:ss').parse(timeStr);
      return DateFormat('hh:mm a').format(parsedTime);
    } catch (e) {
      return timeStr;
    }
  }
}

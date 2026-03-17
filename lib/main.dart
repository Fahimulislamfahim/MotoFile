import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:home_widget/home_widget.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/daily_log_screen.dart';
import 'core/services/notification_service.dart';

import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_service.dart';
import 'core/services/vehicle_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => VehicleService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  @override
  void initState() {
    super.initState();
    _initQuickActions();
    _initHomeWidget();
    _syncWidgetData();
  }

  void _syncWidgetData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
       final vehicleService = Provider.of<VehicleService>(context, listen: false);
       vehicleService.loadVehicles().then((_) {
         if (vehicleService.vehicles.isNotEmpty) {
           vehicleService.updateWidgetStats(vehicleService.vehicles.first.id!);
         }
       });
    });
  }

  void _initHomeWidget() {
    HomeWidget.setAppGroupId('com.vynix.motofile');
    
    // Check if app was launched directly from the widget
    HomeWidget.initiallyLaunchedFromHomeWidget().then((Uri? uri) {
      if (uri != null && uri.scheme == 'motofile' && uri.host == 'add_log') {
        _navigateLogScreen();
      }
    });

    // Listen to widget clicks when app is in background
    HomeWidget.widgetClicked.listen((Uri? uri) {
      if (uri != null && uri.scheme == 'motofile' && uri.host == 'add_log') {
        _navigateLogScreen();
      }
    });
  }

  void _navigateLogScreen() {
    Future.delayed(const Duration(milliseconds: 800), () async {
      final context = navigatorKey.currentContext;
      if (context != null) {
        final vehicleService = Provider.of<VehicleService>(context, listen: false);
        if (vehicleService.vehicles.isEmpty) {
          await vehicleService.loadVehicles();
        }
        if (vehicleService.vehicles.isNotEmpty) {
           Navigator.push(
             context,
             MaterialPageRoute(
               builder: (context) => DailyLogScreen(vehicle: vehicleService.vehicles.first),
             ),
           );
        }
      }
    });
  }

  void _initQuickActions() {
    const QuickActions quickActions = QuickActions();
    quickActions.initialize((String shortcutType) {
      if (shortcutType == 'add_daily_log') {
        _navigateLogScreen();
      }
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'add_daily_log',
        localizedTitle: 'Add Daily Log',
        icon: 'ic_launcher',
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'MotoFile',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          themeAnimationDuration: const Duration(milliseconds: 500),
          themeAnimationCurve: Curves.easeInOut,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(),
            scrollbars: false,
          ),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(0.9),
              ),
              child: child!,
            );
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}

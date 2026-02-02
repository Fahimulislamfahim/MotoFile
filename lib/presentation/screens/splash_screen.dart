import 'package:flutter/material.dart';
import '../../core/services/biometric_auth_service.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final BiometricAuthService _authService = BiometricAuthService();
  String _message = 'Tap to Unlock';

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Small delay to let UI render
    await Future.delayed(const Duration(milliseconds: 500));
    bool authenticated = await _authService.authenticate();
    if (authenticated) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      setState(() {
        _message = 'Authentication Failed. Tap to retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fingerprint, size: 80, color: Theme.of(context).primaryColor),
            const SizedBox(height: 20),
            Text(
              'MotoFile Locked',
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _checkAuth,
              child: Text(
                _message,
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

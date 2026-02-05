import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/biometric_auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/premium_background.dart';
import '../widgets/glass_card.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final BiometricAuthService _authService = BiometricAuthService();
  String _message = 'Tap to Unlock';
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Delay for animation
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    
    setState(() => _isAuthenticating = true);
    
    bool authenticated = await _authService.authenticate();
    
    if (authenticated) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (c, a1, a2) => const HomeScreen(),
            transitionsBuilder: (c, a1, a2, child) => FadeTransition(opacity: a1, child: child),
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _message = 'Authentication Failed. Tap to retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassCard(
                borderRadius: 200,
                padding: const EdgeInsets.all(40),
                child: Icon(
                  Icons.fingerprint_rounded, 
                  size: 80, 
                  color: AppColors.primaryLight
                ),
              ).animate()
              .scale(duration: 800.ms, curve: Curves.easeOutBack)
              .shimmer(delay: 1.seconds, duration: 1.5.seconds),
              
              const SizedBox(height: 40),
              
              Text(
                'MotoFile',
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.5, end: 0),
              
              const SizedBox(height: 16),
              
              Text(
                'Premium Document Manager',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  letterSpacing: 1.2,
                ),
              ).animate().fadeIn(delay: 500.ms),
              
              const SizedBox(height: 60),
              
              GestureDetector(
                onTap: _isAuthenticating ? null : _checkAuth,
                child: AnimatedOpacity(
                  opacity: _isAuthenticating ? 0.5 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      _isAuthenticating ? 'Authenticating...' : _message,
                      style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

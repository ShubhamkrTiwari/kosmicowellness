import 'package:flutter/material.dart';
import 'dart:async';
import 'onboarding_screen.dart';
import 'maintenance_screen.dart';
import '../services/api_service.dart';
import '../managers/user_manager.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _rocketController;
  late Animation<double> _rocketAnimation;

  @override
  void initState() {
    super.initState();
    
    _rocketController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _rocketAnimation = Tween<double>(begin: 0, end: -20).animate(
      CurvedAnimation(parent: _rocketController, curve: Curves.easeInOut),
    );

    _startAppFlow();
  }

  Future<void> _startAppFlow() async {
    // 1. Start waking up the server
    ApiService.wakeUpServer();

    // 2. Check for Maintenance (takes 1-3 seconds as requested)
    bool isMaintenance = await ApiService.checkMaintenanceMode();
    
    if (isMaintenance && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MaintenanceScreen()),
      );
      return;
    }

    // 3. Normal delay for Splash Screen feel
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 4. Check if user is already logged in
    final userManager = UserManager();
    await userManager.init();

    if (userManager.isLoggedIn) {
      debugPrint('SplashScreen: User logged in, navigating to Home');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(title: 'Kosmico Wellness Private Limited'),
        ),
      );
    } else {
      debugPrint('SplashScreen: User not logged in, navigating to Onboarding');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  void dispose() {
    _rocketController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.8),
              colorScheme.secondary.withOpacity(0.2),
            ],
          ),
        ),
        child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo from Assets
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Image.asset(
                  'assets/images/kosmicologo.png',
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.spa,
                    size: 80,
                    color: colorScheme.secondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'KOSMICO',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            Text(
              'WELLNESS',
              style: TextStyle(
                color: colorScheme.secondary.withOpacity(0.8),
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 60),
            
            // Rocket Animation instead of CircularProgressIndicator
            AnimatedBuilder(
              animation: _rocketAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _rocketAnimation.value),
                  child: Column(
                    children: [
                      Icon(
                        Icons.rocket_launch,
                        size: 40,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Launching Kosmico...',
                        style: TextStyle(
                          color: colorScheme.onPrimary.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
    );
  }
}

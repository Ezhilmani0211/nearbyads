import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    _checkLoginSession();
  }

  Future<void> _checkLoginSession() async {
    await Future.delayed(
      const Duration(seconds: 3),
    );

    if (!mounted) return;

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    final bool isLoggedIn =
        prefs.getBool('is_logged_in') ?? false;

    final String token =
        prefs.getString('token') ?? '';

    final String role =
        prefs.getString('user_role') ?? 'user';

    debugPrint(
      'SPLASH SESSION => '
      'isLoggedIn=$isLoggedIn, '
      'tokenExists=${token.isNotEmpty}, '
      'role=$role',
    );

    // Admin session should NEVER be restored
    // after the app is closed/reopened.
    if (role == 'admin') {
      await prefs.remove('is_logged_in');
      await prefs.remove('token');
      await prefs.remove('access_token');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('user_role');

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/login-selection',
      );

      return;
    }

    // User / Shop Owner session restoration
    if (isLoggedIn && token.isNotEmpty) {
      if (role == 'shop_owner') {
        Navigator.pushReplacementNamed(
          context,
          '/owner-dashboard',
          arguments:
              prefs.getString('user_email') ?? '',
        );
      } else {
        Navigator.pushReplacementNamed(
          context,
          '/home',
        );
      }
    } else {
      Navigator.pushReplacementNamed(
        context,
        '/login-selection',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.25,
                    ),
                    blurRadius: 25,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on_rounded,
                size: 70,
                color: Color(0xFF1976D2),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'NearbyAds',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Discover Shops Near You',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 35),

            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor:
                    AlwaysStoppedAnimation<Color>(
                  Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
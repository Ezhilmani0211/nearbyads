
import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'screens/login_selection_screen.dart';
import 'screens/user_login_screen.dart';
import 'screens/user_register_screen.dart';
import 'screens/owner_login_screen.dart';
import 'screens/owner_register_screen.dart';
import 'screens/owner_dashboard_screen.dart';
import 'screens/home_screen.dart';

import 'screens/add_shop_screen.dart';
import 'screens/my_shops_screen.dart';
import 'screens/add_advertisement_screen.dart';
import 'screens/my_ads_screen.dart';
import 'screens/approval_status_screen.dart';

import 'screens/email_verification_screen.dart';

// PROFILE
import 'screens/edit_profile_screen.dart';
import 'screens/change_password_screen.dart';

// ADMIN
import 'screens/admin_login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_pending_shops_screen.dart';
import 'screens/admin_pending_ads_screen.dart';
import 'screens/admin_users_screen.dart';
import 'screens/admin_approved_shops_screen.dart';
import 'screens/admin_approved_ads_screen.dart';
import 'screens/admin_analytics_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const NearbyAdsApp());
}

class NearbyAdsApp extends StatelessWidget {
  const NearbyAdsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NearbyAds',

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
        ),

        scaffoldBackgroundColor: Colors.white,

        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF0D47A1),
          foregroundColor: Colors.white,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF7F9FC),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFE0E6EF),
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF1976D2),
              width: 2,
            ),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            minimumSize: const Size(
              double.infinity,
              50,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      initialRoute: '/',

      routes: {
        // -------------------------
        // SPLASH
        // -------------------------
        '/': (context) =>
            const SplashScreen(),

        // -------------------------
        // LOGIN SELECTION
        // -------------------------
        '/login-selection': (context) =>
            const LoginSelectionScreen(),

        // -------------------------
        // USER
        // -------------------------
        '/user-login': (context) =>
            const UserLoginScreen(),

        '/user-register': (context) =>
            const UserRegisterScreen(),

        // -------------------------
        // PROFILE
        // -------------------------
        '/edit-profile': (context) =>
            const EditProfileScreen(),

        '/change-password': (context) =>
            const ChangePasswordScreen(),

        // -------------------------
        // SHOP OWNER
        // -------------------------
        '/owner-login': (context) =>
            const OwnerLoginScreen(),

        '/owner-register': (context) =>
            const OwnerRegisterScreen(),

        // -------------------------
        // ADMIN
        // -------------------------
        '/admin-login': (context) =>
            const AdminLoginScreen(),

        '/admin-dashboard': (context) =>
            const AdminDashboardScreen(),

        '/admin-pending-shops': (context) =>
            const AdminPendingShopsScreen(),

        '/admin-approved-shops': (context) =>
            const AdminApprovedShopsScreen(),

        '/admin-pending-ads': (context) =>
            const AdminPendingAdsScreen(),

        '/admin-approved-ads': (context) =>
            const AdminApprovedAdsScreen(),

        '/admin-users': (context) =>
            const AdminUsersScreen(),

        '/admin-analytics': (context) =>
            const AdminAnalyticsScreen(),

        // -------------------------
        // EMAIL VERIFICATION
        // -------------------------
        '/email-verification': (context) {
          final args =
              ModalRoute.of(context)
                  ?.settings
                  .arguments
                  as Map<String, dynamic>?;

          final String email =
              args?['email']?.toString() ?? '';

          final String role =
              args?['role']?.toString() ?? 'user';

          return EmailVerificationScreen(
            email: email,
            role: role,
          );
        },

        // -------------------------
        // OWNER DASHBOARD
        // -------------------------
        '/owner-dashboard': (context) {
          final String ownerEmail =
              (ModalRoute.of(context)
                      ?.settings
                      .arguments
                      as String?) ??
                  '';

          return OwnerDashboardScreen(
            ownerEmail: ownerEmail,
          );
        },

        // -------------------------
        // USER HOME
        // -------------------------
        '/home': (context) =>
            const HomeScreen(),

        // -------------------------
        // SHOP MANAGEMENT
        // -------------------------
        '/add-shop': (context) =>
            const AddShopScreen(),

        '/my-shops': (context) {
          final String ownerEmail =
              (ModalRoute.of(context)
                      ?.settings
                      .arguments
                      as String?) ??
                  '';

          return MyShopsScreen(
            ownerEmail: ownerEmail,
          );
        },

        // -------------------------
        // ADVERTISEMENT
        // -------------------------
        '/add-advertisement': (context) {
          final String ownerEmail =
              (ModalRoute.of(context)
                      ?.settings
                      .arguments
                      as String?) ??
                  '';

          return AddAdvertisementScreen(
            ownerEmail: ownerEmail,
          );
        },

        '/my-ads': (context) {
          final String ownerEmail =
              (ModalRoute.of(context)
                      ?.settings
                      .arguments
                      as String?) ??
                  '';

          return MyAdsScreen(
            ownerEmail: ownerEmail,
          );
        },

        // -------------------------
        // APPROVAL STATUS
        // -------------------------
        '/approval-status': (context) =>
            const ApprovalStatusScreen(),
      },
    );
  }
}


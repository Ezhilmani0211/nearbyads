import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() =>
      _AdminLoginScreenState();
}

class _AdminLoginScreenState
    extends State<AdminLoginScreen> {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (isLoading) return;

    final String email =
        emailController.text.trim();

    final String password =
        passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please enter email and password'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.login(
        email: email,
        password: password,
      );

      final String role =
          response['user']?['role']?.toString() ?? '';

      // -------------------------------------------------------
      // ADMIN ROLE CHECK
      // -------------------------------------------------------

      if (role != 'admin') {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('This account is not an admin account'),
          ),
        );

        return;
      }

      // -------------------------------------------------------
      // SAVE ADMIN SESSION
      // -------------------------------------------------------

      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      final String token =
          response['access_token']?.toString() ?? '';

      final String userName =
          response['user']?['full_name']?.toString() ?? '';

      final String userEmail =
          response['user']?['email']?.toString() ?? email;

      await prefs.setString(
        'token',
        token,
      );

      await prefs.setString(
        'access_token',
        token,
      );

      await prefs.setString(
        'user_name',
        userName,
      );

      await prefs.setString(
        'user_email',
        userEmail,
      );

      await prefs.setString(
        'user_role',
        'admin',
      );

      await prefs.setBool(
        'is_logged_in',
        true,
      );

      if (!mounted) return;

      // -------------------------------------------------------
      // GO TO ADMIN DASHBOARD
      // -------------------------------------------------------

      Navigator.pushReplacementNamed(
        context,
        '/admin-dashboard',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text('Admin Login'),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,

            children: [
              const SizedBox(height: 35),

              const Icon(
                Icons.admin_panel_settings_rounded,
                size: 80,
                color: Color(0xFF1976D2),
              ),

              const SizedBox(height: 20),

              const Text(
                'Admin Login',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Login to your administrator account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 35),

              TextField(
                controller: emailController,
                keyboardType:
                    TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon:
                      Icon(Icons.email_outlined),
                ),
              ),

              const SizedBox(height: 18),

              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon:
                      const Icon(Icons.lock_outline),

                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePassword =
                            !obscurePassword;
                      });
                    },
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons
                              .visibility_off_outlined,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 50,

                child: ElevatedButton.icon(
                  onPressed:
                      isLoading ? null : login,

                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<
                                    Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.login),

                  label: Text(
                    isLoading
                        ? 'Logging in...'
                        : 'Login',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
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
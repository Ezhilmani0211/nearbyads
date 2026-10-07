import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _newPasswordController =
      TextEditingController();

  final _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String _email = '';

  static const Color primaryBlue =
      Color(0xFF1976D2);

  static const Color darkBlue =
      Color(0xFF0D47A1);

  static const Color lightBlue =
      Color(0xFFE3F2FD);

  static const Color purple =
      Color(0xFF7B1FA2);

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final prefs =
        await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _email =
          prefs.getString('user_email') ?? '';
    });
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'User email not found',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await ApiService.changePassword(
        email: _email,
        currentPassword: '',
        newPassword:
            _newPasswordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message'] ??
                'Password changed successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );

      _newPasswordController.clear();
      _confirmPasswordController.clear();

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      final message = e
          .toString()
          .replaceFirst(
            'Exception: ',
            '',
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      labelText: label,

      prefixIcon: Icon(
        icon,
        color: primaryBlue,
      ),

      suffixIcon: IconButton(
        icon: Icon(
          obscureText
              ? Icons.visibility_off
              : Icons.visibility,
          color: Colors.grey,
        ),
        onPressed: onToggle,
      ),

      filled: true,

      fillColor:
          const Color(0xFFF7F9FC),

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide:
            const BorderSide(
          color: Color(0xFFE0E6EF),
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide:
            const BorderSide(
          color: primaryBlue,
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F9FF),

      appBar: AppBar(
        title: const Text(
          'Change Password',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),

          child: Form(
            key: _formKey,

            child: Column(
              children: [

                // =========================
                // HEADER
                // =========================

                Container(
                  width: double.infinity,

                  padding:
                      const EdgeInsets.all(22),

                  decoration:
                      BoxDecoration(
                    gradient:
                        const LinearGradient(
                      colors: [
                        primaryBlue,
                        purple,
                      ],
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),

                  child: const Column(
                    children: [

                      CircleAvatar(
                        radius: 32,
                        backgroundColor:
                            Colors.white,

                        child: Icon(
                          Icons.lock_outline,
                          size: 34,
                          color:
                              primaryBlue,
                        ),
                      ),

                      SizedBox(height: 12),

                      Text(
                        'Update Your Password',
                        style: TextStyle(
                          color:
                              Colors.white,
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 6),

                      Text(
                        'Keep your NearbyAds account secure',
                        textAlign:
                            TextAlign.center,

                        style: TextStyle(
                          color:
                              Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // =========================
                // NEW PASSWORD
                // =========================

                TextFormField(
                  controller:
                      _newPasswordController,

                  obscureText:
                      _obscureNew,

                  decoration:
                      _inputDecoration(
                    label:
                        'New Password',

                    icon:
                        Icons.lock_reset,

                    obscureText:
                        _obscureNew,

                    onToggle: () {
                      setState(() {
                        _obscureNew =
                            !_obscureNew;
                      });
                    },
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return
                          'Enter a new password';
                    }

                    if (value.length < 6) {
                      return
                          'Password must contain at least 6 characters';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // =========================
                // CONFIRM PASSWORD
                // =========================

                TextFormField(
                  controller:
                      _confirmPasswordController,

                  obscureText:
                      _obscureConfirm,

                  decoration:
                      _inputDecoration(
                    label:
                        'Confirm New Password',

                    icon:
                        Icons
                            .verified_user_outlined,

                    obscureText:
                        _obscureConfirm,

                    onToggle: () {
                      setState(() {
                        _obscureConfirm =
                            !_obscureConfirm;
                      });
                    },
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return
                          'Confirm your new password';
                    }

                    if (value !=
                        _newPasswordController
                            .text) {
                      return
                          'Passwords do not match';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // =========================
                // INFO
                // =========================

                Container(
                  width: double.infinity,

                  padding:
                      const EdgeInsets.all(16),

                  decoration:
                      BoxDecoration(
                    color: lightBlue,

                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),

                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Icon(
                        Icons.info_outline,
                        color:
                            primaryBlue,
                      ),

                      SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'Your new password must contain at least 6 characters.',

                          style: TextStyle(
                            color:
                                darkBlue,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // =========================
                // UPDATE BUTTON
                // =========================

                SizedBox(
                  width: double.infinity,
                  height: 52,

                  child: ElevatedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : _changePassword,

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          primaryBlue,

                      foregroundColor:
                          Colors.white,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),

                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,

                            child:
                                CircularProgressIndicator(
                              color:
                                  Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Update Password',

                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
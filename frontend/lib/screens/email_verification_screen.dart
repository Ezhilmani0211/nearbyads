import 'package:flutter/material.dart';

import '../services/api_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String role;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.role,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends State<EmailVerificationScreen> {
  final TextEditingController _codeController =
      TextEditingController();

  bool _isLoading = false;
  bool _isResending = false;

  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color purple = Color(0xFF7B1FA2);

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      _showMessage(
        'Please enter the verification code',
        isError: true,
      );
      return;
    }

    if (code.length != 6) {
      _showMessage(
        'Verification code must be 6 digits',
        isError: true,
      );
      return;
    }

    if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) {
      _showMessage(
        'Please enter a valid 6-digit code',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.verifyEmail(
        email: widget.email,
        verificationCode: code,
      );

      if (!mounted) return;

      // ApiService throws an exception for non-2xx responses.
      // Therefore, reaching here means verification succeeded.
      _showMessage(
        response['message']?.toString() ??
            'Email verified successfully',
      );

      await Future.delayed(
        const Duration(milliseconds: 800),
      );

      if (!mounted) return;

      if (widget.role == 'shop_owner') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/owner-login',
          (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/user-login',
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    if (_isResending) return;

    setState(() {
      _isResending = true;
    });

    try {
      final response =
          await ApiService.resendVerificationCode(
        email: widget.email,
      );

      if (!mounted) return;

      // ApiService throws an exception for non-2xx responses.
      // Therefore, reaching here means resend succeeded.
      _codeController.clear();

      _showMessage(
        response['message']?.toString() ??
            'Verification code sent again',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFD32F2F)
            : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 30),

              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      primaryBlue,
                      purple,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(
                        alpha: 0.20,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: Colors.white,
                  size: 45,
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222222),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'We have sent a 6-digit verification code to',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF757575),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: primaryBlue,
                ),
              ),

              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.06,
                      ),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: Color(0xFF222222),
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '000000',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          letterSpacing: 8,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: primaryBlue,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7F9FC),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E6EF),
                          ),
                        ),
                        focusedBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: primaryBlue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading ? null : _verifyEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 23,
                                width: 23,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Verify Email',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Didn't receive the code? ",
                          style: TextStyle(
                            color: Color(0xFF757575),
                          ),
                        ),
                        TextButton(
                          onPressed: _isResending
                              ? null
                              : _resendCode,
                          child: _isResending
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: primaryBlue,
                                  ),
                                )
                              : const Text(
                                  'Resend Code',
                                  style: TextStyle(
                                    color: primaryBlue,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: primaryBlue,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Check your inbox and spam folder for the verification email.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF444444),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}
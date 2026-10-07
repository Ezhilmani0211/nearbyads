import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    final String name =
        prefs.getString('user_name') ?? '';

    final String email =
        prefs.getString('user_email') ?? '';

    if (!mounted) return;

    setState(() {
      nameController.text = name;
      emailController.text = email;
      isLoading = false;
    });
  }

  Future<void> saveProfile() async {
    final String name =
        nameController.text.trim();

    final String email =
        emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter name and email',
          ),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'user_name',
      name,
    );

    await prefs.setString(
      'user_email',
      email,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Profile updated successfully',
        ),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),

      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1976D2),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // PROFILE CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1976D2),
                            Color(0xFF7B1FA2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius:
                            BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1976D2)
                                .withValues(alpha: 0.18),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: 0.12),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 48,
                              color: Color(0xFF1976D2),
                            ),
                          ),

                          const SizedBox(height: 14),

                          const Text(
                            'Edit Your Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),

                          const Text(
                            'Update your account information',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // PERSONAL DETAILS CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // NAME
                          TextField(
                            controller: nameController,
                            textInputAction:
                                TextInputAction.next,
                            decoration:
                                InputDecoration(
                              labelText: 'Name',
                              hintText:
                                  'Enter your name',
                              prefixIcon:
                                  const Icon(
                                Icons.person_outline,
                                color:
                                    Color(0xFF1976D2),
                              ),
                              filled: true,
                              fillColor:
                                  const Color(0xFFF7F9FC),
                              border:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  14,
                                ),
                                borderSide:
                                    BorderSide.none,
                              ),
                              enabledBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  14,
                                ),
                                borderSide:
                                    const BorderSide(
                                  color:
                                      Color(0xFFD6E4F5),
                                ),
                              ),
                              focusedBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  14,
                                ),
                                borderSide:
                                    const BorderSide(
                                  color:
                                      Color(0xFF1976D2),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // EMAIL
                          TextField(
                            controller:
                                emailController,
                            keyboardType:
                                TextInputType
                                    .emailAddress,
                            textInputAction:
                                TextInputAction.done,
                            decoration:
                                InputDecoration(
                              labelText: 'Email',
                              hintText:
                                  'Enter your email',
                              prefixIcon:
                                  const Icon(
                                Icons.email_outlined,
                                color:
                                    Color(0xFF1976D2),
                              ),
                              filled: true,
                              fillColor:
                                  const Color(0xFFF7F9FC),
                              border:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  14,
                                ),
                                borderSide:
                                    BorderSide.none,
                              ),
                              enabledBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  14,
                                ),
                                borderSide:
                                    const BorderSide(
                                  color:
                                      Color(0xFFD6E4F5),
                                ),
                              ),
                              focusedBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  14,
                                ),
                                borderSide:
                                    const BorderSide(
                                  color:
                                      Color(0xFF1976D2),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: saveProfile,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF1976D2),
                          foregroundColor:
                              Colors.white,
                          elevation: 2,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // CANCEL BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              const Color(0xFF1976D2),
                          side: const BorderSide(
                            color: Color(0xFF1976D2),
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
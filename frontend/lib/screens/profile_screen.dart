
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'change_password_screen.dart';

import 'home_screen.dart';
import 'offers_screen.dart';
import 'favorites_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  String _name = 'User';
  String _email = '';
  String _role = 'user';

  static const Color primaryBlue =
      Color(0xFF1976D2);

  static const Color darkBlue =
      Color(0xFF0D47A1);

  static const Color purple =
      Color(0xFF7B1FA2);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs =
        await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _name =
          prefs.getString('user_name') ??
              'User';

      _email =
          prefs.getString('user_email') ??
              '';

      _role =
          prefs.getString('user_role') ??
              'user';
    });
  }

  Future<void> _openEditProfile() async {
    final result = await Navigator.pushNamed(
      context,
      '/edit-profile',
    );

    if (result == true) {
      await _loadProfile();
    } else {
      await _loadProfile();
    }
  }

  Future<void> _openChangePassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ChangePasswordScreen(),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('access_token');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
    await prefs.remove('user_id');
    await prefs.remove('is_logged_in');

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login-selection',
      (route) => false,
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: darkBlue,
        ),
      ),
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = primaryBlue,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color:
                iconColor.withValues(alpha: 0.10),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F9FF),
      body: SafeArea(
        child: Column(
          children: [
            // =========================
            // TOP PROFILE CARD
            // =========================

            Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(
                    colors: [
                      darkBlue,
                      primaryBlue,
                      purple,
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 34,
                          backgroundColor:
                              Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 38,
                            color: primaryBlue,
                          ),
                        ),
                        const SizedBox(
                          width: 14,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                _name,
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize: 19,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                _email,
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                _role.replaceAll(
                                  '_',
                                  ' ',
                                ).toUpperCase(),
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Edit Button
                    SizedBox(
                      width: double.infinity,
                      child:
                          OutlinedButton.icon(
                        onPressed:
                            _openEditProfile,
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                        ),
                        label: const Text(
                          'Edit Profile',
                        ),
                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              Colors.white,
                          side:
                              const BorderSide(
                            color:
                                Colors.white70,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // =========================
            // MENU
            // =========================

            Expanded(
              child:
                  SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ACCOUNT
                    _sectionTitle(
                      'Account',
                    ),

                    _menuCard(
                      icon:
                          Icons.favorite_outline,
                      title:
                          'My Favorites',
                      subtitle:
                          'View your saved shops',
                      iconColor:
                          purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    const FavoritesScreen(),
                          ),
                        );
                      },
                    ),

                    _menuCard(
                      icon:
                          Icons.lock_reset,
                      title:
                          'Change Password',
                      subtitle:
                          'Update your account password',
                      iconColor:
                          primaryBlue,
                      onTap:
                          _openChangePassword,
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    // LOGOUT
                    _sectionTitle(
                      'Account Actions',
                    ),

                    _menuCard(
                      icon:
                          Icons.logout,
                      title:
                          'Logout',
                      subtitle:
                          'Sign out from NearbyAds',
                      iconColor:
                          Colors.red,
                      onTap:
                          _logout,
                    ),

                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // =========================
      // BOTTOM NAVIGATION
      // =========================

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: 3,
        type:
            BottomNavigationBarType.fixed,
        selectedItemColor:
            primaryBlue,
        unselectedItemColor:
            Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const HomeScreen(),
              ),
            );
          }

          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const OffersScreen(),
              ),
            );
          }

          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const FavoritesScreen(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.map_outlined,
            ),
            activeIcon: Icon(
              Icons.map,
            ),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.local_offer_outlined,
            ),
            activeIcon: Icon(
              Icons.local_offer,
            ),
            label: 'Offers',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.favorite_outline,
            ),
            activeIcon: Icon(
              Icons.favorite,
            ),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person_outline,
            ),
            activeIcon: Icon(
              Icons.person,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

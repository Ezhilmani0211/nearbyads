
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('access_token');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
    await prefs.remove('user_id');
    await prefs.remove('is_logged_in');

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login-selection',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome, Admin',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Manage shops, advertisements and users',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 25),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.92,
              children: [
                _dashboardCard(
                  context,
                  icon: Icons.store,
                  title: 'Pending Shops',
                  subtitle:
                      'Review shop requests',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/admin-pending-shops',
                    );
                  },
                ),

                _dashboardCard(
                  context,
                  icon: Icons.verified,
                  title: 'Approved Shops',
                  subtitle:
                      'View approved shops',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/admin-approved-shops',
                    );
                  },
                ),

                _dashboardCard(
                  context,
                  icon: Icons.campaign,
                  title: 'Pending Ads',
                  subtitle:
                      'Review advertisements',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/admin-pending-ads',
                    );
                  },
                ),

                _dashboardCard(
                  context,
                  icon: Icons.verified_user,
                  title: 'Approved Ads',
                  subtitle:
                      'View approved ads',
                  color: Colors.teal,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/admin-approved-ads',
                    );
                  },
                ),

                _dashboardCard(
                  context,
                  icon: Icons.people,
                  title: 'Users',
                  subtitle: 'Manage users',
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/admin-users',
                    );
                  },
                ),

                _dashboardCard(
                  context,
                  icon: Icons.analytics,
                  title: 'Analytics',
                  subtitle:
                      'View app statistics',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/admin-analytics',
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 25),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Admin Controls',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    _controlItem(
                      Icons.store,
                      'Approve or reject shop submissions',
                    ),

                    _controlItem(
                      Icons.verified,
                      'View approved shops',
                    ),

                    _controlItem(
                      Icons.campaign,
                      'Approve or reject advertisements',
                    ),

                    _controlItem(
                      Icons.verified_user,
                      'View approved advertisements',
                    ),

                    _controlItem(
                      Icons.people,
                      'Manage registered users',
                    ),

                    _controlItem(
                      Icons.analytics,
                      'Monitor application analytics',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor:
                    color.withValues(
                  alpha: 0.12,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),

              const SizedBox(height: 13),

              Text(
                title,
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                subtitle,
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controlItem(
    IconData icon,
    String text,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.blue.shade700,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


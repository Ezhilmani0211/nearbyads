import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OwnerDashboardScreen extends StatelessWidget {
  final String ownerEmail;

  const OwnerDashboardScreen({
    super.key,
    required this.ownerEmail,
  });

  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color purple = Color(0xFF7B1FA2);
  static const Color lightBlue = Color(0xFFF5F9FF);

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
      backgroundColor: lightBlue,

      appBar: AppBar(
        title: const Text(
          'Shop Owner Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _logout(context),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // OWNER HEADER
            // --------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryBlue,
                    purple,
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.20),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      size: 34,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome, Shop Owner!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          ownerEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(
                              alpha: 0.85,
                            ),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // --------------------------------------------------
            // SHOP MANAGEMENT
            // --------------------------------------------------
            const Text(
              'Shop Management',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172B4D),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _dashboardCard(
                    context: context,
                    title: 'Add Shop',
                    subtitle: 'Register your shop',
                    icon: Icons.add_business_rounded,
                    color: primaryBlue,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/add-shop',
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _dashboardCard(
                    context: context,
                    title: 'My Shops',
                    subtitle: 'View your shops',
                    icon: Icons.store_rounded,
                    color: purple,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/my-shops',
                        arguments: ownerEmail,
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // --------------------------------------------------
            // ADVERTISEMENT MANAGEMENT
            // --------------------------------------------------
            const Text(
              'Advertisement Management',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172B4D),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _dashboardCard(
                    context: context,
                    title: 'Add Advertisement',
                    subtitle: 'Create a new offer',
                    icon: Icons.campaign_rounded,
                    color: const Color(0xFF5E35B1),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/add-advertisement',
                        arguments: ownerEmail,
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _dashboardCard(
                    context: context,
                    title: 'My Ads',
                    subtitle: 'Manage advertisements',
                    icon: Icons.ads_click_rounded,
                    color: const Color(0xFF3949AB),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/my-ads',
                        arguments: ownerEmail,
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // --------------------------------------------------
            // APPROVAL STATUS
            // --------------------------------------------------
            const Text(
              'Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172B4D),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: _dashboardCard(
                context: context,
                title: 'Approval Status',
                subtitle:
                    'Check shop & advertisement status',
                icon: Icons.fact_check_rounded,
                color: const Color(0xFF00838F),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/approval-status',
                    arguments: ownerEmail,
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // --------------------------------------------------
            // HOW NEARBYADS WORKS
            // --------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE0E7FF),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: primaryBlue,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'How NearbyAds Works',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF172B4D),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  _infoStep(
                    number: '1',
                    text:
                        'Add your shop and submit it for admin approval.',
                  ),

                  _infoStep(
                    number: '2',
                    text:
                        'After approval, your shop becomes visible to nearby users.',
                  ),

                  _infoStep(
                    number: '3',
                    text:
                        'Create advertisements and submit them for approval.',
                  ),

                  _infoStep(
                    number: '4',
                    text:
                        'Approved offers are displayed to nearby users.',
                  ),

                  _infoStep(
                    number: '5',
                    text:
                        'Use Approval Status to monitor your shop and advertisement status.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _dashboardCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE0E7FF),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 27,
                ),
              ),

              const SizedBox(height: 13),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172B4D),
                ),
              ),

              const SizedBox(height: 5),

              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoStep({
    required String number,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  primaryBlue,
                  purple,
                ],
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF424242),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
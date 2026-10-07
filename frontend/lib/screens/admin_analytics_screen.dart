
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() =>
      _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState
    extends State<AdminAnalyticsScreen> {
  bool loading = true;
  String? errorMessage;

  int totalUsers = 0;
  int shopOwners = 0;
  int admins = 0;
  int totalShops = 0;
  int pendingShops = 0;
  int approvedShops = 0;
  int pendingAds = 0;
  int approvedAds = 0;

  @override
  void initState() {
    super.initState();
    loadAnalytics();
  }

  Future<void> loadAnalytics() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getAdminUsers(),
        ApiService.getPendingShops(),
        ApiService.getApprovedShops(),
        ApiService.getPendingAds(),
        ApiService.getApprovedAds(),
      ]);

      if (!mounted) return;

      final usersResult = results[0];
      final pendingShopsResult = results[1];
      final approvedShopsResult = results[2];
      final pendingAdsResult = results[3];
      final approvedAdsResult = results[4];

      final users =
          (usersResult['users'] ?? []) as List<dynamic>;

      final pendingShopList =
          (pendingShopsResult['shops'] ?? [])
              as List<dynamic>;

      final approvedShopList =
          (approvedShopsResult['shops'] ?? [])
              as List<dynamic>;

      final pendingAdList =
          (pendingAdsResult['ads'] ?? [])
              as List<dynamic>;

      final approvedAdList =
          (approvedAdsResult['ads'] ?? [])
              as List<dynamic>;

      int ownerCount = 0;
      int adminCount = 0;

      for (final user in users) {
        final role =
            (user['role'] ?? '').toString().toLowerCase();

        if (role == 'shop_owner') {
          ownerCount++;
        } else if (role == 'admin') {
          adminCount++;
        }
      }

      setState(() {
        totalUsers = users.length;
        shopOwners = ownerCount;
        admins = adminCount;

        pendingShops = pendingShopList.length;
        approvedShops = approvedShopList.length;
        totalShops =
            pendingShops + approvedShops;

        pendingAds = pendingAdList.length;
        approvedAds = approvedAdList.length;

        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = e.toString();
      });
    }
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required int value,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor:
                  color.withValues(alpha: 0.12),
              child: Icon(
                icon,
                color: color,
                size: 27,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 12,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 15),
            const Text(
              'Failed to load analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              errorMessage ?? '',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: loadAnalytics,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed:
                loading ? null : loadAnalytics,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? _errorState()
              : RefreshIndicator(
                  onRefresh: loadAnalytics,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _sectionTitle('Users'),

                      _statCard(
                        icon: Icons.people,
                        title: 'Total Users',
                        value: totalUsers,
                        color: Colors.blue,
                      ),

                      const SizedBox(height: 12),

                      _statCard(
                        icon: Icons.store,
                        title: 'Shop Owners',
                        value: shopOwners,
                        color: Colors.green,
                      ),

                      const SizedBox(height: 12),

                      _statCard(
                        icon: Icons.admin_panel_settings,
                        title: 'Admins',
                        value: admins,
                        color: Colors.purple,
                      ),

                      _sectionTitle('Shops'),

                      _statCard(
                        icon: Icons.storefront,
                        title: 'Total Shops',
                        value: totalShops,
                        color: Colors.indigo,
                      ),

                      const SizedBox(height: 12),

                      _statCard(
                        icon: Icons.pending_actions,
                        title: 'Pending Shops',
                        value: pendingShops,
                        color: Colors.orange,
                      ),

                      const SizedBox(height: 12),

                      _statCard(
                        icon: Icons.verified,
                        title: 'Approved Shops',
                        value: approvedShops,
                        color: Colors.green,
                      ),

                      _sectionTitle('Advertisements'),

                      _statCard(
                        icon: Icons.campaign,
                        title: 'Pending Ads',
                        value: pendingAds,
                        color: Colors.orange,
                      ),

                      const SizedBox(height: 12),

                      _statCard(
                        icon: Icons.verified_user,
                        title: 'Approved Ads',
                        value: approvedAds,
                        color: Colors.teal,
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}


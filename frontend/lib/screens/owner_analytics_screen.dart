import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OwnerAnalyticsScreen extends StatefulWidget {
  final String ownerEmail;

  const OwnerAnalyticsScreen({
    super.key,
    required this.ownerEmail,
  });

  @override
  State<OwnerAnalyticsScreen> createState() =>
      _OwnerAnalyticsScreenState();
}

class _OwnerAnalyticsScreenState
    extends State<OwnerAnalyticsScreen> {
  bool loading = true;
  String? errorMessage;

  int totalShops = 0;
  int approvedShops = 0;
  int pendingShops = 0;
  int rejectedShops = 0;

  int totalAds = 0;
  int approvedAds = 0;
  int pendingAds = 0;
  int rejectedAds = 0;

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
      final shopResult = await ApiService.getMyShops(
        ownerEmail: widget.ownerEmail,
      );

      final adResult = await ApiService.getMyAds(
        ownerEmail: widget.ownerEmail,
      );

      final shopList =
          List<dynamic>.from(shopResult['shops'] ?? []);

      final adList =
          List<dynamic>.from(adResult['ads'] ?? []);

      int approvedShopCount = 0;
      int pendingShopCount = 0;
      int rejectedShopCount = 0;

      for (final shop in shopList) {
        final status =
            (shop['status'] ?? 'pending')
                .toString()
                .toLowerCase();

        if (status == 'approved') {
          approvedShopCount++;
        } else if (status == 'rejected') {
          rejectedShopCount++;
        } else {
          pendingShopCount++;
        }
      }

      int approvedAdCount = 0;
      int pendingAdCount = 0;
      int rejectedAdCount = 0;

      for (final ad in adList) {
        final status =
            (ad['status'] ?? 'pending')
                .toString()
                .toLowerCase();

        if (status == 'approved') {
          approvedAdCount++;
        } else if (status == 'rejected') {
          rejectedAdCount++;
        } else {
          pendingAdCount++;
        }
      }

      if (!mounted) return;

      setState(() {
        totalShops = shopList.length;
        approvedShops = approvedShopCount;
        pendingShops = pendingShopCount;
        rejectedShops = rejectedShopCount;

        totalAds = adList.length;
        approvedAds = approvedAdCount;
        pendingAds = pendingAdCount;
        rejectedAds = rejectedAdCount;

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

  Widget statCard(
    String title,
    int value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
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
            const SizedBox(height: 10),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.blue,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(24),
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
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          errorMessage!,
                          textAlign:
                              TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed:
                              loadAnalytics,
                          icon:
                              const Icon(Icons.refresh),
                          label:
                              const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadAnalytics,
                  child: ListView(
                    padding:
                        const EdgeInsets.all(20),
                    children: [
                      Text(
                        widget.ownerEmail,
                        style: TextStyle(
                          color:
                              Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 25),

                      sectionTitle(
                        'Shop Statistics',
                        Icons.store,
                      ),

                      const SizedBox(height: 12),

                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        children: [
                          statCard(
                            'Total Shops',
                            totalShops,
                            Icons.store,
                            Colors.blue,
                          ),
                          statCard(
                            'Approved',
                            approvedShops,
                            Icons.check_circle,
                            Colors.green,
                          ),
                          statCard(
                            'Pending',
                            pendingShops,
                            Icons.pending,
                            Colors.orange,
                          ),
                          statCard(
                            'Rejected',
                            rejectedShops,
                            Icons.cancel,
                            Colors.red,
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      sectionTitle(
                        'Advertisement Statistics',
                        Icons.campaign,
                      ),

                      const SizedBox(height: 12),

                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        children: [
                          statCard(
                            'Total Ads',
                            totalAds,
                            Icons.campaign,
                            Colors.deepOrange,
                          ),
                          statCard(
                            'Approved',
                            approvedAds,
                            Icons.check_circle,
                            Colors.green,
                          ),
                          statCard(
                            'Pending',
                            pendingAds,
                            Icons.pending,
                            Colors.orange,
                          ),
                          statCard(
                            'Rejected',
                            rejectedAds,
                            Icons.cancel,
                            Colors.red,
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Summary',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                'You have $totalShops shop(s) and $totalAds advertisement(s).',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$approvedShops shop(s) and $approvedAds advertisement(s) are approved.',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$pendingShops shop(s) and $pendingAds advertisement(s) are waiting for approval.',
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}
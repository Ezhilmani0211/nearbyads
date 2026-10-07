import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminPendingAdsScreen extends StatefulWidget {
  const AdminPendingAdsScreen({super.key});

  @override
  State<AdminPendingAdsScreen> createState() =>
      _AdminPendingAdsScreenState();
}

class _AdminPendingAdsScreenState
    extends State<AdminPendingAdsScreen> {
  bool loading = true;
  String? errorMessage;
  List<dynamic> ads = [];

  @override
  void initState() {
    super.initState();
    loadPendingAds();
  }

  Future<void> loadPendingAds() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getPendingAds();

      if (!mounted) return;

      setState(() {
        ads = result['ads'] ?? [];
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

  Future<void> approveAd(String adId) async {
    try {
      await ApiService.approveAdvertisement(
        adId: adId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Advertisement approved successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );

      await loadPendingAds();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Approval failed: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> rejectAd(String adId) async {
    try {
      await ApiService.rejectAdvertisement(
        adId: adId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Advertisement rejected',
          ),
          backgroundColor: Colors.red,
        ),
      );

      await loadPendingAds();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Rejection failed: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> confirmApprove(String adId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Approve Advertisement',
          ),
          content: const Text(
            'Are you sure you want to approve this advertisement?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await approveAd(adId);
    }
  }

  Future<void> confirmReject(String adId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Reject Advertisement',
          ),
          content: const Text(
            'Are you sure you want to reject this advertisement?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await rejectAd(adId);
    }
  }

  Widget buildAdCard(dynamic ad) {
    final adId =
        (ad['id'] ?? ad['_id'] ?? '').toString();

    final title =
        (ad['title'] ?? 'Advertisement').toString();

    final description =
        (ad['description'] ?? '').toString();

    final ownerEmail =
        (ad['owner_email'] ?? '').toString();

    final shopId =
        (ad['shop_id'] ?? '').toString();

    final discount =
        ad['discount']?.toString() ?? '0';

    final radius =
        ad['radius']?.toString() ?? '0';

    final startDate =
        (ad['start_date'] ?? '').toString();

    final endDate =
        (ad['end_date'] ?? '').toString();

    final offerImage =
        (ad['offer_image'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            if (offerImage.isNotEmpty)
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(12),
                child: Image.network(
                  offerImage,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          Icons.campaign,
                          size: 55,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),

            if (offerImage.isNotEmpty)
              const SizedBox(height: 14),

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Colors.orange.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (description.isNotEmpty)
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),

            const SizedBox(height: 16),

            _detailRow(
              Icons.email,
              'Owner Email',
              ownerEmail,
            ),

            if (shopId.isNotEmpty)
              _detailRow(
                Icons.store,
                'Shop ID',
                shopId,
              ),

            _detailRow(
              Icons.percent,
              'Discount',
              '$discount%',
            ),

            _detailRow(
              Icons.radar,
              'Offer Radius',
              '$radius meters',
            ),

            if (startDate.isNotEmpty)
              _detailRow(
                Icons.calendar_today,
                'Start Date',
                startDate,
              ),

            if (endDate.isNotEmpty)
              _detailRow(
                Icons.event,
                'End Date',
                endDate,
              ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: adId.isEmpty
                        ? null
                        : () => confirmApprove(adId),
                    icon: const Icon(
                      Icons.check,
                    ),
                    label: const Text(
                      'Approve',
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.green,
                      foregroundColor:
                          Colors.white,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: adId.isEmpty
                        ? null
                        : () => confirmReject(adId),
                    icon: const Icon(
                      Icons.close,
                    ),
                    label: const Text(
                      'Reject',
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.red,
                      foregroundColor:
                          Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pending Advertisements',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed:
                loading ? null : loadPendingAds,
            icon: const Icon(
              Icons.refresh,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
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
                        const SizedBox(
                          height: 15,
                        ),
                        const Text(
                          'Failed to load pending advertisements',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          errorMessage!,
                          textAlign:
                              TextAlign.center,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        ElevatedButton.icon(
                          onPressed:
                              loadPendingAds,
                          icon: const Icon(
                            Icons.refresh,
                          ),
                          label: const Text(
                            'Retry',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ads.isEmpty
                  ? RefreshIndicator(
                      onRefresh:
                          loadPendingAds,
                      child: ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 150),
                          Icon(
                            Icons
                                .campaign_outlined,
                            size: 70,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 15),
                          Center(
                            child: Text(
                              'No Pending Advertisements',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Center(
                            child: Text(
                              'All advertisements have been reviewed.',
                              textAlign:
                                  TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh:
                          loadPendingAds,
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.all(16),
                        itemCount: ads.length,
                        itemBuilder:
                            (context, index) {
                          return buildAdCard(
                            ads[index],
                          );
                        },
                      ),
                    ),
    );
  }
}
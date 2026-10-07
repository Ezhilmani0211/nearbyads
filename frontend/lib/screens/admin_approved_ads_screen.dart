import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminApprovedAdsScreen extends StatefulWidget {
  const AdminApprovedAdsScreen({super.key});

  @override
  State<AdminApprovedAdsScreen> createState() =>
      _AdminApprovedAdsScreenState();
}

class _AdminApprovedAdsScreenState
    extends State<AdminApprovedAdsScreen> {
  bool loading = true;
  String? errorMessage;
  List<dynamic> ads = [];

  @override
  void initState() {
    super.initState();
    loadApprovedAds();
  }

  Future<void> loadApprovedAds() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getApprovedAds();

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

  Widget buildAdCard(dynamic ad) {
    final title =
        (ad['title'] ?? ad['offer_title'] ?? 'Advertisement')
            .toString();

    final description =
        (ad['description'] ?? '').toString();

    final ownerEmail =
        (ad['owner_email'] ?? '').toString();

    final shopId =
        (ad['shop_id'] ?? '').toString();

    final discount =
        (ad['discount'] ?? '').toString();

    final radius =
        (ad['radius'] ?? '').toString();

    final startDate =
        (ad['start_date'] ?? '').toString();

    final endDate =
        (ad['end_date'] ?? '').toString();

    final adImages =
        ad['images'] is List
            ? List<dynamic>.from(ad['images'])
            : ad['offer_images'] is List
                ? List<dynamic>.from(ad['offer_images'])
                : <dynamic>[];

    String imageUrl = '';

    if (adImages.isNotEmpty) {
      imageUrl = adImages.first.toString();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) {
                    return Container(
                      height: 180,
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

            if (imageUrl.isNotEmpty)
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
                        Colors.green.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'APPROVED',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],

            const SizedBox(height: 16),

            if (ownerEmail.isNotEmpty)
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

            if (discount.isNotEmpty)
              _detailRow(
                Icons.local_offer,
                'Discount',
                discount,
              ),

            if (radius.isNotEmpty)
              _detailRow(
                Icons.radar,
                'Radius',
                radius,
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

  Widget _emptyState() {
    return RefreshIndicator(
      onRefresh: loadApprovedAds,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 150),
          Icon(
            Icons.campaign_outlined,
            size: 70,
            color: Colors.grey,
          ),
          SizedBox(height: 15),
          Center(
            child: Text(
              'No Approved Ads',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: Text(
              'There are no approved advertisements yet.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
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
              'Failed to load approved ads',
              textAlign: TextAlign.center,
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
              onPressed: loadApprovedAds,
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
        title: const Text('Approved Ads'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed:
                loading ? null : loadApprovedAds,
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
              : ads.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: loadApprovedAds,
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
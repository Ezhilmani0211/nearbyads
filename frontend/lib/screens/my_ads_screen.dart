import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'edit_advertisement_screen.dart';

class MyAdsScreen extends StatefulWidget {
  final String ownerEmail;

  const MyAdsScreen({
    super.key,
    required this.ownerEmail,
  });

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  static const Color primaryBlue =
      Color(0xFF1976D2);

  static const Color darkBlue =
      Color(0xFF0D47A1);

  bool loading = true;
  String? errorMessage;

  List<dynamic> ads = [];

  @override
  void initState() {
    super.initState();
    loadAds();
  }

  // ============================================================
  // LOAD ADS
  // ============================================================

  Future<void> loadAds() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result =
          await ApiService.getMyAds(
        ownerEmail: widget.ownerEmail,
      );

      if (!mounted) return;

      setState(() {
        ads = result['ads'] ?? [];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage =
            e.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  // ============================================================
  // STATUS
  // ============================================================

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;

      case 'rejected':
        return Colors.red;

      case 'pending':
      default:
        return Colors.orange;
    }
  }

  IconData statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;

      case 'rejected':
        return Icons.cancel;

      case 'pending':
      default:
        return Icons.hourglass_top;
    }
  }

  Widget buildStatus(String status) {
    final color = statusColor(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color:
            color.withValues(alpha: 0.12),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            statusIcon(status),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight:
                  FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORMAT HELPERS
  // ============================================================

  String formatDiscount(dynamic value) {
    if (value == null) {
      return '0%';
    }

    final number =
        double.tryParse(
      value.toString(),
    );

    if (number == null) {
      return '$value%';
    }

    if (number ==
        number.roundToDouble()) {
      return '${number.toInt()}%';
    }

    return '$number%';
  }

  String formatRadius(dynamic value) {
    if (value == null) {
      return '0 m';
    }

    final number =
        double.tryParse(
      value.toString(),
    );

    if (number == null) {
      return '$value m';
    }

    if (number ==
        number.roundToDouble()) {
      return '${number.toInt()} m';
    }

    return '$number m';
  }

  String formatDateValue(dynamic value) {
    if (value == null) {
      return '-';
    }

    final text =
        value.toString().trim();

    if (text.isEmpty) {
      return '-';
    }

    try {
      final date =
          DateTime.parse(text);

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      if (text.contains('T')) {
        return text.split('T').first;
      }

      return text;
    }
  }

  // ============================================================
  // EDIT
  // ============================================================

  Future<void> editAd(
    dynamic ad,
  ) async {
    final result =
        await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return EditAdvertisementScreen(
            ad: Map<String, dynamic>.from(
              ad,
            ),
          );
        },
      ),
    );

    if (result == true) {
      await loadAds();
    }
  }

  // ============================================================
  // AD CARD
  // ============================================================

  Widget buildAdCard(
    dynamic ad,
  ) {
    final title =
        (ad['title'] ??
                'Advertisement')
            .toString();

    final description =
        (ad['description'] ?? '')
            .toString();

    final discount =
        formatDiscount(
      ad['discount'],
    );

    final radius =
        formatRadius(
      ad['radius'],
    );

    final status =
        (ad['status'] ??
                'pending')
            .toString();

    final startDate =
        formatDateValue(
      ad['start_date'],
    );

    final endDate =
        formatDateValue(
      ad['end_date'],
    );

    final offerImage =
        (ad['offer_image'] ?? '')
            .toString();

    final shopName =
        (ad['shop_name'] ??
                ad['shopName'] ??
                '')
            .toString();

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),
      elevation: 3,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // IMAGE
            // ==================================================

            if (offerImage.isNotEmpty)
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                child:
                    Image.network(
                  offerImage,
                  width:
                      double.infinity,
                  height: 170,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return Container(
                      height: 170,
                      width:
                          double.infinity,
                      color: Colors
                          .grey.shade200,
                      child:
                          const Center(
                        child: Icon(
                          Icons
                              .image_not_supported,
                          size: 45,
                          color:
                              Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),

            if (offerImage.isNotEmpty)
              const SizedBox(
                height: 14,
              ),

            // ==================================================
            // TITLE + STATUS
            // ==================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style:
                        const TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                      color: darkBlue,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                buildStatus(
                  status,
                ),
              ],
            ),

            // ==================================================
            // SHOP NAME
            // ==================================================

            if (shopName.isNotEmpty) ...[
              const SizedBox(
                height: 8,
              ),
              Row(
                children: [
                  Icon(
                    Icons.store,
                    size: 17,
                    color:
                        Colors.grey.shade700,
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  Expanded(
                    child: Text(
                      shopName,
                      style:
                          TextStyle(
                        fontSize: 13,
                        color: Colors
                            .grey.shade700,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // ==================================================
            // DESCRIPTION
            // ==================================================

            if (description.isNotEmpty) ...[
              const SizedBox(
                height: 12,
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // DISCOUNT + RADIUS
            // ==================================================

            Row(
              children: [
                Expanded(
                  child: _infoItem(
                    Icons
                        .local_offer_outlined,
                    'Discount',
                    discount,
                  ),
                ),
                Expanded(
                  child: _infoItem(
                    Icons.radar,
                    'Radius',
                    radius,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            // ==================================================
            // DATES
            // ==================================================

            Row(
              children: [
                Expanded(
                  child: _infoItem(
                    Icons
                        .calendar_today,
                    'Start',
                    startDate,
                  ),
                ),
                Expanded(
                  child: _infoItem(
                    Icons.event,
                    'End',
                    endDate,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // STATUS MESSAGE
            // ==================================================

            _buildStatusMessage(
              status,
            ),

            const SizedBox(
              height: 14,
            ),

            // ==================================================
            // EDIT
            // ==================================================

            SizedBox(
              width:
                  double.infinity,
              child:
                  OutlinedButton.icon(
                onPressed:
                    () => editAd(ad),
                icon:
                    const Icon(
                  Icons.edit,
                ),
                label:
                    const Text(
                  'Edit Advertisement',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS MESSAGE
  // ============================================================

  Widget _buildStatusMessage(
    String status,
  ) {
    final normalized =
        status.toLowerCase();

    if (normalized ==
        'approved') {
      return Container(
        width:
            double.infinity,
        padding:
            const EdgeInsets.all(12),
        decoration:
            BoxDecoration(
          color:
              Colors.green.withValues(
            alpha: 0.08,
          ),
          borderRadius:
              BorderRadius.circular(
            10,
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 19,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'This advertisement has been approved.',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight:
                      FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (normalized ==
        'rejected') {
      return Container(
        width:
            double.infinity,
        padding:
            const EdgeInsets.all(12),
        decoration:
            BoxDecoration(
          color:
              Colors.red.withValues(
            alpha: 0.08,
          ),
          borderRadius:
              BorderRadius.circular(
            10,
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.cancel,
              color: Colors.red,
              size: 19,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'This advertisement was rejected. You can edit and submit it again.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight:
                      FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(12),
      decoration:
          BoxDecoration(
        color:
            Colors.orange.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(
          10,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.hourglass_top,
            color: Colors.orange,
            size: 19,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'This advertisement is waiting for admin approval.',
              style: TextStyle(
                color: Colors.orange,
                fontWeight:
                    FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO ITEM
  // ============================================================

  Widget _infoItem(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: primaryBlue,
        ),
        const SizedBox(
          width: 7,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors
                      .grey.shade600,
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                value,
                style:
                    const TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ERROR VIEW
  // ============================================================

  Widget _buildErrorView() {
    return Center(
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
              'Failed to load advertisements',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
              textAlign:
                  TextAlign.center,
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              errorMessage ??
                  'Something went wrong.',
              textAlign:
                  TextAlign.center,
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton.icon(
              onPressed: loadAds,
              icon:
                  const Icon(
                Icons.refresh,
              ),
              label:
                  const Text(
                'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY VIEW
  // ============================================================

  Widget _buildEmptyView() {
    return RefreshIndicator(
      onRefresh: loadAds,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(24),
        children: const [
          SizedBox(
            height: 150,
          ),
          Icon(
            Icons.campaign_outlined,
            size: 70,
            color: Colors.grey,
          ),
          SizedBox(
            height: 15,
          ),
          Center(
            child: Text(
              'No advertisements found',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 8,
          ),
          Center(
            child: Text(
              'Your submitted advertisements '
              'will appear here.',
              textAlign:
                  TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'My Advertisements',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed:
                loading
                    ? null
                    : loadAds,
            icon:
                const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color: primaryBlue,
              ),
            )
          : errorMessage != null
              ? _buildErrorView()
              : ads.isEmpty
                  ? _buildEmptyView()
                  : RefreshIndicator(
                      onRefresh:
                          loadAds,
                      child:
                          ListView.builder(
                        padding:
                            const EdgeInsets
                                .all(
                          16,
                        ),
                        itemCount:
                            ads.length,
                        itemBuilder:
                            (
                          context,
                          index,
                        ) {
                          return buildAdCard(
                            ads[index],
                          );
                        },
                      ),
                    ),
    );
  }
}
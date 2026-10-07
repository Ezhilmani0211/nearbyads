import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'home_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';

class OffersScreen extends StatefulWidget {
  final bool forceRefresh;

  const OffersScreen({
    super.key,
    this.forceRefresh = false,
  });

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color purple = Color(0xFF7B1FA2);

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _offers =
      <Map<String, dynamic>>[];

  Map<String, String> _shopNames =
      <String, String>{};

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  // ============================================================
  // LOAD APPROVED OFFERS
  // ============================================================

  Future<void> _loadOffers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Map<String, dynamic> adsData =
          await ApiService.getApprovedAds(
        forceRefresh: true,
      );

      final dynamic rawAds = adsData['ads'];

      final List<dynamic> ads =
          rawAds is List ? rawAds : <dynamic>[];

      final List<Map<String, dynamic>> offers =
          ads
              .whereType<Map>()
              .map(
                (dynamic ad) =>
                    Map<String, dynamic>.from(ad),
              )
              .where(
                (Map<String, dynamic> ad) {
                  final String status = _getString(
                    ad['status'],
                    'approved',
                  ).toLowerCase();

                  return status == 'approved';
                },
              )
              .toList();

      // ----------------------------------------------------------
      // LOAD APPROVED SHOPS
      // ----------------------------------------------------------

      final Map<String, String> shopNames =
          <String, String>{};

      try {
        final Map<String, dynamic> shopsData =
            await ApiService.getApprovedShops();

        final dynamic rawShops =
            shopsData['shops'];

        final List<dynamic> shops =
            rawShops is List
                ? rawShops
                : <dynamic>[];

        for (final dynamic rawShop in shops) {
          if (rawShop is! Map) {
            continue;
          }

          final Map<String, dynamic> shop =
              Map<String, dynamic>.from(rawShop);

          final String shopId = _getString(
            shop['id'] ??
                shop['_id'] ??
                shop['shop_id'],
            '',
          );

          final String shopName = _getString(
            shop['shop_name'] ??
                shop['shopName'] ??
                shop['name'],
            '',
          );

          if (shopId.isNotEmpty &&
              shopName.isNotEmpty) {
            shopNames[shopId] = shopName;
          }
        }
      } catch (_) {
        // Shop names are optional.
      }

      // ----------------------------------------------------------
      // ATTACH SHOP NAME
      // ----------------------------------------------------------

      for (final Map<String, dynamic> offer
          in offers) {
        final String shopId = _getString(
          offer['shop_id'] ??
              offer['shopId'],
          '',
        );

        if (shopId.isEmpty) {
          continue;
        }

        final String? shopName =
            shopNames[shopId];

        if (shopName != null &&
            shopName.isNotEmpty) {
          offer['shop_name'] = shopName;
        }
      }

      if (!mounted) return;

      setState(() {
        _offers = offers;
        _shopNames = shopNames;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _offers = <Map<String, dynamic>>[];

        _isLoading = false;

        _errorMessage =
            'Unable to load offers.';
      });
    }
  }

  // ============================================================
  // STRING HELPER
  // ============================================================

  String _getString(
    dynamic value,
    String fallback,
  ) {
    if (value == null) {
      return fallback;
    }

    final String text =
        value.toString().trim();

    return text.isEmpty ? fallback : text;
  }

  // ============================================================
  // DISCOUNT
  // ============================================================

  String _formatDiscount(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is num) {
      final double number = value.toDouble();

      if (number <= 0) {
        return '';
      }

      if (number == number.roundToDouble()) {
        return '${number.toInt()}% OFF';
      }

      return '${number.toStringAsFixed(1)}% OFF';
    }

    String text = value.toString().trim();

    if (text.isEmpty) {
      return '';
    }

    if (text.contains('%')) {
      if (text.toLowerCase().contains('off')) {
        return text;
      }

      return '$text OFF';
    }

    return '$text% OFF';
  }

  // ============================================================
  // RADIUS
  // ============================================================

  String _formatRadius(dynamic value) {
    if (value == null) {
      return '';
    }

    final double? radius =
        double.tryParse(value.toString());

    if (radius == null || radius <= 0) {
      return '';
    }

    if (radius >= 1000) {
      return '${(radius / 1000).toStringAsFixed(1)} km radius';
    }

    return '${radius.round()} m radius';
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(dynamic value) {
    if (value == null) {
      return '';
    }

    final String text =
        value.toString().trim();

    if (text.isEmpty) {
      return '';
    }

    try {
      final DateTime date =
          DateTime.parse(text);

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return text;
    }
  }

  // ============================================================
  // SHOP NAME
  // ============================================================

  String _getShopName(
    Map<String, dynamic> offer,
  ) {
    final String directName = _getString(
      offer['shop_name'] ??
          offer['shopName'] ??
          offer['name'],
      '',
    );

    if (directName.isNotEmpty) {
      return directName;
    }

    final String shopId = _getString(
      offer['shop_id'] ??
          offer['shopId'],
      '',
    );

    if (shopId.isNotEmpty) {
      final String? mappedName =
          _shopNames[shopId];

      if (mappedName != null &&
          mappedName.isNotEmpty) {
        return mappedName;
      }
    }

    return 'Nearby Shop';
  }

  // ============================================================
  // OFFER DETAILS
  // ============================================================

  void _showOfferDetails(
    Map<String, dynamic> offer,
  ) {
    final String title = _getString(
      offer['title'],
      'Special Offer',
    );

    final String description = _getString(
      offer['description'],
      'No description available.',
    );

    final String discount =
        _formatDiscount(offer['discount']);

    final String radius =
        _formatRadius(offer['radius']);

    final String startDate =
        _formatDate(offer['start_date']);

    final String endDate =
        _formatDate(offer['end_date']);

    final String image =
        _getString(offer['offer_image'], '');

    final String shopName =
        _getShopName(offer);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (image.isNotEmpty)
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(16),
                      child: Image.network(
                        image,
                        width: double.infinity,
                        height: 190,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (
                          BuildContext context,
                          Object error,
                          StackTrace? stackTrace,
                        ) {
                          return _imagePlaceholder(
                            height: 190,
                          );
                        },
                      ),
                    )
                  else
                    _imagePlaceholder(
                      height: 150,
                    ),

                  const SizedBox(height: 18),

                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.storefront,
                        size: 18,
                        color: primaryBlue,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          shopName,
                          style: TextStyle(
                            color:
                                Colors.grey.shade700,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (discount.isNotEmpty) ...[
                    const SizedBox(height: 13),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color:
                            purple.withValues(alpha: 0.10),
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Text(
                        discount,
                        style: const TextStyle(
                          color: purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        color: primaryBlue,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          description,
                          style: const TextStyle(
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (radius.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const Icon(
                          Icons.radar,
                          color: primaryBlue,
                        ),
                        const SizedBox(width: 10),
                        Text(radius),
                      ],
                    ),
                  ],

                  if (startDate.isNotEmpty ||
                      endDate.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          color: primaryBlue,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            startDate.isNotEmpty &&
                                    endDate.isNotEmpty
                                ? '$startDate → $endDate'
                                : startDate.isNotEmpty
                                    ? startDate
                                    : endDate,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // OFFER CARD
  // ============================================================

  Widget _buildOfferCard(
    Map<String, dynamic> offer,
  ) {
    final String title = _getString(
      offer['title'],
      'Special Offer',
    );

    final String description = _getString(
      offer['description'],
      'No description available.',
    );

    final String discount =
        _formatDiscount(offer['discount']);

    final String radius =
        _formatRadius(offer['radius']);

    final String image =
        _getString(offer['offer_image'], '');

    final String shopId = _getString(
      offer['shop_id'] ??
          offer['shopId'],
      '',
    );

    final String shopName =
        _getShopName(offer);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () =>
            _showOfferDetails(offer),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              if (image.isNotEmpty)
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(14),
                  child: Image.network(
                    image,
                    width: double.infinity,
                    height: 170,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return _imagePlaceholder();
                    },
                  ),
                )
              else
                _imagePlaceholder(),

              const SizedBox(height: 13),

              Row(
                children: [
                  const Icon(
                    Icons.storefront,
                    size: 18,
                    color: primaryBlue,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      shopName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: primaryBlue,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  if (discount.isNotEmpty)
                    const SizedBox(width: 8),

                  if (discount.isNotEmpty)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: purple,
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: Text(
                        discount,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                description,
                maxLines: 3,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  if (radius.isNotEmpty) ...[
                    const Icon(
                      Icons.radar,
                      size: 18,
                      color: primaryBlue,
                    ),
                    const SizedBox(width: 5),
                    Text(radius),
                  ],

                  const Spacer(),

                  if (shopId.isNotEmpty)
                    const Icon(
                      Icons.storefront,
                      size: 18,
                      color: primaryBlue,
                    ),

                  const SizedBox(width: 5),

                  const Text(
                    'View Offer',
                    style: TextStyle(
                      color: primaryBlue,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE PLACEHOLDER
  // ============================================================

  Widget _imagePlaceholder({
    double height = 170,
  }) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            lightBlue,
            Color(0xFFF3E5F5),
          ],
        ),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: const Center(
        child: Icon(
          Icons.local_offer,
          size: 55,
          color: purple,
        ),
      ),
    );
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _onNavigationChanged(int index) {
    if (!mounted) return;

    if (index == 1) {
      return;
    }

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const HomeScreen(),
        ),
      );
      return;
    }

    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const FavoritesScreen(),
        ),
      );
      return;
    }

    if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const ProfileScreen(),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F8FA),

      appBar: AppBar(
        title: const Text(
          'Nearby Offers',
        ),
        centerTitle: true,
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh offers',
            onPressed:
                _isLoading
                    ? null
                    : _loadOffers,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: _buildBody(),

      bottomNavigationBar:
          NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: 1,
        indicatorColor: lightBlue,
        onDestinationSelected:
            _onNavigationChanged,
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.map_outlined,
              color: Colors.grey,
            ),
            selectedIcon: Icon(
              Icons.map,
              color: primaryBlue,
            ),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.local_offer_outlined,
              color: Colors.grey,
            ),
            selectedIcon: Icon(
              Icons.local_offer,
              color: purple,
            ),
            label: 'Offers',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.favorite_border,
              color: Colors.grey,
            ),
            selectedIcon: Icon(
              Icons.favorite,
              color: primaryBlue,
            ),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
              color: Colors.grey,
            ),
            selectedIcon: Icon(
              Icons.person,
              color: primaryBlue,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryBlue,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),

              const SizedBox(height: 15),

              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 15),

              ElevatedButton.icon(
                onPressed: _loadOffers,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Try Again',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_offers.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadOffers,
        color: primaryBlue,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 170),
            Icon(
              Icons.local_offer_outlined,
              size: 70,
              color: purple,
            ),
            SizedBox(height: 15),
            Center(
              child: Text(
                'No offers available right now.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOffers,
      color: primaryBlue,
      child: ListView.builder(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _offers.length,
        itemBuilder:
            (
          BuildContext context,
          int index,
        ) {
          return _buildOfferCard(
            _offers[index],
          );
        },
      ),
    );
  }
}
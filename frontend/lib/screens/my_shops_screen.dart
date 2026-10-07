import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'edit_shop_screen.dart';

class MyShopsScreen extends StatefulWidget {
  final String ownerEmail;

  const MyShopsScreen({
    super.key,
    required this.ownerEmail,
  });

  @override
  State<MyShopsScreen> createState() =>
      _MyShopsScreenState();
}

class _MyShopsScreenState
    extends State<MyShopsScreen> {
  static const Color primaryBlue =
      Color(0xFF1976D2);

  static const Color darkBlue =
      Color(0xFF0D47A1);

  static const Color purple =
      Color(0xFF7B1FA2);

  bool isLoading = true;

  String? errorMessage;

  List<Map<String, dynamic>> shops = [];

  @override
  void initState() {
    super.initState();
    loadMyShops();
  }

  // ============================================================
  // LOAD MY SHOPS
  // ============================================================

  Future<void> loadMyShops() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result =
          await ApiService.getMyShops(
        ownerEmail: widget.ownerEmail,
      );

      final List<dynamic> shopList =
          result['shops'] ?? [];

      final loadedShops =
          shopList
              .map(
                (shop) =>
                    Map<String, dynamic>.from(
                  shop,
                ),
              )
              .toList();

      if (!mounted) return;

      setState(() {
        shops = loadedShops;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;

      case 'rejected':
        return Colors.red;

      default:
        return Colors.deepPurple;
    }
  }

  // ============================================================
  // LATITUDE
  // ============================================================

  String getLatitude(
    Map<String, dynamic> shop,
  ) {
    if (shop['latitude'] != null) {
      return shop['latitude'].toString();
    }

    final location = shop['location'];

    if (location is Map) {
      final coordinates =
          location['coordinates'];

      if (coordinates is List &&
          coordinates.length >= 2) {
        return coordinates[1].toString();
      }
    }

    return '';
  }

  // ============================================================
  // LONGITUDE
  // ============================================================

  String getLongitude(
    Map<String, dynamic> shop,
  ) {
    if (shop['longitude'] != null) {
      return shop['longitude'].toString();
    }

    final location = shop['location'];

    if (location is Map) {
      final coordinates =
          location['coordinates'];

      if (coordinates is List &&
          coordinates.length >= 2) {
        return coordinates[0].toString();
      }
    }

    return '';
  }

  // ============================================================
  // SAFE STRING
  // ============================================================

  String getString(
    Map<String, dynamic> shop,
    String key,
  ) {
    final value = shop[key];

    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget infoRow(
    IconData icon,
    String text,
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
            size: 19,
            color: primaryBlue,
          ),
          const SizedBox(width: 9),
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

  // ============================================================
  // FACILITY CHIP
  // ============================================================

  Widget facilityChip(
    String title,
    IconData icon,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        right: 7,
        bottom: 7,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.shade100,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: primaryBlue,
          ),
          const SizedBox(width: 5),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
              color: darkBlue,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SHOP CARD
  // ============================================================

  Widget buildShopCard(
    Map<String, dynamic> shop,
  ) {
    final shopName =
        getString(
          shop,
          'shop_name',
        ).isEmpty
            ? 'Unnamed Shop'
            : getString(
                shop,
                'shop_name',
              );

    final category =
        getString(
          shop,
          'category',
        ).isEmpty
            ? 'Unknown'
            : getString(
                shop,
                'category',
              );

    final description =
        getString(
      shop,
      'description',
    );

    final address =
        getString(
      shop,
      'address',
    );

    final locality =
        getString(
      shop,
      'locality',
    );

    final city =
        getString(
      shop,
      'city',
    );

    final district =
        getString(
      shop,
      'district',
    );

    final state =
        getString(
      shop,
      'state',
    );

    final phone =
        getString(
      shop,
      'phone',
    );

    final whatsapp =
        getString(
      shop,
      'whatsapp',
    );

    final website =
        getString(
      shop,
      'website',
    );

    final instagram =
        getString(
      shop,
      'instagram',
    );

    final facebook =
        getString(
      shop,
      'facebook',
    );

    final openingTime =
        getString(
      shop,
      'opening_time',
    );

    final closingTime =
        getString(
      shop,
      'closing_time',
    );

    final status =
        getString(
      shop,
      'status',
    ).isEmpty
            ? 'pending'
            : getString(
                shop,
                'status',
              );

    final bool open24Hours =
        shop['open_24_hours'] ==
            true;

    final bool parking =
        shop['parking'] == true;

    final bool homeDelivery =
        shop['home_delivery'] ==
            true;

    final bool onlineOrder =
        shop['online_order'] ==
            true;

    final bool upi =
        shop['upi'] == true;

    final bool cash =
        shop['cash'] == true;

    final bool offersAvailable =
        shop['offers_available'] ==
            true;

    final bool discountAvailable =
        shop[
                'discount_available'] ==
            true;

    final double advertisementRadius =
        double.tryParse(
              shop[
                      'advertisement_radius']
                  ?.toString() ??
                  '',
            ) ??
            0;

    final dynamic daysValue =
        shop['working_days'];

    final List<String> shopWorkingDays =
        daysValue is List
            ? daysValue
                .map(
                  (e) => e.toString(),
                )
                .toList()
            : [];

    final latitude =
        getLatitude(shop);

    final longitude =
        getLongitude(shop);

    return Card(
      elevation: 2,
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration:
                      BoxDecoration(
                    gradient:
                        const LinearGradient(
                      colors: [
                        primaryBlue,
                        purple,
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),

                const SizedBox(
                  width: 13,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        shopName,
                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                          color: darkBlue,
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        category,
                        style: TextStyle(
                          color:
                              Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        getStatusColor(
                      status,
                    ).withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color:
                          getStatusColor(
                        status,
                      ),
                      fontSize: 10,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // ==================================================
            // DESCRIPTION
            // ==================================================

            if (description.isNotEmpty) ...[
              const SizedBox(
                height: 15,
              ),
              Text(
                description,
                style: TextStyle(
                  color:
                      Colors.grey.shade700,
                ),
              ),
            ],

            const SizedBox(
              height: 15,
            ),

            // ==================================================
            // CONTACT
            // ==================================================

            if (phone.isNotEmpty)
              infoRow(
                Icons.phone_outlined,
                phone,
              ),

            if (whatsapp.isNotEmpty)
              infoRow(
                Icons.chat_outlined,
                'WhatsApp: $whatsapp',
              ),

            // ==================================================
            // ADDRESS
            // ==================================================

            if (address.isNotEmpty ||
                locality.isNotEmpty ||
                city.isNotEmpty ||
                district.isNotEmpty ||
                state.isNotEmpty)
              infoRow(
                Icons.location_on_outlined,
                [
                  address,
                  locality,
                  city,
                  district,
                  state,
                ]
                    .where(
                      (e) => e.isNotEmpty,
                    )
                    .join(', '),
              ),

            // ==================================================
            // LOCATION
            // ==================================================

            if (latitude.isNotEmpty &&
                longitude.isNotEmpty)
              infoRow(
                Icons.my_location,
                'Lat: $latitude\nLng: $longitude',
              ),

            // ==================================================
            // OPENING HOURS
            // ==================================================

            if (open24Hours)
              infoRow(
                Icons.access_time,
                'Open 24 Hours',
              )
            else if (openingTime.isNotEmpty ||
                closingTime.isNotEmpty)
              infoRow(
                Icons.access_time,
                [
                  openingTime,
                  closingTime,
                ]
                    .where(
                      (e) => e.isNotEmpty,
                    )
                    .join(' - '),
              ),

            // ==================================================
            // WORKING DAYS
            // ==================================================

            if (shopWorkingDays.isNotEmpty) ...[
              const SizedBox(
                height: 4,
              ),
              infoRow(
                Icons.calendar_month_outlined,
                shopWorkingDays.join(
                  ', ',
                ),
              ),
            ],

            // ==================================================
            // ONLINE DETAILS
            // ==================================================

            if (website.isNotEmpty)
              infoRow(
                Icons.language_outlined,
                website,
              ),

            if (instagram.isNotEmpty)
              infoRow(
                Icons.camera_alt_outlined,
                'Instagram: $instagram',
              ),

            if (facebook.isNotEmpty)
              infoRow(
                Icons.facebook_outlined,
                'Facebook: $facebook',
              ),

            // ==================================================
            // FACILITIES
            // ==================================================

            if (parking ||
                homeDelivery ||
                onlineOrder ||
                upi ||
                cash) ...[
              const SizedBox(
                height: 5,
              ),
              const Text(
                'Facilities',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.bold,
                  color: darkBlue,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Wrap(
                children: [
                  if (parking)
                    facilityChip(
                      'Parking',
                      Icons.local_parking,
                    ),
                  if (homeDelivery)
                    facilityChip(
                      'Home Delivery',
                      Icons.delivery_dining,
                    ),
                  if (onlineOrder)
                    facilityChip(
                      'Online Order',
                      Icons.shopping_bag_outlined,
                    ),
                  if (upi)
                    facilityChip(
                      'UPI',
                      Icons.qr_code,
                    ),
                  if (cash)
                    facilityChip(
                      'Cash',
                      Icons.payments_outlined,
                    ),
                ],
              ),
            ],

            // ==================================================
            // OFFERS
            // ==================================================

            if (offersAvailable ||
                discountAvailable) ...[
              const SizedBox(
                height: 8,
              ),
              const Text(
                'Offers',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.bold,
                  color: darkBlue,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Wrap(
                children: [
                  if (offersAvailable)
                    facilityChip(
                      'Offers Available',
                      Icons.local_offer_outlined,
                    ),
                  if (discountAvailable)
                    facilityChip(
                      'Discount Available',
                      Icons.discount_outlined,
                    ),
                ],
              ),
            ],

            // ==================================================
            // ADVERTISEMENT RADIUS
            // ==================================================

            if (advertisementRadius >
                0)
              infoRow(
                Icons.radar,
                'Advertisement Radius: '
                '${advertisementRadius.toStringAsFixed(0)} meters',
              ),

            const SizedBox(
              height: 8,
            ),

            // ==================================================
            // EDIT SHOP
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final updated =
                      await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditShopScreen(
                        shop: shop,
                      ),
                    ),
                  );

                  if (updated == true &&
                      mounted) {
                    await loadMyShops();
                  }
                },
                icon: const Icon(
                  Icons.edit_outlined,
                ),
                label: const Text(
                  'Edit Shop',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      primaryBlue,
                  side:
                      const BorderSide(
                    color: primaryBlue,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
            const Text('My Shops'),
        actions: [
          IconButton(
            onPressed:
                isLoading
                    ? null
                    : loadMyShops,
            icon:
                const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadMyShops,
        child: Builder(
          builder: (_) {
            // ==================================================
            // LOADING
            // ==================================================

            if (isLoading) {
              return const Center(
                child:
                    CircularProgressIndicator(
                  color: primaryBlue,
                ),
              );
            }

            // ==================================================
            // ERROR
            // ==================================================

            if (errorMessage != null) {
              return ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(
                    height: 150,
                  ),
                  const Icon(
                    Icons.error_outline,
                    size: 65,
                    color: Colors.red,
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  const Center(
                    child: Text(
                      'Failed to load shops',
                      style:
                          TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.all(
                      25,
                    ),
                    child: Text(
                      errorMessage!,
                      textAlign:
                          TextAlign.center,
                    ),
                  ),
                  Center(
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          loadMyShops,
                      icon:
                          const Icon(
                        Icons.refresh,
                      ),
                      label:
                          const Text(
                        'Try Again',
                      ),
                    ),
                  ),
                ],
              );
            }

            // ==================================================
            // EMPTY
            // ==================================================

            if (shops.isEmpty) {
              return ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(
                    height: 160,
                  ),
                  const Icon(
                    Icons.store_outlined,
                    size: 75,
                    color: primaryBlue,
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  const Center(
                    child: Text(
                      'No Shops Found',
                      style:
                          TextStyle(
                        fontSize: 21,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Center(
                    child: Text(
                      'Your submitted shops will appear here.',
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              );
            }

            // ==================================================
            // SHOP LIST
            // ==================================================

            return ListView.builder(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.all(16),
              itemCount:
                  shops.length,
              itemBuilder:
                  (context, index) =>
                      buildShopCard(
                shops[index],
              ),
            );
          },
        ),
      ),
    );
  }
}
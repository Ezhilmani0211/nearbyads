import 'package:flutter/material.dart';

import '../services/api_service.dart';

class EditShopScreen extends StatefulWidget {
  final Map<String, dynamic> shop;

  const EditShopScreen({
    super.key,
    required this.shop,
  });

  @override
  State<EditShopScreen> createState() =>
      _EditShopScreenState();
}

class _EditShopScreenState
    extends State<EditShopScreen> {
  static const Color primaryBlue =
      Color(0xFF1976D2);

  static const Color darkBlue =
      Color(0xFF0D47A1);

  static const Color purple =
      Color(0xFF7B1FA2);

  final formKey =
      GlobalKey<FormState>();

  late final TextEditingController
      shopNameController;

  late final TextEditingController
      categoryController;

  late final TextEditingController
      descriptionController;

  late final TextEditingController
      ownerNameController;

  late final TextEditingController
      ownerEmailController;

  late final TextEditingController
      phoneController;

  late final TextEditingController
      whatsappController;

  late final TextEditingController
      addressController;

  late final TextEditingController
      localityController;

  late final TextEditingController
      cityController;

  late final TextEditingController
      districtController;

  late final TextEditingController
      stateController;

  late final TextEditingController
      pincodeController;

  late final TextEditingController
      latitudeController;

  late final TextEditingController
      longitudeController;

  late final TextEditingController
      openingTimeController;

  late final TextEditingController
      closingTimeController;

  late final TextEditingController
      websiteController;

  late final TextEditingController
      instagramController;

  late final TextEditingController
      facebookController;

  late final TextEditingController
      advertisementRadiusController;

  bool open24Hours = false;

  bool parking = false;
  bool homeDelivery = false;
  bool onlineOrder = false;
  bool upi = false;
  bool cash = false;

  bool offersAvailable = false;
  bool discountAvailable = false;

  final Set<String> selectedWorkingDays =
      {};

  final List<String> workingDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  bool isSaving = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    final shop = widget.shop;

    shopNameController =
        TextEditingController(
      text:
          shop['shop_name']?.toString() ??
              '',
    );

    categoryController =
        TextEditingController(
      text:
          shop['category']?.toString() ??
              '',
    );

    descriptionController =
        TextEditingController(
      text:
          shop['description']?.toString() ??
              '',
    );

    ownerNameController =
        TextEditingController(
      text:
          shop['owner_name']?.toString() ??
              '',
    );

    ownerEmailController =
        TextEditingController(
      text:
          shop['owner_email']?.toString() ??
              '',
    );

    phoneController =
        TextEditingController(
      text:
          shop['phone']?.toString() ??
              '',
    );

    whatsappController =
        TextEditingController(
      text:
          shop['whatsapp']?.toString() ??
              '',
    );

    addressController =
        TextEditingController(
      text:
          shop['address']?.toString() ??
              '',
    );

    localityController =
        TextEditingController(
      text:
          shop['locality']?.toString() ??
              '',
    );

    cityController =
        TextEditingController(
      text:
          shop['city']?.toString() ??
              '',
    );

    districtController =
        TextEditingController(
      text:
          shop['district']?.toString() ??
              '',
    );

    stateController =
        TextEditingController(
      text:
          shop['state']?.toString() ??
              '',
    );

    pincodeController =
        TextEditingController(
      text:
          shop['pincode']?.toString() ??
              '',
    );

    latitudeController =
        TextEditingController(
      text: getLatitude(),
    );

    longitudeController =
        TextEditingController(
      text: getLongitude(),
    );

    openingTimeController =
        TextEditingController(
      text:
          shop['opening_time']
                  ?.toString() ??
              '',
    );

    closingTimeController =
        TextEditingController(
      text:
          shop['closing_time']
                  ?.toString() ??
              '',
    );

    websiteController =
        TextEditingController(
      text:
          shop['website']?.toString() ??
              '',
    );

    instagramController =
        TextEditingController(
      text:
          shop['instagram']?.toString() ??
              '',
    );

    facebookController =
        TextEditingController(
      text:
          shop['facebook']?.toString() ??
              '',
    );

    advertisementRadiusController =
        TextEditingController(
      text:
          shop['advertisement_radius']
                  ?.toString() ??
              '1000',
    );

    open24Hours =
        shop['open_24_hours'] == true;

    parking =
        shop['parking'] == true;

    homeDelivery =
        shop['home_delivery'] == true;

    onlineOrder =
        shop['online_order'] == true;

    upi =
        shop['upi'] == true;

    cash =
        shop['cash'] == true;

    offersAvailable =
        shop['offers_available'] == true;

    discountAvailable =
        shop['discount_available'] == true;

    final days =
        shop['working_days'];

    if (days is List) {
      selectedWorkingDays.addAll(
        days.map(
          (e) => e.toString(),
        ),
      );
    }
  }

  // ============================================================
  // LOCATION
  // ============================================================

  String getLatitude() {
    if (widget.shop['latitude'] != null) {
      return widget.shop['latitude'].toString();
    }

    final location =
        widget.shop['location'];

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

  String getLongitude() {
    if (widget.shop['longitude'] != null) {
      return widget.shop['longitude'].toString();
    }

    final location =
        widget.shop['location'];

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
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    shopNameController.dispose();
    categoryController.dispose();
    descriptionController.dispose();
    ownerNameController.dispose();
    ownerEmailController.dispose();
    phoneController.dispose();
    whatsappController.dispose();
    addressController.dispose();
    localityController.dispose();
    cityController.dispose();
    districtController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    openingTimeController.dispose();
    closingTimeController.dispose();
    websiteController.dispose();
    instagramController.dispose();
    facebookController.dispose();
    advertisementRadiusController.dispose();

    super.dispose();
  }

  // ============================================================
  // DECORATION
  // ============================================================

  InputDecoration decoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: primaryBlue,
      ),
    );
  }

  // ============================================================
  // UPDATE SHOP
  // ============================================================

  Future<void> updateShop() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final shopId =
        widget.shop['id']?.toString() ??
            widget.shop['_id']?.toString() ??
            '';

    if (shopId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text('Shop ID not found.'),
        ),
      );
      return;
    }

    final latitude =
        double.tryParse(
      latitudeController.text.trim(),
    );

    final longitude =
        double.tryParse(
      longitudeController.text.trim(),
    );

    if (latitude == null ||
        longitude == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Enter valid latitude and longitude.',
          ),
        ),
      );
      return;
    }

    final advertisementRadius =
        double.tryParse(
      advertisementRadiusController
          .text
          .trim(),
    );

    if (advertisementRadius == null ||
        advertisementRadius <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid advertisement radius.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await ApiService.updateShop(
        shopId: shopId,

        shopName:
            shopNameController.text.trim(),

        category:
            categoryController.text.trim(),

        description:
            descriptionController.text.trim(),

        ownerName:
            ownerNameController.text.trim(),

        ownerEmail:
            ownerEmailController.text.trim(),

        phone:
            phoneController.text.trim(),

        whatsapp:
            whatsappController.text.trim(),

        address:
            addressController.text.trim(),

        locality:
            localityController.text.trim(),

        city:
            cityController.text.trim(),

        district:
            districtController.text.trim(),

        state:
            stateController.text.trim(),

        pincode:
            pincodeController.text.trim(),

        latitude: latitude,

        longitude: longitude,

        openingTime:
            openingTimeController.text.trim(),

        closingTime:
            closingTimeController.text.trim(),

        open24Hours:
            open24Hours,

        workingDays:
            selectedWorkingDays.toList(),

        website:
            websiteController.text.trim(),

        instagram:
            instagramController.text.trim(),

        facebook:
            facebookController.text.trim(),

        parking:
            parking,

        homeDelivery:
            homeDelivery,

        onlineOrder:
            onlineOrder,

        upi:
            upi,

        cash:
            cash,

        offersAvailable:
            offersAvailable,

        discountAvailable:
            discountAvailable,

        advertisementRadius:
            advertisementRadius,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Shop updated and submitted for approval.',
          ),
          backgroundColor:
              primaryBlue,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget sectionTitle(String text) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 19,
          fontWeight:
              FontWeight.bold,
          color: darkBlue,
        ),
      ),
    );
  }

  // ============================================================
  // SWITCH TILE
  // ============================================================

  Widget switchTile({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding:
          EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight:
              FontWeight.w500,
        ),
      ),
      secondary: Icon(
        icon,
        color: primaryBlue,
      ),
      value: value,
      activeThumbColor:
          primaryBlue,
      onChanged: onChanged,
    );
  }

  // ============================================================
  // WORKING DAYS
  // ============================================================

  Widget workingDaysSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: workingDays.map(
        (day) {
          final selected =
              selectedWorkingDays
                  .contains(day);

          return FilterChip(
            label: Text(day),
            selected: selected,
            selectedColor:
                primaryBlue.withValues(
              alpha: 0.15,
            ),
            checkmarkColor:
                primaryBlue,
            labelStyle: TextStyle(
              color: selected
                  ? primaryBlue
                  : Colors.black87,
              fontWeight: selected
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
            onSelected: (value) {
              setState(() {
                if (value) {
                  selectedWorkingDays
                      .add(day);
                } else {
                  selectedWorkingDays
                      .remove(day);
                }
              });
            },
          );
        },
      ).toList(),
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
            const Text('Edit Shop'),
      ),

      body: Form(
        key: formKey,

        child: ListView(
          padding:
              const EdgeInsets.all(16),

          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior
                  .onDrag,

          children: [
            const Text(
              'Update Shop Details',
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
                color: darkBlue,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Updated shop details will be submitted for admin approval again.',
              style: TextStyle(
                color:
                    Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // SHOP INFORMATION
            // ==================================================

            sectionTitle(
              'Shop Information',
            ),

            TextFormField(
              controller:
                  shopNameController,
              decoration: decoration(
                'Shop Name *',
                Icons.store_outlined,
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter shop name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller:
                  categoryController,
              decoration: decoration(
                'Category *',
                Icons.category_outlined,
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter category';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller:
                  descriptionController,
              maxLines: 4,
              decoration: decoration(
                'Description',
                Icons.description_outlined,
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // OWNER INFORMATION
            // ==================================================

            sectionTitle(
              'Owner Information',
            ),

            TextFormField(
              controller:
                  ownerNameController,
              decoration: decoration(
                'Owner Name *',
                Icons.person_outline,
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter owner name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller:
                  ownerEmailController,
              keyboardType:
                  TextInputType.emailAddress,
              decoration: decoration(
                'Owner Email *',
                Icons.email_outlined,
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter email';
                }

                if (!value.contains('@')) {
                  return 'Enter valid email';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller:
                  phoneController,
              keyboardType:
                  TextInputType.phone,
              decoration: decoration(
                'Phone Number *',
                Icons.phone_outlined,
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter phone number';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller:
                  whatsappController,
              keyboardType:
                  TextInputType.phone,
              decoration: decoration(
                'WhatsApp Number',
                Icons.chat_outlined,
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // ADDRESS
            // ==================================================

            sectionTitle(
              'Address',
            ),

            TextFormField(
              controller:
                  addressController,
              maxLines: 2,
              decoration: decoration(
                'Address *',
                Icons.location_on_outlined,
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter address';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller:
                  localityController,
              decoration: decoration(
                'Locality *',
                Icons.place_outlined,
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter locality';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller:
                  cityController,
              decoration: decoration(
                'City *',
                Icons.location_city_outlined,
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter city';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller:
                  districtController,
              decoration: decoration(
                'District',
                Icons.map_outlined,
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller:
                  stateController,
              decoration: decoration(
                'State',
                Icons.public_outlined,
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller:
                  pincodeController,
              keyboardType:
                  TextInputType.number,
              decoration: decoration(
                'Pincode *',
                Icons.pin_drop_outlined,
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter pincode';
                }
                return null;
              },
            ),

            const SizedBox(height: 28),

            // ==================================================
            // SHOP LOCATION
            // ==================================================

            sectionTitle(
              'Shop Location',
            ),

            TextFormField(
              controller:
                  latitudeController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: decoration(
                'Latitude *',
                Icons.my_location,
              ),
              validator: (value) {
                if (double.tryParse(
                      value?.trim() ?? '',
                    ) ==
                    null) {
                  return 'Enter valid latitude';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller:
                  longitudeController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: decoration(
                'Longitude *',
                Icons.explore_outlined,
              ),
              validator: (value) {
                if (double.tryParse(
                      value?.trim() ?? '',
                    ) ==
                    null) {
                  return 'Enter valid longitude';
                }
                return null;
              },
            ),

            const SizedBox(height: 28),

            // ==================================================
            // OPENING HOURS
            // ==================================================

            sectionTitle(
              'Opening Hours',
            ),

            switchTile(
              title: 'Open 24 Hours',
              icon:
                  Icons.access_time_filled,
              value: open24Hours,
              onChanged: (value) {
                setState(() {
                  open24Hours = value;
                });
              },
            ),

            if (!open24Hours) ...[
              const SizedBox(height: 8),

              TextFormField(
                controller:
                    openingTimeController,
                decoration:
                    decoration(
                  'Opening Time',
                  Icons.access_time,
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller:
                    closingTimeController,
                decoration:
                    decoration(
                  'Closing Time',
                  Icons.access_time_filled,
                ),
              ),
            ],

            const SizedBox(height: 20),

            const Text(
              'Working Days',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
                color: darkBlue,
              ),
            ),

            const SizedBox(height: 10),

            workingDaysSection(),

            const SizedBox(height: 28),

            // ==================================================
            // ONLINE DETAILS
            // ==================================================

            sectionTitle(
              'Online Details',
            ),

            TextFormField(
              controller:
                  websiteController,
              keyboardType:
                  TextInputType.url,
              decoration: decoration(
                'Website',
                Icons.language,
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller:
                  instagramController,
              decoration: decoration(
                'Instagram',
                Icons.camera_alt_outlined,
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller:
                  facebookController,
              decoration: decoration(
                'Facebook',
                Icons.facebook_outlined,
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // FACILITIES
            // ==================================================

            sectionTitle(
              'Facilities',
            ),

            switchTile(
              title: 'Parking',
              icon:
                  Icons.local_parking,
              value: parking,
              onChanged: (value) {
                setState(() {
                  parking = value;
                });
              },
            ),

            switchTile(
              title: 'Home Delivery',
              icon:
                  Icons.delivery_dining,
              value: homeDelivery,
              onChanged: (value) {
                setState(() {
                  homeDelivery = value;
                });
              },
            ),

            switchTile(
              title: 'Online Order',
              icon:
                  Icons.shopping_bag_outlined,
              value: onlineOrder,
              onChanged: (value) {
                setState(() {
                  onlineOrder = value;
                });
              },
            ),

            switchTile(
              title: 'UPI',
              icon: Icons.qr_code,
              value: upi,
              onChanged: (value) {
                setState(() {
                  upi = value;
                });
              },
            ),

            switchTile(
              title: 'Cash',
              icon:
                  Icons.payments_outlined,
              value: cash,
              onChanged: (value) {
                setState(() {
                  cash = value;
                });
              },
            ),

            const SizedBox(height: 28),

            // ==================================================
            // OFFERS
            // ==================================================

            sectionTitle(
              'Offers & Advertisement',
            ),

            switchTile(
              title: 'Offers Available',
              icon:
                  Icons.local_offer_outlined,
              value: offersAvailable,
              onChanged: (value) {
                setState(() {
                  offersAvailable = value;
                });
              },
            ),

            switchTile(
              title: 'Discount Available',
              icon:
                  Icons.discount_outlined,
              value: discountAvailable,
              onChanged: (value) {
                setState(() {
                  discountAvailable =
                      value;
                });
              },
            ),

            const SizedBox(height: 8),

            TextFormField(
              controller:
                  advertisementRadiusController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: decoration(
                'Advertisement Radius (meters)',
                Icons.radar,
              ),
              validator: (value) {
                final radius =
                    double.tryParse(
                  value?.trim() ?? '',
                );

                if (radius == null ||
                    radius <= 0) {
                  return 'Enter valid radius';
                }

                return null;
              },
            ),

            const SizedBox(height: 30),

            // ==================================================
            // UPDATE BUTTON
            // ==================================================

            SizedBox(
              height: 54,
              child: DecoratedBox(
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
                    14,
                  ),
                ),
                child:
                    ElevatedButton.icon(
                  onPressed:
                      isSaving
                          ? null
                          : updateShop,
                  icon: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.save_outlined,
                        ),
                  label: Text(
                    isSaving
                        ? 'Updating...'
                        : 'Update Shop',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.transparent,
                    shadowColor:
                        Colors.transparent,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }
}
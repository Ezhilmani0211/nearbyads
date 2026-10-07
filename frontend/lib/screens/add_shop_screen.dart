import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';
import 'map_picker_screen.dart';

class AddShopScreen extends StatefulWidget {
  const AddShopScreen({super.key});

  @override
  State<AddShopScreen> createState() => _AddShopScreenState();
}

class _AddShopScreenState extends State<AddShopScreen> {
  final _formKey = GlobalKey<FormState>();

  // ============================================================
  // TEXT CONTROLLERS
  // ============================================================

  final shopNameController = TextEditingController();
  final descriptionController = TextEditingController();

  final ownerNameController = TextEditingController();
  final ownerEmailController = TextEditingController();
  final phoneController = TextEditingController();
  final whatsappController = TextEditingController();

  final addressController = TextEditingController();
  final localityController = TextEditingController();
  final cityController = TextEditingController();
  final districtController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();

  final websiteController = TextEditingController();
  final instagramController = TextEditingController();
  final facebookController = TextEditingController();

  final openingTimeController = TextEditingController();
  final closingTimeController = TextEditingController();

  final radiusController = TextEditingController();

  // Manual location controllers
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();

  // ============================================================
  // VARIABLES
  // ============================================================

  String? selectedCategory;

  double? latitude;
  double? longitude;

  bool isLoadingLocation = false;
  bool isSubmitting = false;

  bool open24Hours = false;
  bool offersAvailable = false;
  bool discountAvailable = false;
  bool confirmed = false;

  bool parking = false;
  bool homeDelivery = false;
  bool onlineOrder = false;
  bool upi = false;
  bool cash = false;

  // ============================================================
  // CATEGORY LIST
  // ============================================================

  final List<String> categories = [
    'Restaurant',
    'Hotel',
    'Pharmacy',
    'Supermarket',
    'Clothing',
    'Guest House',
    'Hospital',
    'Clinic',
    'Mall',
    'Bakery',
    'Electronics',
    'Hardware',
    'Beauty Salon',
    'Mobile Shop',
    'Jewellery',
    'Furniture',
    'Book Store',
    'Grocery',
    'Other',
  ];

  // ============================================================
  // WORKING DAYS
  // ============================================================

  final List<String> workingDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final Set<String> selectedWorkingDays = {};

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    shopNameController.dispose();
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

    websiteController.dispose();
    instagramController.dispose();
    facebookController.dispose();

    openingTimeController.dispose();
    closingTimeController.dispose();

    radiusController.dispose();

    latitudeController.dispose();
    longitudeController.dispose();

    super.dispose();
  }

  // ============================================================
  // USE CURRENT LOCATION
  // ============================================================

  Future<void> useCurrentLocation() async {
    setState(() {
      isLoadingLocation = true;
    });

    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enable location service.',
            ),
          ),
        );

        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission denied.',
            ),
          ),
        );

        return;
      }

      if (permission ==
          LocationPermission.deniedForever) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission permanently denied.',
            ),
          ),
        );

        return;
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;

        latitudeController.text =
            position.latitude.toString();

        longitudeController.text =
            position.longitude.toString();
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Current location selected.\n'
            'Latitude: ${position.latitude.toStringAsFixed(6)}\n'
            'Longitude: ${position.longitude.toStringAsFixed(6)}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to get current location: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoadingLocation = false;
        });
      }
    }
  }

  // ============================================================
  // PICK LOCATION FROM OPENSTREETMAP
  // ============================================================

  Future<void> pickLocationFromMap() async {
    final LatLng? result =
        await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return MapPickerScreen(
            initialLatitude: latitude,
            initialLongitude: longitude,
          );
        },
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      latitude = result.latitude;
      longitude = result.longitude;

      latitudeController.text =
          result.latitude.toString();

      longitudeController.text =
          result.longitude.toString();
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Shop location selected successfully.',
        ),
      ),
    );
  }

  // ============================================================
  // APPLY MANUAL LATITUDE / LONGITUDE
  // ============================================================

  void applyManualLocation() {
    final String latitudeText =
        latitudeController.text.trim();

    final String longitudeText =
        longitudeController.text.trim();

    if (latitudeText.isEmpty ||
        longitudeText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter both latitude and longitude.',
          ),
        ),
      );

      return;
    }

    final double? enteredLatitude =
        double.tryParse(latitudeText);

    final double? enteredLongitude =
        double.tryParse(longitudeText);

    if (enteredLatitude == null ||
        enteredLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter valid latitude and longitude.',
          ),
        ),
      );

      return;
    }

    if (enteredLatitude < -90 ||
        enteredLatitude > 90) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Latitude must be between -90 and 90.',
          ),
        ),
      );

      return;
    }

    if (enteredLongitude < -180 ||
        enteredLongitude > 180) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Longitude must be between -180 and 180.',
          ),
        ),
      );

      return;
    }

    setState(() {
      latitude = enteredLatitude;
      longitude = enteredLongitude;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Location applied successfully.\n'
          'Latitude: ${enteredLatitude.toStringAsFixed(6)}\n'
          'Longitude: ${enteredLongitude.toStringAsFixed(6)}',
        ),
      ),
    );
  }

  // ============================================================
  // TIME PICKERS
  // ============================================================

  Future<void> selectOpeningTime() async {
    final TimeOfDay? time =
        await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) {
      return;
    }

    setState(() {
      openingTimeController.text =
          time.format(context);
    });
  }

  Future<void> selectClosingTime() async {
    final TimeOfDay? time =
        await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) {
      return;
    }

    setState(() {
      closingTimeController.text =
          time.format(context);
    });
  }

  // ============================================================
  // SUBMIT SHOP
  // ============================================================

  Future<void> submitShop() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (latitude == null ||
        longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select shop location.',
          ),
        ),
      );

      return;
    }

    if (!open24Hours &&
        selectedWorkingDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one working day.',
          ),
        ),
      );

      return;
    }

    if (!confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please confirm the shop details.',
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // ADVERTISEMENT RADIUS
    // ==========================================================

    double advertisementRadius = 1000;

    final String radiusText =
        radiusController.text.trim();

    if (radiusText.isNotEmpty) {
      final double? parsedRadius =
          double.tryParse(radiusText);

      if (parsedRadius == null ||
          parsedRadius <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enter a valid advertisement radius.',
            ),
          ),
        );

        return;
      }

      advertisementRadius = parsedRadius;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final result =
          await ApiService.createShop(
        // ========================================================
        // BASIC SHOP INFORMATION
        // ========================================================

        shopName:
            shopNameController.text.trim(),

        category:
            selectedCategory ?? 'Other',

        description:
            descriptionController.text.trim(),

        // ========================================================
        // OWNER INFORMATION
        // ========================================================

        ownerName:
            ownerNameController.text.trim(),

        ownerEmail:
            ownerEmailController.text.trim(),

        phone:
            phoneController.text.trim(),

        whatsapp:
            whatsappController.text.trim(),

        // ========================================================
        // ADDRESS
        // ========================================================

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

        // ========================================================
        // LOCATION
        // ========================================================

        latitude: latitude!,

        longitude: longitude!,

        // ========================================================
        // OPENING HOURS
        // ========================================================

        openingTime:
            openingTimeController.text.trim(),

        closingTime:
            closingTimeController.text.trim(),

        open24Hours:
            open24Hours,

        // ========================================================
        // WORKING DAYS
        // ========================================================

        workingDays:
            selectedWorkingDays.toList(),

        // ========================================================
        // ONLINE DETAILS
        // ========================================================

        website:
            websiteController.text.trim(),

        instagram:
            instagramController.text.trim(),

        facebook:
            facebookController.text.trim(),

        // ========================================================
        // FACILITIES
        // ========================================================

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

        // ========================================================
        // OFFERS & ADVERTISEMENT
        // ========================================================

        offersAvailable:
            offersAvailable,

        discountAvailable:
            discountAvailable,

        advertisementRadius:
            advertisementRadius,       
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ??
                'Shop submitted successfully.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Shop submission failed: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  // ============================================================
  // REQUIRED FIELD
  // ============================================================

  Widget requiredField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
        validator: (value) {
          if (value == null ||
              value.trim().isEmpty) {
            return '$label is required';
          }

          return null;
        },
      ),
    );
  }

  // ============================================================
  // OPTIONAL FIELD
  // ============================================================

  Widget optionalField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget sectionTitle(String title) {
    return Padding(
      padding:
          const EdgeInsets.only(
        top: 20,
        bottom: 12,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // LOCATION SECTION
  // ============================================================

  Widget locationSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius:
                BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.shade200,
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.blue,
                size: 34,
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                latitude == null ||
                        longitude == null
                    ? 'Shop location not selected'
                    : 'Latitude: ${latitude!.toStringAsFixed(6)}\n'
                      'Longitude: ${longitude!.toStringAsFixed(6)}',
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        // ======================================================
        // USE CURRENT LOCATION
        // ======================================================

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed:
                isLoadingLocation
                    ? null
                    : useCurrentLocation,
            icon: isLoadingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.my_location,
                  ),
            label: const Text(
              'Use Current Location',
            ),
          ),
        ),

        const SizedBox(
          height: 10,
        ),

        // ======================================================
        // PICK FROM MAP
        // ======================================================

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed:
                pickLocationFromMap,
            icon: const Icon(
              Icons.map,
            ),
            label: const Text(
              'Pick Location From Map',
            ),
          ),
        ),

        const SizedBox(
          height: 16,
        ),

        // ======================================================
        // MANUAL LATITUDE
        // ======================================================

        TextFormField(
          controller: latitudeController,
          keyboardType:
              const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: InputDecoration(
            labelText: 'Latitude',
            hintText: 'Example: 8.813369093326774',
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        // ======================================================
        // MANUAL LONGITUDE
        // ======================================================

        TextFormField(
          controller: longitudeController,
          keyboardType:
              const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: InputDecoration(
            labelText: 'Longitude',
            hintText: 'Example: 78.12986012019925',
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        // ======================================================
        // APPLY MANUAL LOCATION
        // ======================================================

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed:
                applyManualLocation,
            icon: const Icon(
              Icons.check_circle_outline,
            ),
            label: const Text(
              'Apply Location',
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // WORKING DAYS
  // ============================================================

  Widget workingDaysSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          workingDays.map((day) {
        final bool selected =
            selectedWorkingDays
                .contains(day);

        return FilterChip(
          label: Text(day),
          selected: selected,
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
      }).toList(),
    );
  }

  // ============================================================
  // FACILITIES
  // ============================================================

  Widget facilitiesSection() {
    return Column(
      children: [
        CheckboxListTile(
          contentPadding:
              EdgeInsets.zero,
          title:
              const Text('Parking'),
          value: parking,
          onChanged: (value) {
            setState(() {
              parking =
                  value ?? false;
            });
          },
        ),
        CheckboxListTile(
          contentPadding:
              EdgeInsets.zero,
          title:
              const Text('Home Delivery'),
          value: homeDelivery,
          onChanged: (value) {
            setState(() {
              homeDelivery =
                  value ?? false;
            });
          },
        ),
        CheckboxListTile(
          contentPadding:
              EdgeInsets.zero,
          title:
              const Text('Online Order'),
          value: onlineOrder,
          onChanged: (value) {
            setState(() {
              onlineOrder =
                  value ?? false;
            });
          },
        ),
        CheckboxListTile(
          contentPadding:
              EdgeInsets.zero,
          title: const Text('UPI'),
          value: upi,
          onChanged: (value) {
            setState(() {
              upi =
                  value ?? false;
            });
          },
        ),
        CheckboxListTile(
          contentPadding:
              EdgeInsets.zero,
          title:
              const Text('Cash'),
          value: cash,
          onChanged: (value) {
            setState(() {
              cash =
                  value ?? false;
            });
          },
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Add Shop'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding:
                const EdgeInsets.all(16),
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior
                    .onDrag,
            children: [
              // ==================================================
              // SHOP INFORMATION
              // ==================================================

              sectionTitle(
                'Shop Information',
              ),

              requiredField(
                label: 'Shop Name *',
                controller:
                    shopNameController,
              ),

              DropdownButtonFormField<String>(
                initialValue:
                    selectedCategory,
                decoration:
                    InputDecoration(
                  labelText:
                      'Shop Category *',
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
                items:
                    categories.map(
                  (category) {
                    return DropdownMenuItem<
                        String>(
                      value: category,
                      child:
                          Text(category),
                    );
                  },
                ).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory =
                        value;
                  });
                },
                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return 'Please select category';
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 14,
              ),

              optionalField(
                label: 'Description',
                controller:
                    descriptionController,
                maxLines: 4,
              ),

              // ==================================================
              // OWNER
              // ==================================================

              sectionTitle(
                'Owner Information',
              ),

              requiredField(
                label: 'Owner Name *',
                controller:
                    ownerNameController,
              ),

              requiredField(
                label: 'Owner Email *',
                controller:
                    ownerEmailController,
                keyboardType:
                    TextInputType.emailAddress,
              ),

              requiredField(
                label: 'Phone Number *',
                controller:
                    phoneController,
                keyboardType:
                    TextInputType.phone,
              ),

              optionalField(
                label: 'WhatsApp',
                controller:
                    whatsappController,
                keyboardType:
                    TextInputType.phone,
              ),

              // ==================================================
              // ADDRESS
              // ==================================================

              sectionTitle(
                'Address',
              ),

              requiredField(
                label: 'Address *',
                controller:
                    addressController,
                maxLines: 2,
              ),

              requiredField(
                label: 'Area / Locality *',
                controller:
                    localityController,
              ),

              requiredField(
                label: 'City *',
                controller:
                    cityController,
              ),

              optionalField(
                label: 'District',
                controller:
                    districtController,
              ),

              optionalField(
                label: 'State',
                controller:
                    stateController,
              ),

              requiredField(
                label: 'Pincode *',
                controller:
                    pincodeController,
                keyboardType:
                    TextInputType.number,
              ),

              // ==================================================
              // LOCATION
              // ==================================================

              sectionTitle(
                'Shop Location',
              ),

              locationSection(),

              // ==================================================
              // OPENING HOURS
              // ==================================================

              sectionTitle(
                'Opening Hours',
              ),

              SwitchListTile(
                contentPadding:
                    EdgeInsets.zero,
                title:
                    const Text(
                  'Open 24 Hours',
                ),
                value:
                    open24Hours,
                onChanged: (value) {
                  setState(() {
                    open24Hours =
                        value;
                  });
                },
              ),

              if (!open24Hours) ...[
                GestureDetector(
                  onTap:
                      selectOpeningTime,
                  child:
                      AbsorbPointer(
                    child:
                        optionalField(
                      label:
                          'Opening Time',
                      controller:
                          openingTimeController,
                    ),
                  ),
                ),

                GestureDetector(
                  onTap:
                      selectClosingTime,
                  child:
                      AbsorbPointer(
                    child:
                        optionalField(
                      label:
                          'Closing Time',
                      controller:
                          closingTimeController,
                    ),
                  ),
                ),
              ],

              const Text(
                'Working Days',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              workingDaysSection(),

              // ==================================================
              // ONLINE DETAILS
              // ==================================================

              sectionTitle(
                'Online Details',
              ),

              optionalField(
                label: 'Website',
                controller:
                    websiteController,
                keyboardType:
                    TextInputType.url,
              ),

              optionalField(
                label: 'Instagram',
                controller:
                    instagramController,
              ),

              optionalField(
                label: 'Facebook',
                controller:
                    facebookController,
              ),

              // ==================================================
              // FACILITIES
              // ==================================================

              sectionTitle(
                'Facilities',
              ),

              facilitiesSection(),

              // ==================================================
              // OFFERS
              // ==================================================

              sectionTitle(
                'Offers & Advertisement',
              ),

              SwitchListTile(
                contentPadding:
                    EdgeInsets.zero,
                title:
                    const Text(
                  'Offers Available',
                ),
                value:
                    offersAvailable,
                onChanged: (value) {
                  setState(() {
                    offersAvailable =
                        value;
                  });
                },
              ),

              SwitchListTile(
                contentPadding:
                    EdgeInsets.zero,
                title:
                    const Text(
                  'Discount Available',
                ),
                value:
                    discountAvailable,
                onChanged: (value) {
                  setState(() {
                    discountAvailable =
                        value;
                  });
                },
              ),

              optionalField(
                label:
                    'Advertisement Radius (meters)',
                controller:
                    radiusController,
                keyboardType:
                    TextInputType.number,
              ),

              // ==================================================
              // CONFIRMATION
              // ==================================================

              sectionTitle(
                'Confirmation',
              ),

              CheckboxListTile(
                contentPadding:
                    EdgeInsets.zero,
                title:
                    const Text(
                  'I confirm that the above shop details are correct.',
                ),
                value: confirmed,
                onChanged: (value) {
                  setState(() {
                    confirmed =
                        value ?? false;
                  });
                },
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // SUBMIT
              // ==================================================

              SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      isSubmitting ||
                              !confirmed
                          ? null
                          : submitShop,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                          ),
                        )
                      : const Text(
                          'Submit Shop for Approval',
                          style:
                              TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
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
      ),
    );
  }
}
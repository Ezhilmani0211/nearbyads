import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AddAdvertisementScreen extends StatefulWidget {
  final String ownerEmail;

  const AddAdvertisementScreen({
    super.key,
    required this.ownerEmail,
  });

  @override
  State<AddAdvertisementScreen> createState() =>
      _AddAdvertisementScreenState();
}

class _AddAdvertisementScreenState
    extends State<AddAdvertisementScreen> {
  static const Color primaryBlue =
      Color(0xFF1976D2);

  static const Color darkBlue =
      Color(0xFF0D47A1);

  static const Color purple =
      Color(0xFF7B1FA2);

  final formKey =
      GlobalKey<FormState>();

  final titleController =
      TextEditingController();

  final descriptionController =
      TextEditingController();

  final discountController =
      TextEditingController();

  final radiusController =
      TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  List<Map<String, dynamic>> shops = [];

  String? selectedShopId;

  bool loadingShops = true;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    loadShops();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    discountController.dispose();
    radiusController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD OWNER SHOPS
  // ============================================================

  Future<void> loadShops() async {
    setState(() {
      loadingShops = true;
    });

    try {
      final data =
          await ApiService.getMyShops(
        ownerEmail: widget.ownerEmail,
      );

      final List<dynamic> shopList =
          data['shops'] ?? [];

      final loadedShops =
          shopList
              .map(
                (shop) =>
                    Map<String, dynamic>.from(
                  shop,
                ),
              )
              .where(
                (shop) =>
                    shop['status']
                        ?.toString()
                        .toLowerCase() ==
                    'approved',
              )
              .toList();

      if (!mounted) return;

      setState(() {
        shops = loadedShops;
        loadingShops = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingShops = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load shops: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // START DATE
  // ============================================================

  Future<void> selectStartDate() async {
    final today = DateTime.now();

    final picked =
        await showDatePicker(
      context: context,
      initialDate:
          startDate != null &&
                  startDate!.isAfter(today)
              ? startDate!
              : today,
      firstDate: today,
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        startDate = picked;

        if (endDate != null &&
            endDate!.isBefore(picked)) {
          endDate = null;
        }
      });
    }
  }

  // ============================================================
  // END DATE
  // ============================================================

  Future<void> selectEndDate() async {
    final today = DateTime.now();

    final firstDate =
        startDate ?? today;

    final picked =
        await showDatePicker(
      context: context,
      initialDate:
          endDate != null &&
                  !endDate!.isBefore(firstDate)
              ? endDate!
              : firstDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        endDate = picked;
      });
    }
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String formatDate(DateTime? date) {
    if (date == null) {
      return 'Select date';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> submitAdvertisement() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (selectedShopId == null ||
        selectedShopId!.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text('Please select a shop.'),
        ),
      );
      return;
    }

    if (startDate == null ||
        endDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please select start and end date.',
          ),
        ),
      );
      return;
    }

    if (endDate!.isBefore(startDate!)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'End date must be after start date.',
          ),
        ),
      );
      return;
    }

    final discount =
        double.tryParse(
      discountController.text.trim(),
    );

    final radius =
        double.tryParse(
      radiusController.text.trim(),
    );

    if (discount == null ||
        discount < 0 ||
        discount > 100) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid discount between 0 and 100.',
          ),
        ),
      );
      return;
    }

    if (radius == null ||
        radius <= 0) {
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
      submitting = true;
    });

    try {
      final result =
          await ApiService.createAdvertisement(
        ownerEmail:
            widget.ownerEmail,
        shopId:
            selectedShopId!,
        title:
            titleController.text.trim(),
        description:
            descriptionController.text.trim(),
        discount:
            discount,
        radius:
            radius,
        startDate:
            startDate!.toIso8601String(),
        endDate:
            endDate!.toIso8601String(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ??
                'Advertisement submitted for approval.',
          ),
          backgroundColor:
              Colors.green,
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          submitting = false;
        });
      }
    }
  }

  // ============================================================
  // FIELD DECORATION
  // ============================================================

  InputDecoration fieldDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: primaryBlue,
      ),
      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide:
            const BorderSide(
          color: primaryBlue,
          width: 2,
        ),
      ),
    );
  }

  // ============================================================
  // DATE FIELD
  // ============================================================

  Widget dateField({
    required String label,
    required IconData icon,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(12),
      child: InputDecorator(
        decoration:
            fieldDecoration(
          label,
          icon,
        ),
        child: Text(
          formatDate(value),
          style: TextStyle(
            color: value == null
                ? Colors.grey
                : Colors.black,
          ),
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
            const Text(
          'Add Advertisement',
        ),
        centerTitle: true,
      ),

      body: loadingShops
          ? const Center(
              child:
                  CircularProgressIndicator(
                color: primaryBlue,
              ),
            )
          : shops.isEmpty
              ? _buildNoShops()
              : Form(
                  key: formKey,
                  child: ListView(
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior
                            .onDrag,
                    children: [
                      const Text(
                        'Advertisement Details',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,
                          color: darkBlue,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        'Owner: ${widget.ownerEmail}',
                        style: TextStyle(
                          color:
                              Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      // ==================================================
                      // SHOP
                      // ==================================================

                      DropdownButtonFormField<
                          String>(
                        initialValue:
                            selectedShopId,
                        decoration:
                            fieldDecoration(
                          'Select Shop *',
                          Icons.store,
                        ),
                        items:
                            shops.map(
                          (shop) {
                            final id =
                                shop['_id']
                                        ?.toString() ??
                                    shop['id']
                                        ?.toString();

                            final name =
                                shop['shop_name']
                                        ?.toString() ??
                                    'Shop';

                            return DropdownMenuItem<
                                String>(
                              value: id,
                              child: Text(
                                name,
                              ),
                            );
                          },
                        ).toList(),
                        onChanged:
                            submitting
                                ? null
                                : (value) {
                                    setState(() {
                                      selectedShopId =
                                          value;
                                    });
                                  },
                        validator:
                            (value) {
                          if (value ==
                              null) {
                            return 'Select a shop';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // TITLE
                      // ==================================================

                      TextFormField(
                        controller:
                            titleController,
                        textInputAction:
                            TextInputAction.next,
                        decoration:
                            fieldDecoration(
                          'Advertisement Title *',
                          Icons
                              .campaign_outlined,
                        ),
                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Enter advertisement title';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // DESCRIPTION
                      // ==================================================

                      TextFormField(
                        controller:
                            descriptionController,
                        maxLines: 4,
                        decoration:
                            fieldDecoration(
                          'Description *',
                          Icons
                              .description_outlined,
                        ),
                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Enter advertisement description';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // DISCOUNT
                      // ==================================================

                      TextFormField(
                        controller:
                            discountController,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                            fieldDecoration(
                          'Discount (%) *',
                          Icons
                              .local_offer_outlined,
                        ),
                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Enter discount';
                          }

                          final discount =
                              double.tryParse(
                            value.trim(),
                          );

                          if (discount ==
                              null) {
                            return 'Enter a valid discount';
                          }

                          if (discount <
                                  0 ||
                              discount >
                                  100) {
                            return 'Discount must be 0-100';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // RADIUS
                      // ==================================================

                      TextFormField(
                        controller:
                            radiusController,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                            fieldDecoration(
                          'Offer Radius (meters) *',
                          Icons.radar,
                        ),
                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Enter offer radius';
                          }

                          final radius =
                              double.tryParse(
                            value.trim(),
                          );

                          if (radius ==
                                  null ||
                              radius <= 0) {
                            return 'Enter a valid radius';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 28,
                      ),

                      // ==================================================
                      // OFFER PERIOD
                      // ==================================================

                      const Text(
                        'Offer Period',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                          color: darkBlue,
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      dateField(
                        label:
                            'Start Date *',
                        icon:
                            Icons.calendar_today,
                        value:
                            startDate,
                        onTap:
                            selectStartDate,
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      dateField(
                        label:
                            'End Date *',
                        icon:
                            Icons.event,
                        value:
                            endDate,
                        onTap:
                            selectEndDate,
                      ),

                      const SizedBox(
                        height: 30,
                      ),

                      // ==================================================
                      // SUBMIT
                      // ==================================================

                      SizedBox(
                        height: 52,
                        child:
                            DecoratedBox(
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
                                BorderRadius
                                    .circular(
                              14,
                            ),
                          ),
                          child:
                              ElevatedButton
                                  .icon(
                            onPressed:
                                submitting
                                    ? null
                                    : submitAdvertisement,
                            icon: submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons
                                        .send,
                                  ),
                            label: Text(
                              submitting
                                  ? 'Submitting...'
                                  : 'Submit for Approval',
                              style:
                                  const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  Colors.transparent,
                              shadowColor:
                                  Colors.transparent,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 25,
                      ),
                    ],
                  ),
                ),
    );
  }

  // ============================================================
  // NO APPROVED SHOPS
  // ============================================================

  Widget _buildNoShops() {
    return RefreshIndicator(
      onRefresh: loadShops,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(24),
        children: [
          const SizedBox(
            height: 130,
          ),
          Icon(
            Icons.store_outlined,
            size: 75,
            color: primaryBlue,
          ),
          const SizedBox(
            height: 18,
          ),
          const Center(
            child: Text(
              'No Approved Shops',
              style: TextStyle(
                fontSize: 21,
                fontWeight:
                    FontWeight.bold,
                color: darkBlue,
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Center(
            child: Text(
              'You need an approved shop before creating an advertisement.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(
            height: 22,
          ),
          Center(
            child:
                OutlinedButton.icon(
              onPressed: loadShops,
              icon:
                  const Icon(
                Icons.refresh,
              ),
              label:
                  const Text(
                'Refresh',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
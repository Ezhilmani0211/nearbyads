import 'package:flutter/material.dart';

import '../services/api_service.dart';

class EditAdvertisementScreen extends StatefulWidget {
  final Map<String, dynamic> ad;

  const EditAdvertisementScreen({
    super.key,
    required this.ad,
  });

  @override
  State<EditAdvertisementScreen> createState() =>
      _EditAdvertisementScreenState();
}

class _EditAdvertisementScreenState
    extends State<EditAdvertisementScreen> {
  static const Color primaryBlue =
      Color(0xFF1976D2);

  static const Color darkBlue =
      Color(0xFF0D47A1);

  final formKey =
      GlobalKey<FormState>();

  late final TextEditingController
      titleController;

  late final TextEditingController
      descriptionController;

  late final TextEditingController
      discountController;

  late final TextEditingController
      radiusController;

  late final TextEditingController
      startDateController;

  late final TextEditingController
      endDateController;

  bool updating = false;

  @override
  void initState() {
    super.initState();

    titleController =
        TextEditingController(
      text:
          (widget.ad['title'] ?? '')
              .toString(),
    );

    descriptionController =
        TextEditingController(
      text:
          (widget.ad['description'] ??
                  '')
              .toString(),
    );

    discountController =
        TextEditingController(
      text:
          (widget.ad['discount'] ?? '')
              .toString(),
    );

    radiusController =
        TextEditingController(
      text:
          (widget.ad['radius'] ?? '')
              .toString(),
    );

    startDateController =
        TextEditingController(
      text: _formatInitialDate(
        widget.ad['start_date'],
      ),
    );

    endDateController =
        TextEditingController(
      text: _formatInitialDate(
        widget.ad['end_date'],
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    discountController.dispose();
    radiusController.dispose();
    startDateController.dispose();
    endDateController.dispose();

    super.dispose();
  }

  // ============================================================
  // INITIAL DATE
  // ============================================================

  String _formatInitialDate(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    final text =
        value.toString().trim();

    if (text.isEmpty) {
      return '';
    }

    try {
      final date =
          DateTime.parse(text);

      return '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      if (text.contains('T')) {
        return text.split('T').first;
      }

      return text;
    }
  }

  // ============================================================
  // SELECT DATE
  // ============================================================

  Future<void> selectDate({
    required bool isStartDate,
  }) async {
    final currentValue =
        isStartDate
            ? startDateController.text
            : endDateController.text;

    DateTime initialDate =
        DateTime.now();

    if (currentValue.isNotEmpty) {
      try {
        initialDate =
            DateTime.parse(
          currentValue,
        );
      } catch (_) {}
    }

    final today =
        DateTime.now();

    if (initialDate.isBefore(today)) {
      initialDate = today;
    }

    final picked =
        await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate:
          DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    final formatted =
        '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';

    setState(() {
      if (isStartDate) {
        startDateController.text =
            formatted;

        final existingEnd =
            endDateController
                .text
                .trim();

        if (existingEnd.isNotEmpty) {
          try {
            final end =
                DateTime.parse(
              existingEnd,
            );

            if (end.isBefore(
              picked,
            )) {
              endDateController
                  .clear();
            }
          } catch (_) {}
        }
      } else {
        endDateController.text =
            formatted;
      }
    });
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<void>
      updateAdvertisement() async {
    if (!formKey.currentState!
        .validate()) {
      return;
    }

    final adId =
        (widget.ad['id'] ??
                widget.ad['_id'] ??
                '')
            .toString();

    if (adId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Advertisement ID not found.',
          ),
        ),
      );
      return;
    }

    final discount =
        double.tryParse(
      discountController.text
          .trim(),
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
            'Enter a valid radius greater than 0.',
          ),
        ),
      );
      return;
    }

    final startDate =
        startDateController.text
            .trim();

    final endDate =
        endDateController.text.trim();

    if (startDate.isEmpty ||
        endDate.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please select start and end dates.',
          ),
        ),
      );
      return;
    }

    try {
      final start =
          DateTime.parse(
        startDate,
      );

      final end =
          DateTime.parse(
        endDate,
      );

      if (end.isBefore(start)) {
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
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid date format.',
          ),
        ),
      );
      return;
    }

    setState(() {
      updating = true;
    });

    try {
      final result =
          await ApiService
              .updateAdvertisement(
        adId: adId,
        title:
            titleController.text
                .trim(),
        description:
            descriptionController
                .text
                .trim(),
        discount: discount,
        radius: radius,
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ??
                'Advertisement updated and submitted for approval.',
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
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update advertisement: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          updating = false;
        });
      }
    }
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration inputDecoration(
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
            BorderRadius.circular(
          12,
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        borderSide:
            const BorderSide(
          color: primaryBlue,
          width: 2,
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
    final status =
        (widget.ad['status'] ??
                'pending')
            .toString()
            .toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Edit Advertisement',
        ),
        centerTitle: true,
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

            if (status == 'approved')
              Container(
                margin:
                    const EdgeInsets.only(
                  top: 12,
                  bottom: 18,
                ),
                padding:
                    const EdgeInsets.all(
                  12,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.orange
                      .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    10,
                  ),
                ),
                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color:
                          Colors.orange,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: Text(
                        'Editing an approved advertisement will send it for admin approval again.',
                        style:
                            TextStyle(
                          color:
                              Colors.orange,
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
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
                  inputDecoration(
                'Advertisement Title *',
                Icons.campaign_outlined,
              ),
              validator:
                  (value) {
                if (value == null ||
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
                  inputDecoration(
                'Description *',
                Icons.description_outlined,
              ),
              validator:
                  (value) {
                if (value == null ||
                    value
                        .trim()
                        .isEmpty) {
                  return 'Enter description';
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
                  inputDecoration(
                'Discount (%) *',
                Icons.local_offer_outlined,
              ),
              validator:
                  (value) {
                if (value == null ||
                    value
                        .trim()
                        .isEmpty) {
                  return 'Enter discount';
                }

                final number =
                    double.tryParse(
                  value.trim(),
                );

                if (number == null) {
                  return 'Enter a valid number';
                }

                if (number < 0 ||
                    number > 100) {
                  return 'Discount must be between 0 and 100';
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
                  inputDecoration(
                'Offer Radius (meters) *',
                Icons.radar,
              ),
              validator:
                  (value) {
                if (value == null ||
                    value
                        .trim()
                        .isEmpty) {
                  return 'Enter offer radius';
                }

                final number =
                    double.tryParse(
                  value.trim(),
                );

                if (number == null) {
                  return 'Enter a valid number';
                }

                if (number <= 0) {
                  return 'Radius must be greater than 0';
                }

                return null;
              },
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // START DATE
            // ==================================================

            TextFormField(
              controller:
                  startDateController,
              readOnly: true,
              onTap:
                  updating
                      ? null
                      : () {
                          selectDate(
                            isStartDate:
                                true,
                          );
                        },
              decoration:
                  inputDecoration(
                'Start Date *',
                Icons.calendar_today,
              ),
              validator:
                  (value) {
                if (value == null ||
                    value
                        .trim()
                        .isEmpty) {
                  return 'Select start date';
                }

                return null;
              },
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // END DATE
            // ==================================================

            TextFormField(
              controller:
                  endDateController,
              readOnly: true,
              onTap:
                  updating
                      ? null
                      : () {
                          selectDate(
                            isStartDate:
                                false,
                          );
                        },
              decoration:
                  inputDecoration(
                'End Date *',
                Icons.event,
              ),
              validator:
                  (value) {
                if (value == null ||
                    value
                        .trim()
                        .isEmpty) {
                  return 'Select end date';
                }

                return null;
              },
            ),

            const SizedBox(
              height: 28,
            ),

            // ==================================================
            // UPDATE BUTTON
            // ==================================================

            SizedBox(
              height: 52,
              child:
                  ElevatedButton.icon(
                onPressed:
                    updating
                        ? null
                        : updateAdvertisement,
                icon: updating
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
                        Icons.save,
                      ),
                label: Text(
                  updating
                      ? 'Updating...'
                      : 'Update Advertisement',
                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
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
}
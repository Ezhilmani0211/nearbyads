import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class ApprovalStatusScreen
    extends StatefulWidget {
  const ApprovalStatusScreen({
    super.key,
  });

  @override
  State<ApprovalStatusScreen> createState() =>
      _ApprovalStatusScreenState();
}

class _ApprovalStatusScreenState
    extends State<ApprovalStatusScreen> {
  static const Color primaryBlue =
      Color(0xFF1976D2);

  static const Color darkBlue =
      Color(0xFF0D47A1);

  static const Color purple =
      Color(0xFF7B1FA2);

  String ownerEmail = '';

  bool isLoading = true;

  String? errorMessage;

  List<Map<String, dynamic>> shops = [];

  @override
  void initState() {
    super.initState();
    loadOwner();
  }

  Future<void> loadOwner() async {
    final prefs =
        await SharedPreferences.getInstance();

    ownerEmail =
        prefs.getString('user_email') ??
            '';

    if (ownerEmail.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage =
            'Owner email not found.';
      });
      return;
    }

    await loadStatus();
  }

  Future<void> loadStatus() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result =
          await ApiService.getMyShops(
        ownerEmail: ownerEmail,
      );

      final list =
          result['shops'] ?? [];

      final loaded =
          (list as List)
              .map(
                (item) =>
                    Map<String, dynamic>.from(
                  item,
                ),
              )
              .toList();

      if (!mounted) return;

      setState(() {
        shops = loaded;
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

  Color statusColor(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;

      case 'rejected':
        return Colors.red;

      default:
        return purple;
    }
  }

  IconData statusIcon(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;

      case 'rejected':
        return Icons.cancel;

      default:
        return Icons.hourglass_top_rounded;
    }
  }

  Widget buildStatusCard(
    Map<String, dynamic> shop,
  ) {
    final name =
        shop['shop_name']?.toString() ??
            'Unnamed Shop';

    final category =
        shop['category']?.toString() ??
            '';

    final status =
        shop['status']?.toString() ??
            'pending';

    final color =
        statusColor(status);

    return Container(
      margin:
          const EdgeInsets.only(bottom: 16),
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
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
                      BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.storefront,
                  color: Colors.white,
                  size: 29,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                        color: darkBlue,
                      ),
                    ),
                    if (category.isNotEmpty)
                      Text(
                        category,
                        style: TextStyle(
                          color: Colors
                              .grey
                              .shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(15),
            decoration:
                BoxDecoration(
              color: color.withValues(
                alpha: 0.08,
              ),
              borderRadius:
                  BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(
                  alpha: 0.25,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  statusIcon(status),
                  color: color,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        status.toLowerCase() ==
                                'approved'
                            ? 'Your shop has been approved.'
                            : status.toLowerCase() ==
                                    'rejected'
                                ? 'Your shop was rejected.'
                                : 'Your shop is waiting for admin approval.',
                        style: TextStyle(
                          color:
                              Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Approval Status'),
        actions: [
          IconButton(
            onPressed:
                isLoading
                    ? null
                    : loadStatus,
            icon:
                const Icon(Icons.refresh),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: loadStatus,

        child: Builder(
          builder: (_) {
            if (isLoading) {
              return const Center(
                child:
                    CircularProgressIndicator(
                  color: primaryBlue,
                ),
              );
            }

            if (errorMessage != null) {
              return ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 150),
                  const Icon(
                    Icons.error_outline,
                    size: 65,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: Text(
                      errorMessage!,
                      textAlign:
                          TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          loadStatus,
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

            if (shops.isEmpty) {
              return ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 160),
                  const Icon(
                    Icons.assignment_outlined,
                    size: 75,
                    color: primaryBlue,
                  ),
                  const SizedBox(height: 18),
                  const Center(
                    child: Text(
                      'No Approval Requests',
                      style:
                          TextStyle(
                        fontSize: 21,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Submitted shops will appear here.',
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.all(16),
              children: [
                const Text(
                  'Shop Approval Status',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight:
                        FontWeight.bold,
                    color: darkBlue,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Track the approval status of your submitted shops.',
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 20),

                ...shops.map(
                  buildStatusCard,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
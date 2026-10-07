import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminPendingShopsScreen extends StatefulWidget {
  const AdminPendingShopsScreen({super.key});

  @override
  State<AdminPendingShopsScreen> createState() =>
      _AdminPendingShopsScreenState();
}

class _AdminPendingShopsScreenState
    extends State<AdminPendingShopsScreen> {
  bool loading = true;
  String? errorMessage;
  List<dynamic> shops = [];

  @override
  void initState() {
    super.initState();
    loadPendingShops();
  }

  Future<void> loadPendingShops() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getPendingShops();

      if (!mounted) return;

      setState(() {
        shops = result['shops'] ?? [];
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

  Future<void> approveShop(String shopId) async {
    try {
      await ApiService.approveShop(shopId: shopId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop approved successfully'),
          backgroundColor: Colors.green,
        ),
      );

      loadPendingShops();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Approval failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> rejectShop(String shopId) async {
    try {
      await ApiService.rejectShop(shopId: shopId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop rejected'),
          backgroundColor: Colors.red,
        ),
      );

      loadPendingShops();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rejection failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> confirmApprove(String shopId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Approve Shop'),
          content: const Text(
            'Are you sure you want to approve this shop?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await approveShop(shopId);
    }
  }

  Future<void> confirmReject(String shopId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Shop'),
          content: const Text(
            'Are you sure you want to reject this shop?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await rejectShop(shopId);
    }
  }

  Widget buildShopCard(dynamic shop) {
    final shopId =
        (shop['id'] ?? shop['_id'] ?? '').toString();

    final shopName =
        (shop['shop_name'] ?? shop['name'] ?? 'Shop').toString();

    final category =
        (shop['category'] ?? '').toString();

    final description =
        (shop['description'] ?? '').toString();

    final ownerName =
        (shop['owner_name'] ?? '').toString();

    final ownerEmail =
        (shop['owner_email'] ?? '').toString();

    final phone =
        (shop['phone'] ?? '').toString();

    final address =
        (shop['address'] ?? '').toString();

    final locality =
        (shop['locality'] ?? '').toString();

    final city =
        (shop['city'] ?? '').toString();

    final pincode =
        (shop['pincode'] ?? '').toString();

    final shopImages =
        shop['shop_images'] is List
            ? List<dynamic>.from(shop['shop_images'])
            : <dynamic>[];

    String imageUrl = '';

    if (shopImages.isNotEmpty) {
      imageUrl = shopImages.first.toString();
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
                          Icons.store,
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
                    shopName,
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
                        Colors.orange.withValues(alpha: 0.12),
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

            const SizedBox(height: 8),

            if (category.isNotEmpty)
              Row(
                children: [
                  const Icon(
                    Icons.category,
                    size: 18,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
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

            _detailRow(
              Icons.person,
              'Owner',
              ownerName,
            ),

            if (ownerEmail.isNotEmpty)
              _detailRow(
                Icons.email,
                'Email',
                ownerEmail,
              ),

            if (phone.isNotEmpty)
              _detailRow(
                Icons.phone,
                'Phone',
                phone,
              ),

            if (address.isNotEmpty)
              _detailRow(
                Icons.location_on,
                'Address',
                address,
              ),

            if (locality.isNotEmpty)
              _detailRow(
                Icons.place,
                'Locality',
                locality,
              ),

            if (city.isNotEmpty)
              _detailRow(
                Icons.location_city,
                'City',
                city,
              ),

            if (pincode.isNotEmpty)
              _detailRow(
                Icons.pin_drop,
                'Pincode',
                pincode,
              ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: shopId.isEmpty
                        ? null
                        : () => confirmApprove(shopId),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: shopId.isEmpty
                        ? null
                        : () => confirmReject(shopId),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
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
      padding: const EdgeInsets.only(bottom: 9),
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
        title: const Text('Pending Shops'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: loading
                ? null
                : loadPendingShops,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
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
                          'Failed to load pending shops',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: loadPendingShops,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : shops.isEmpty
                  ? RefreshIndicator(
                      onRefresh: loadPendingShops,
                      child: ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 150),
                          Icon(
                            Icons.store_outlined,
                            size: 70,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 15),
                          Center(
                            child: Text(
                              'No Pending Shops',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Center(
                            child: Text(
                              'All shops have been reviewed.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadPendingShops,
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.all(16),
                        itemCount: shops.length,
                        itemBuilder:
                            (context, index) {
                          return buildShopCard(
                            shops[index],
                          );
                        },
                      ),
                    ),
    );
  }
}
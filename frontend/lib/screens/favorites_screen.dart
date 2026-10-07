
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';
import 'offers_screen.dart';
import 'profile_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() =>
      _FavoritesScreenState();
}

class _FavoritesScreenState
    extends State<FavoritesScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryBlue =
      Color(0xFF1976D2);

  static const Color darkBlue =
      Color(0xFF0D47A1);

  static const Color lightBlue =
      Color(0xFFE3F2FD);

  static const Color purple =
      Color(0xFF7B1FA2);

  // ============================================================
  // STATE
  // ============================================================

  List<Map<String, dynamic>> _favorites =
      <Map<String, dynamic>>[];

  bool _isLoading = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  // ============================================================
  // LOAD FAVORITES
  // ============================================================

  Future<void> _loadFavorites() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    final List<String> data =
        prefs.getStringList('favorite_shops') ?? [];

    if (data.isEmpty) {
      if (!mounted) return;

      setState(() {
        _favorites =
            <Map<String, dynamic>>[];
        _isLoading = false;
      });

      return;
    }

    try {
      final List<Map<String, dynamic>> shops =
          data
              .map(
                (item) =>
                    Map<String, dynamic>.from(
                  jsonDecode(item),
                ),
              )
              .toList();

      if (!mounted) return;

      setState(() {
        _favorites = shops;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _favorites =
            <Map<String, dynamic>>[];
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // REMOVE FAVORITE
  // ============================================================

  Future<void> _removeFavorite(
    int index,
  ) async {
    if (index < 0 ||
        index >= _favorites.length) {
      return;
    }

    final Map<String, dynamic> shop =
        _favorites[index];

    final String name =
        (
          shop['shop_name'] ??
              shop['name'] ??
              'Shop'
        ).toString();

    setState(() {
      _favorites.removeAt(index);
    });

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setStringList(
      'favorite_shops',
      _favorites
          .map(
            (shop) => jsonEncode(shop),
          )
          .toList(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '$name removed from favorites.',
        ),
        backgroundColor: darkBlue,
        behavior:
            SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _shopName(
    Map<String, dynamic> shop,
  ) {
    return (
      shop['shop_name'] ??
          shop['name'] ??
          'Unknown Shop'
    ).toString();
  }

  String _category(
    Map<String, dynamic> shop,
  ) {
    return (
      shop['category'] ??
          'Shop'
    ).toString();
  }

  String _address(
    Map<String, dynamic> shop,
  ) {
    return (
      shop['address'] ??
          'Address unavailable'
    ).toString();
  }

  // ============================================================
  // OPEN SHOP
  // ============================================================

  void _openShop(
    Map<String, dynamic> shop,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          key: ValueKey(
            'favorite-${shop['id'] ?? shop['_id'] ?? _shopName(shop)}',
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SHOP CARD
  // ============================================================

  Widget _buildFavoriteCard(
    Map<String, dynamic> shop,
    int index,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      elevation: 2,
      shadowColor:
          primaryBlue.withValues(
        alpha: 0.12,
      ),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: () {
          _openShop(shop);
        },
        child: Padding(
          padding:
              const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              // SHOP ICON
              Container(
                width: 58,
                height: 58,
                decoration:
                    BoxDecoration(
                  gradient:
                      const LinearGradient(
                    begin:
                        Alignment.topLeft,
                    end:
                        Alignment.bottomRight,
                    colors: [
                      primaryBlue,
                      purple,
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              // DETAILS
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _shopName(shop),
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFF222222),
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    // CATEGORY
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration:
                          BoxDecoration(
                        color: lightBlue,
                        borderRadius:
                            BorderRadius
                                .circular(
                          8,
                        ),
                      ),
                      child: Text(
                        _category(shop),
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color:
                              darkBlue,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    Row(
                      children: [
                        const Icon(
                          Icons
                              .location_on_outlined,
                          size: 16,
                          color:
                              primaryBlue,
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Expanded(
                          child: Text(
                            _address(shop),
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                TextStyle(
                              color: Colors
                                  .grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              // REMOVE FAVORITE
              IconButton(
                tooltip:
                    'Remove from favorites',
                onPressed: () {
                  _removeFavorite(index);
                },
                icon: const Icon(
                  Icons.favorite_rounded,
                  color: purple,
                  size: 27,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadFavorites,
      color: primaryBlue,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(
            height: 145,
          ),

          Container(
            width: 110,
            height: 110,
            margin:
                const EdgeInsets.symmetric(
              horizontal: 125,
            ),
            decoration:
                BoxDecoration(
              gradient:
                  const LinearGradient(
                begin:
                    Alignment.topLeft,
                end:
                    Alignment.bottomRight,
                colors: [
                  lightBlue,
                  Color(0xFFF3E5F5),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 58,
              color: purple,
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          const Center(
            child: Text(
              'No Favorites Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
                color:
                    Color(0xFF222222),
              ),
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 35,
            ),
            child: Text(
              'Favorite shops from the map will appear here.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color:
                    Colors.grey.shade600,
              ),
            ),
          ),

          const SizedBox(
            height: 25,
          ),

          Center(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const HomeScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.map_outlined,
              ),
              label: const Text(
                'Explore Nearby Shops',
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
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _onNavigationChanged(
    int index,
  ) {
    if (index == 2) {
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

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const OffersScreen(),
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
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F8FA),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        title: const Text(
          'Favorites',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor:
            darkBlue,
        foregroundColor:
            Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip:
                'Refresh favorites',
            onPressed:
                _isLoading
                    ? null
                    : _loadFavorites,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color: primaryBlue,
              ),
            )
          : _favorites.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh:
                      _loadFavorites,
                  color: primaryBlue,
                  child:
                      ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets
                            .all(16),
                    itemCount:
                        _favorites.length,
                    itemBuilder:
                        (
                      BuildContext
                          context,
                      int index,
                    ) {
                      return _buildFavoriteCard(
                        _favorites[index],
                        index,
                      );
                    },
                  ),
                ),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================

      bottomNavigationBar:
          NavigationBar(
        backgroundColor:
            Colors.white,
        selectedIndex: 2,
        indicatorColor:
            lightBlue,
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
              color: purple,
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
}


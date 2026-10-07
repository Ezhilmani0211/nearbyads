import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() =>
      _AdminUsersScreenState();
}

class _AdminUsersScreenState
    extends State<AdminUsersScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response =
          await ApiService.getAdminUsers();

      final users = response['users'];

      if (!mounted) return;

      setState(() {
        _users = users is List ? users : [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'shop_owner':
        return 'Shop Owner';
      default:
        return 'User';
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'shop_owner':
        return Icons.store;
      default:
        return Icons.person;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'shop_owner':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Widget _userCard(
    Map<String, dynamic> user,
  ) {
    final String name =
        user['full_name']?.toString() ?? '';

    final String email =
        user['email']?.toString() ?? '';

    final String role =
        user['role']?.toString() ?? 'user';

    final bool emailVerified =
        user['email_verified'] == true;

    final Color roleColor =
        _roleColor(role);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor:
                      roleColor.withValues(alpha: 0.12),
                  child: Icon(
                    _roleIcon(role),
                    color: roleColor,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty
                            ? 'No Name'
                            : name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        roleColor.withValues(alpha: 0.10),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        _roleIcon(role),
                        size: 16,
                        color: roleColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _roleLabel(role),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: roleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: emailVerified
                        ? Colors.green.withValues(
                            alpha: 0.10,
                          )
                        : Colors.red.withValues(
                            alpha: 0.10,
                          ),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        emailVerified
                            ? Icons.verified
                            : Icons.warning_amber,
                        size: 16,
                        color: emailVerified
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        emailVerified
                            ? 'Verified'
                            : 'Not Verified',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: emailVerified
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _usersByRole(
    String role,
  ) {
    return _users
        .whereType<Map<String, dynamic>>()
        .where(
          (user) =>
              (user['role']?.toString() ?? 'user') ==
              role,
        )
        .toList();
  }

  Widget _usersSection(
    String title,
    String role,
    IconData icon,
    Color color,
  ) {
    final users = _usersByRole(role);

    if (users.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title,
          users.length,
          icon,
          color,
        ),
        ...users.map(
          (user) => _userCard(user),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 70,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 15),
            const Text(
              'No users found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no registered users yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 65,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 15),
            const Text(
              'Unable to load users',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ??
                  'Something went wrong.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _usersSection(
            'Users',
            'user',
            Icons.people,
            Colors.blue,
          ),
          _usersSection(
            'Shop Owners',
            'shop_owner',
            Icons.store,
            Colors.orange,
          ),
          _usersSection(
            'Admins',
            'admin',
            Icons.admin_panel_settings,
            Colors.red,
          ),
          if (_usersByRole('user').isEmpty &&
              _usersByRole('shop_owner').isEmpty &&
              _usersByRole('admin').isEmpty)
            _emptyState(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed:
                _isLoading ? null : _loadUsers,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh users',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? _errorState()
              : _buildUsersList(),
    );
  }
}
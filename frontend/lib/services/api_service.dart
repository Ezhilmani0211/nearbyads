import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
 static const String baseUrl = 'http://10.84.92.152:8001';

  static const Duration _timeout =
      Duration(seconds: 20);

  // ============================================================
  // COMMON HEADERS
  // ============================================================

  static Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // ============================================================
  // AUTH HEADERS
  // ============================================================

  static Future<Map<String, String>> _authHeaders() async {
    final prefs =
        await SharedPreferences.getInstance();

    final token =
        prefs.getString('access_token') ??
        prefs.getString('token') ??
        '';

    final headers = _headers();

    if (token.isNotEmpty) {
      headers['Authorization'] =
          'Bearer $token';
    }

    return headers;
  }

  // ============================================================
  // RESPONSE HANDLER
  // ============================================================

  static Future<Map<String, dynamic>> _handleResponse(
    http.Response response, {
    String defaultMessage = 'Request failed',
  }) async {
    dynamic data;

    try {
      data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {};
    } catch (_) {
      data = {};
    }

    debugPrint(
      'API RESPONSE => ${response.statusCode} ${response.body}',
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (data is Map<String, dynamic>) {
        return data;
      }

      return {
        'data': data,
      };
    }

    if (data is Map<String, dynamic>) {
      throw Exception(
        data['detail']?.toString() ??
            data['message']?.toString() ??
            defaultMessage,
      );
    }

    throw Exception(defaultMessage);
  }

  // ============================================================
  // GET
  // ============================================================

  static Future<Map<String, dynamic>> _get(
    String url, {
    String defaultMessage = 'Request failed',
    Map<String, String>? headers,
  }) async {
    try {
      debugPrint('API GET => $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: headers ?? _headers(),
          )
          .timeout(_timeout);

      return await _handleResponse(
        response,
        defaultMessage: defaultMessage,
      );
    } catch (e) {
      debugPrint('API GET ERROR => $e');

      if (e is Exception &&
          e.toString().startsWith('Exception: ')) {
        rethrow;
      }

      throw Exception(
        'Unable to connect to the server',
      );
    }
  }

  // ============================================================
  // POST
  // ============================================================

  static Future<Map<String, dynamic>> _post(
    String url, {
    Map<String, dynamic>? body,
    String defaultMessage = 'Request failed',
    Map<String, String>? headers,
  }) async {
    try {
      debugPrint('API POST => $url');
      debugPrint('API POST BODY => $body');

      final response = await http
          .post(
            Uri.parse(url),
            headers: headers ?? _headers(),
            body: body == null
                ? null
                : jsonEncode(body),
          )
          .timeout(_timeout);

      return await _handleResponse(
        response,
        defaultMessage: defaultMessage,
      );
    } catch (e) {
      debugPrint('API POST ERROR => $e');

      if (e is Exception &&
          e.toString().startsWith('Exception: ')) {
        rethrow;
      }

      throw Exception(
        'Unable to connect to the server',
      );
    }
  }

  // ============================================================
  // PUT
  // ============================================================

  static Future<Map<String, dynamic>> _put(
    String url, {
    Map<String, dynamic>? body,
    String defaultMessage = 'Request failed',
    Map<String, String>? headers,
  }) async {
    try {
      debugPrint('API PUT => $url');
      debugPrint('API PUT BODY => $body');

      final response = await http
          .put(
            Uri.parse(url),
            headers: headers ?? _headers(),
            body: body == null
                ? null
                : jsonEncode(body),
          )
          .timeout(_timeout);

      return await _handleResponse(
        response,
        defaultMessage: defaultMessage,
      );
    } catch (e) {
      debugPrint('API PUT ERROR => $e');

      if (e is Exception &&
          e.toString().startsWith('Exception: ')) {
        rethrow;
      }

      throw Exception(
        'Unable to connect to the server',
      );
    }
  }

  // ============================================================
  // TEMPORARY HEALTH TEST
  // ============================================================

  static Future<Map<String, dynamic>> testHealth() async {
    return _get(
      '$baseUrl/api/health',
      defaultMessage: 'Health check failed',
    );
  }

  // ============================================================
  // AUTH - LOGIN
  // ============================================================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return _post(
      '$baseUrl/api/auth/login',
      body: {
        'email': email,
        'password': password,
      },
      defaultMessage: 'Login failed',
    );
  }

  // ============================================================
  // AUTH - REGISTER
  // ============================================================

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    return _post(
      '$baseUrl/api/auth/register',
      body: {
        'full_name': name,
        'email': email,
        'password': password,
        'role': role,
      },
      defaultMessage: 'Registration failed',
    );
  }

  // ============================================================
  // AUTH - VERIFY EMAIL
  // ============================================================

  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String verificationCode,
  }) async {
    return _post(
      '$baseUrl/api/auth/verify-email',
      body: {
        'email': email,
        'verification_code': verificationCode,
      },
      defaultMessage:
          'Email verification failed',
    );
  }

  // ============================================================
  // AUTH - RESEND VERIFICATION
  // ============================================================

  static Future<Map<String, dynamic>>
      resendVerificationCode({
    required String email,
  }) async {
    return _post(
      '$baseUrl/api/auth/resend-verification',
      body: {
        'email': email,
      },
      defaultMessage:
          'Unable to resend verification code',
    );
  }

  // ============================================================
  // AUTH - CHANGE PASSWORD
  // ============================================================

  static Future<Map<String, dynamic>>
      changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      debugPrint(
        'API CHANGE PASSWORD => '
        '$baseUrl/api/auth/change-password',
      );

      final headers =
          await _authHeaders();

      final response = await http
          .put(
            Uri.parse(
              '$baseUrl/api/auth/change-password',
            ),
            headers: headers,
            body: jsonEncode({
              'email': email,
              'new_password': newPassword,
            }),
          )
          .timeout(_timeout);

      return await _handleResponse(
        response,
        defaultMessage:
            'Unable to change password',
      );
    } catch (e) {
      debugPrint(
        'API CHANGE PASSWORD ERROR => $e',
      );

      if (e is Exception &&
          e.toString().startsWith('Exception: ')) {
        rethrow;
      }

      throw Exception(
        'Unable to connect to the server',
      );
    }
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  static Future<Map<String, dynamic>>
      forgotPassword({
    required String email,
  }) async {
    return _post(
      '$baseUrl/api/auth/forgot-password',
      body: {
        'email': email,
      },
      defaultMessage:
          'Unable to send reset code',
    );
  }

  // ============================================================
  // VERIFY RESET CODE
  // ============================================================

  static Future<Map<String, dynamic>>
      verifyResetCode({
    required String email,
    required String resetCode,
  }) async {
    return _post(
      '$baseUrl/api/auth/verify-reset-code',
      body: {
        'email': email,
        'reset_code': resetCode,
      },
      defaultMessage:
          'Invalid reset code',
    );
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  static Future<Map<String, dynamic>>
      resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    return _post(
      '$baseUrl/api/auth/reset-password',
      body: {
        'email': email,
        'reset_token': resetToken,
        'new_password': newPassword,
      },
      defaultMessage:
          'Unable to reset password',
    );
  }

  // ============================================================
  // ADMIN - GET ALL USERS
  // ============================================================

  static Future<Map<String, dynamic>>
      getAdminUsers() async {
    final headers =
        await _authHeaders();

    return _get(
      '$baseUrl/api/auth/admin/users',
      headers: headers,
      defaultMessage:
          'Unable to load users',
    );
  }

  // ============================================================
  // SHOPS - CREATE
  // ============================================================

  static Future<Map<String, dynamic>>
      createShop({
    required String shopName,
    required String category,
    required String description,
    required String ownerName,
    required String ownerEmail,
    required String phone,
    required String address,
    required String locality,
    required String city,
    required String pincode,
    required double latitude,
    required double longitude,
    required String openingTime,
    required String closingTime,
    required String website,

    // NEW SHOP FIELDS
    String whatsapp = '',
    String district = '',
    String state = '',
    bool open24Hours = false,
    List<String> workingDays = const [],
    String instagram = '',
    String facebook = '',
    bool parking = false,
    bool homeDelivery = false,
    bool onlineOrder = false,
    bool upi = false,
    bool cash = false,
    bool offersAvailable = false,
    bool discountAvailable = false,
    double advertisementRadius = 1000,
  }) async {
    return _post(
      '$baseUrl/api/shops/create',
      body: {
        'shop_name': shopName,
        'category': category,
        'description': description,

        'owner_name': ownerName,
        'owner_email': ownerEmail,
        'phone': phone,
        'whatsapp': whatsapp,

        'address': address,
        'locality': locality,
        'city': city,
        'district': district,
        'state': state,
        'pincode': pincode,

        'latitude': latitude,
        'longitude': longitude,

        'opening_time': openingTime,
        'closing_time': closingTime,
        'open_24_hours': open24Hours,
        'working_days': workingDays,

        'website': website,
        'instagram': instagram,
        'facebook': facebook,

        'parking': parking,
        'home_delivery': homeDelivery,
        'online_order': onlineOrder,
        'upi': upi,
        'cash': cash,

        'offers_available': offersAvailable,
        'discount_available': discountAvailable,
        'advertisement_radius':
            advertisementRadius,
      },
      defaultMessage:
          'Unable to create shop',
    );
  }

  // ============================================================
  // SHOPS - MY SHOPS
  // ============================================================

  static Future<Map<String, dynamic>>
      getMyShops({
    required String ownerEmail,
  }) async {
    final encodedEmail =
        Uri.encodeQueryComponent(ownerEmail);

    return _get(
      '$baseUrl/api/shops/my-shops'
      '?owner_email=$encodedEmail',
      defaultMessage:
          'Unable to load your shops',
    );
  }

  // ============================================================
  // SHOPS - UPDATE
  // ============================================================

  static Future<Map<String, dynamic>>
      updateShop({
    required String shopId,
    required String shopName,
    required String category,
    required String description,
    required String ownerName,
    required String ownerEmail,
    required String phone,
    required String address,
    required String locality,
    required String city,
    required String pincode,
    required double latitude,
    required double longitude,
    required String openingTime,
    required String closingTime,
    required String website,

    // NEW SHOP FIELDS
    String whatsapp = '',
    String district = '',
    String state = '',
    bool open24Hours = false,
    List<String> workingDays = const [],
    String instagram = '',
    String facebook = '',
    bool parking = false,
    bool homeDelivery = false,
    bool onlineOrder = false,
    bool upi = false,
    bool cash = false,
    bool offersAvailable = false,
    bool discountAvailable = false,
    double advertisementRadius = 1000,
  }) async {
    return _put(
      '$baseUrl/api/shops/$shopId',
      body: {
        'shop_name': shopName,
        'category': category,
        'description': description,

        'owner_name': ownerName,
        'owner_email': ownerEmail,
        'phone': phone,
        'whatsapp': whatsapp,

        'address': address,
        'locality': locality,
        'city': city,
        'district': district,
        'state': state,
        'pincode': pincode,

        'latitude': latitude,
        'longitude': longitude,

        'opening_time': openingTime,
        'closing_time': closingTime,
        'open_24_hours': open24Hours,
        'working_days': workingDays,

        'website': website,
        'instagram': instagram,
        'facebook': facebook,

        'parking': parking,
        'home_delivery': homeDelivery,
        'online_order': onlineOrder,
        'upi': upi,
        'cash': cash,

        'offers_available': offersAvailable,
        'discount_available': discountAvailable,
        'advertisement_radius':
            advertisementRadius,
      },
      defaultMessage:
          'Unable to update shop',
    );
  }

  // ============================================================
  // SHOPS - APPROVED
  // ============================================================

  static Future<Map<String, dynamic>>
      getApprovedShops() async {
    return _get(
      '$baseUrl/api/shops/approved',
      defaultMessage:
          'Unable to load approved shops',
    );
  }

  // ============================================================
  // SHOPS - NEARBY
  // ============================================================

  static Future<Map<String, dynamic>>
      getNearbyShops({
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    return _get(
      '$baseUrl/api/shops/nearby'
      '?latitude=$latitude'
      '&longitude=$longitude'
      '&radius=$radius',
      defaultMessage:
          'Unable to load nearby shops',
    );
  }

  // ============================================================
  // SHOPS - PENDING
  // ============================================================

  static Future<Map<String, dynamic>>
      getPendingShops() async {
    return _get(
      '$baseUrl/api/shops/pending',
      defaultMessage:
          'Unable to load pending shops',
    );
  }

  // ============================================================
  // SHOPS - APPROVE
  // ============================================================

  static Future<Map<String, dynamic>>
      approveShop({
    required String shopId,
  }) async {
    return _put(
      '$baseUrl/api/shops/$shopId/approve',
      defaultMessage:
          'Unable to approve shop',
    );
  }

  // ============================================================
  // SHOPS - REJECT
  // ============================================================

  static Future<Map<String, dynamic>>
      rejectShop({
    required String shopId,
  }) async {
    return _put(
      '$baseUrl/api/shops/$shopId/reject',
      defaultMessage:
          'Unable to reject shop',
    );
  }

  // ============================================================
  // ADS - CREATE
  // ============================================================

  static Future<Map<String, dynamic>>
      createAdvertisement({
    required String ownerEmail,
    required String shopId,
    required String title,
    required String description,
    required double discount,
    required double radius,
    required String startDate,
    required String endDate,
  }) async {
    return _post(
      '$baseUrl/api/ads/create',
      body: {
        'owner_email': ownerEmail,
        'shop_id': shopId,
        'title': title,
        'description': description,
        'discount': discount,
        'radius': radius,
        'start_date': startDate,
        'end_date': endDate,
      },
      defaultMessage:
          'Unable to create advertisement',
    );
  }

  // ============================================================
  // ADS - MY ADS
  // ============================================================

  static Future<Map<String, dynamic>>
      getMyAds({
    required String ownerEmail,
  }) async {
    final encodedEmail =
        Uri.encodeQueryComponent(ownerEmail);

    return _get(
      '$baseUrl/api/ads/my-ads'
      '?owner_email=$encodedEmail',
      defaultMessage:
          'Unable to load advertisements',
    );
  }

  // ============================================================
  // ADS - UPDATE
  // ============================================================

  static Future<Map<String, dynamic>>
      updateAdvertisement({
    required String adId,
    required String title,
    required String description,
    required double discount,
    required double radius,
    required String startDate,
    required String endDate,
  }) async {
    return _put(
      '$baseUrl/api/ads/$adId',
      body: {
        'title': title,
        'description': description,
        'discount': discount,
        'radius': radius,
        'start_date': startDate,
        'end_date': endDate,
      },
      defaultMessage:
          'Unable to update advertisement',
    );
  }

  // ============================================================
  // ADS - APPROVED
  // ============================================================

  static Future<Map<String, dynamic>>
      getApprovedAds({
    bool forceRefresh = false,
  }) async {
    return _get(
      '$baseUrl/api/ads/approved',
      defaultMessage:
          'Unable to load approved advertisements',
    );
  }

  // ============================================================
  // ADS - PENDING
  // ============================================================

  static Future<Map<String, dynamic>>
      getPendingAds() async {
    return _get(
      '$baseUrl/api/ads/pending',
      defaultMessage:
          'Unable to load pending advertisements',
    );
  }

  // ============================================================
  // ADS - APPROVE
  // ============================================================

  static Future<Map<String, dynamic>>
      approveAdvertisement({
    required String adId,
  }) async {
    return _put(
      '$baseUrl/api/ads/$adId/approve',
      defaultMessage:
          'Unable to approve advertisement',
    );
  }

  // ============================================================
  // ADS - REJECT
  // ============================================================

  static Future<Map<String, dynamic>>
      rejectAdvertisement({
    required String adId,
  }) async {
    return _put(
      '$baseUrl/api/ads/$adId/reject',
      defaultMessage:
          'Unable to reject advertisement',
    );
  }
}
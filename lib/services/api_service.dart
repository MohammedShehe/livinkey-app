// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/constants.dart';
import '../models/auth_models.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  String? _token;
  String? _role;

  Dio get dio => _dio;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(kStorageToken);
    _role = prefs.getString(kStorageRole);
    
    print('ApiService.init - token present: ${_token != null}');
    print('ApiService.init - role: $_role');

    _dio = Dio(BaseOptions(
      baseUrl: kApiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // ============================================================
        // FIXED: ALWAYS get token from SharedPreferences on each request
        // This ensures the interceptor always has the latest token
        // ============================================================
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(kStorageToken);
        
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          print('ApiService.onRequest - Added Authorization header (token from SharedPreferences)');
        } else {
          print('ApiService.onRequest - NO TOKEN available');
        }
        
        options.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate';
        options.headers['Pragma'] = 'no-cache';
        options.headers['Expires'] = '0';
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (error, handler) async {
        print('ApiService.onError - Status: ${error.response?.statusCode}, Message: ${error.message}');
        if (error.response?.statusCode == 401 || error.response?.statusCode == 403) {
          await _handleUnauthorized();
        }
        return handler.next(error);
      },
    ));
  }

  Future<void> _handleUnauthorized() async {
    print('ApiService._handleUnauthorized - Clearing token due to 401/403');
    await clearToken();
  }

  Future<void> setToken(String token, {String? role}) async {
    print('ApiService.setToken - Setting token (length: ${token.length}), role: $role');
    _token = token;
    _role = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kStorageToken, token);
    if (role != null) {
      await prefs.setString(kStorageRole, role);
    }
    print('ApiService.setToken - Token saved to SharedPreferences');
    
    // Verify token was saved
    final savedToken = prefs.getString(kStorageToken);
    print('ApiService.setToken - Verification: token saved = ${savedToken != null}');
  }

  Future<void> clearToken() async {
    print('ApiService.clearToken - Clearing token and user data');
    _token = null;
    _role = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kStorageToken);
    await prefs.remove(kStorageRole);
    await prefs.remove(kStorageUser);
  }

  Future<String?> getToken() async {
    // Always get from SharedPreferences to ensure freshness
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(kStorageToken);
    print('ApiService.getToken - Retrieved token from SharedPreferences: ${_token != null}');
    return _token;
  }

  String? get token => _token;
  String? get role => _role;

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    await prefs.setString(kStorageUser, userJson);
    print('ApiService.saveUser - User saved with role: ${user.role}');
  }

  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(kStorageUser);
    if (userJson != null) {
      try {
        return UserModel.fromJson(jsonDecode(userJson));
      } catch (e) {
        print('ApiService.getUser - Error parsing user: $e');
        return null;
      }
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(kStorageToken);
    final user = prefs.getString(kStorageUser);
    final loggedIn = token != null && token.isNotEmpty && user != null;
    print('ApiService.isLoggedIn - $loggedIn');
    return loggedIn;
  }

  Future<String?> getStoredRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kStorageRole);
  }

  Future<bool> switchToRole(String newRole) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(kStorageUser);
    if (userJson == null) return false;
    
    try {
      final user = jsonDecode(userJson);
      user['role'] = newRole;
      await prefs.setString(kStorageUser, jsonEncode(user));
      await prefs.setString(kStorageRole, newRole);
      _role = newRole;
      print('ApiService.switchToRole - Switched to role: $newRole');
      return true;
    } catch (e) {
      print('ApiService.switchToRole - Error: $e');
      return false;
    }
  }

  // ============================================================
  // SAFE TYPE PARSING HELPERS
  // ============================================================
  
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return 0;
      return int.tryParse(trimmed) ?? 0;
    }
    if (value is bool) return value ? 1 : 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return 0.0;
      return double.tryParse(trimmed) ?? 0.0;
    }
    if (value is bool) return value ? 1.0 : 0.0;
    return 0.0;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return false;
  }

  // ============================================================
  // TENANT HOME
  // ============================================================
  Future<Map<String, dynamic>> getTenantHome() async {
    try {
      // No need to call getToken() - interceptor will get it from SharedPreferences
      final response = await _dio.get('/tenants/home');
      return response.data;
    } on DioException catch (e) {
      print('getTenantHome error: ${e.message}');
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  // Tenant Login
  Future<LoginResponse> tenantLogin(String email, String password) async {
    try {
      final response = await _dio.post('/tenants/auth/login', data: {
        'email': email,
        'password': password,
      });
      print('Tenant login response status: ${response.statusCode}');
      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      print('Tenant login DioException: ${e.message}');
      if (e.response != null && e.response!.data != null) {
        return LoginResponse.fromJson(e.response!.data);
      }
      return LoginResponse(
        success: false,
        message: 'Network error. Please try again.',
      );
    } catch (e) {
      print('Tenant login error: $e');
      return LoginResponse(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  // Guest Login
  Future<LoginResponse> guestLogin(String email, String password) async {
    try {
      final response = await _dio.post('/guests/login', data: {
        'email': email,
        'password': password,
      });
      print('Guest login response status: ${response.statusCode}');
      print('Guest login response data: ${response.data}');
      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      print('Guest login DioException: ${e.message}');
      if (e.response != null && e.response!.data != null) {
        return LoginResponse.fromJson(e.response!.data);
      }
      return LoginResponse(
        success: false,
        message: 'Network error. Please try again.',
      );
    } catch (e) {
      print('Guest login error: $e');
      return LoginResponse(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  // Guest Register
  Future<Map<String, dynamic>> guestRegister(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/guests/register', data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  // Guest Forgot Password
  Future<Map<String, dynamic>> guestForgotPassword(String email) async {
    try {
      final response = await _dio.post('/guests/forgot-password', data: {
        'email': email,
      });
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  // Guest Verify OTP
  Future<OtpResponse> guestVerifyOTP(String email, String otp) async {
    try {
      final response = await _dio.post('/guests/verify-otp', data: {
        'email': email,
        'otp': otp,
      });
      return OtpResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return OtpResponse.fromJson(e.response!.data);
      }
      return OtpResponse(
        success: false,
        message: 'Network error. Please try again.',
      );
    } catch (e) {
      return OtpResponse(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  // Guest Reset Password
  Future<Map<String, dynamic>> guestResetPassword(String resetToken, String newPassword, String confirmPassword) async {
    try {
      final response = await _dio.post('/guests/reset-password', data: {
        'resetToken': resetToken,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      });
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  // Tenant Forgot Password
  Future<Map<String, dynamic>> tenantForgotPassword(String email) async {
    try {
      final response = await _dio.post('/tenants/auth/forgot-password', data: {
        'email': email,
      });
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  // Tenant Verify OTP
  Future<OtpResponse> tenantVerifyOTP(String email, String otp) async {
    try {
      final response = await _dio.post('/tenants/auth/verify-otp', data: {
        'email': email,
        'otp': otp,
      });
      return OtpResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return OtpResponse.fromJson(e.response!.data);
      }
      return OtpResponse(
        success: false,
        message: 'Network error. Please try again.',
      );
    } catch (e) {
      return OtpResponse(
        success: false,
        message: 'An error occurred. Please try again.',
      );
    }
  }

  // Tenant Reset Password
  Future<Map<String, dynamic>> tenantResetPassword(String resetToken, String newPassword, String confirmPassword) async {
    try {
      final response = await _dio.post('/tenants/auth/reset-password', data: {
        'resetToken': resetToken,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      });
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  // Tenant Change Password
  Future<Map<String, dynamic>> tenantChangePassword(String currentPassword, String newPassword, String confirmPassword) async {
    try {
      final response = await _dio.post('/tenants/auth/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      });
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  // ============ TENANT ENDPOINTS ============

  Future<Map<String, dynamic>> getTenantProfile() async {
    try {
      final response = await _dio.get('/tenants/profile');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  // ============ GUEST ENDPOINTS ============

  // ============ GUEST ENDPOINTS ============

  Future<Map<String, dynamic>> getGuestDashboard() async {
    try {
      final response = await _dio.get(
        '/guests/dashboard',
        options: Options(
          headers: {
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          },
        ),
      );
      print('Guest dashboard response status: ${response.statusCode}');
      return response.data ?? {'success': false, 'message': 'Empty response'};
    } on DioException catch (e) {
      print('getGuestDashboard DioException: ${e.message}, status: ${e.response?.statusCode}');
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      if (e.response?.statusCode == 401) {
        return {'success': false, 'message': 'Session expired. Please login again.'};
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      print('getGuestDashboard error: $e');
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> getGuestProfile() async {
    try {
      final response = await _dio.get('/guests/profile');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> updateGuestProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/guests/profile', data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> guestChangePassword(String currentPassword, String newPassword, String confirmPassword) async {
    try {
      final response = await _dio.post('/guests/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      });
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  // ============ PUBLIC ENDPOINTS ============

  Future<Map<String, dynamic>> getPublicPGs({String? search, String? status, double? minRent, double? maxRent}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (minRent != null) queryParams['min_rent'] = minRent;
      if (maxRent != null) queryParams['max_rent'] = maxRent;

      final response = await _dio.get(
        '/public/pgs',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          },
        ),
      );
      print('Public PGs response status: ${response.statusCode}');
      return response.data ?? {'success': false, 'message': 'Empty response', 'data': []};
    } on DioException catch (e) {
      print('getPublicPGs DioException: ${e.message}, status: ${e.response?.statusCode}');
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      if (e.response?.statusCode == 304) {
        return {'success': true, 'data': [], 'message': 'Cached - no new data'};
      }
      return {'success': false, 'message': 'Network error. Please try again.', 'data': []};
    } catch (e) {
      print('getPublicPGs error: $e');
      return {'success': false, 'message': 'An error occurred. Please try again.', 'data': []};
    }
  }

  Future<Map<String, dynamic>> getPublicPGDetails(int pgId) async {
    try {
      final response = await _dio.get('/public/pgs/$pgId');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> getPublicPGStats() async {
    try {
      final response = await _dio.get('/public/pgs/stats');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  // ============ TENANT PAYMENTS ============

  Future<Map<String, dynamic>> getCurrentBill() async {
    try {
      final response = await _dio.get('/tenant-payments/bill');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> getPaymentHistory() async {
    try {
      final response = await _dio.get('/tenant-payments/history');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> submitPaymentProof({
    required int billId,
    required String transactionId,
    required double amountPaid,
    required String paymentScreenshot,
  }) async {
    try {
      if (billId <= 0) {
        return {'success': false, 'message': 'Invalid bill ID'};
      }
      if (transactionId.isEmpty) {
        return {'success': false, 'message': 'Transaction ID is required'};
      }
      if (amountPaid <= 0) {
        return {'success': false, 'message': 'Amount must be greater than 0'};
      }
      if (paymentScreenshot.isEmpty) {
        return {'success': false, 'message': 'Payment screenshot is required'};
      }

      final formData = FormData();
      formData.fields.add(MapEntry('bill_id', billId.toString()));
      formData.fields.add(MapEntry('transaction_id', transactionId));
      formData.fields.add(MapEntry('amount_paid', amountPaid.toString()));

      try {
        MultipartFile file;
        
        if (kIsWeb) {
          if (paymentScreenshot.startsWith('data:image')) {
            final parts = paymentScreenshot.split(',');
            if (parts.length == 2) {
              final bytes = base64Decode(parts[1]);
              if (bytes.isNotEmpty) {
                file = MultipartFile.fromBytes(
                  bytes,
                  filename: 'proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
                  contentType: DioMediaType('image', 'jpeg'),
                );
              } else {
                return {'success': false, 'message': 'Empty image data'};
              }
            } else {
              return {'success': false, 'message': 'Invalid image data format'};
            }
          } else {
            try {
              final response = await Dio().get(
                paymentScreenshot,
                options: Options(responseType: ResponseType.bytes),
              );
              if (response.data != null && response.data is Uint8List) {
                file = MultipartFile.fromBytes(
                  response.data as Uint8List,
                  filename: 'proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
                  contentType: DioMediaType('image', 'jpeg'),
                );
              } else {
                return {'success': false, 'message': 'Failed to load image'};
              }
            } catch (e) {
              return {'success': false, 'message': 'Failed to load image: ${e.toString()}'};
            }
          }
        } else {
          final fileObj = File(paymentScreenshot);
          if (await fileObj.exists()) {
            final bytes = await fileObj.readAsBytes();
            if (bytes.isEmpty) {
              return {'success': false, 'message': 'File is empty'};
            }
            
            String extension = 'jpg';
            final fileName = fileObj.path.split('/').last;
            if (fileName.contains('.')) {
              extension = fileName.split('.').last;
            }
            
            file = MultipartFile.fromBytes(
              bytes,
              filename: 'proof_${DateTime.now().millisecondsSinceEpoch}.$extension',
            );
          } else {
            return {'success': false, 'message': 'File does not exist: $paymentScreenshot'};
          }
        }

        formData.files.add(MapEntry('payment_screenshot', file));
      } catch (fileError) {
        print('Error creating file part: $fileError');
        return {'success': false, 'message': 'Failed to process file: ${fileError.toString()}'};
      }

      final response = await _dio.post(
        '/tenant-payments/proof',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      
      return response.data;
    } on DioException catch (e) {
      print('DioException in submitPaymentProof: ${e.message}');
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return {'success': false, 'message': 'Connection timeout. Please try again.'};
      }
      if (e.type == DioExceptionType.connectionError) {
        return {'success': false, 'message': 'Network error. Please check your connection.'};
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      print('Unexpected error in submitPaymentProof: $e');
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  // ============ MAINTENANCE ============

  Future<Map<String, dynamic>> getMyMaintenanceRequests({String? status}) async {
    try {
      final query = status != null ? '?status=$status' : '';
      final response = await _dio.get('/maintenance/my-requests$query');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> getMaintenanceStats() async {
    try {
      final response = await _dio.get('/maintenance/my-stats');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> createMaintenanceRequest({
    required String issueType,
    String? description,
    required String serviceDate,
    String? freeTime,
    String? imagePath,
  }) async {
    try {
      final formData = FormData();
      
      formData.fields.add(MapEntry('issue_type', issueType));
      if (description != null && description.isNotEmpty) {
        formData.fields.add(MapEntry('description', description));
      }
      formData.fields.add(MapEntry('service_date', serviceDate));
      if (freeTime != null && freeTime.isNotEmpty) {
        formData.fields.add(MapEntry('free_time', freeTime));
      }

      if (imagePath != null && imagePath.isNotEmpty) {
        try {
          MultipartFile file;
          
          if (kIsWeb) {
            if (imagePath.startsWith('data:image')) {
              final parts = imagePath.split(',');
              if (parts.length == 2) {
                final bytes = base64Decode(parts[1]);
                if (bytes.isNotEmpty) {
                  file = MultipartFile.fromBytes(
                    bytes,
                    filename: 'maintenance_${DateTime.now().millisecondsSinceEpoch}.jpg',
                    contentType: DioMediaType('image', 'jpeg'),
                  );
                } else {
                  return {'success': false, 'message': 'Empty image data'};
                }
              } else {
                return {'success': false, 'message': 'Invalid image data format'};
              }
            } else {
              try {
                final response = await Dio().get(
                  imagePath,
                  options: Options(responseType: ResponseType.bytes),
                );
                if (response.data != null && response.data is Uint8List) {
                  file = MultipartFile.fromBytes(
                    response.data as Uint8List,
                    filename: 'maintenance_${DateTime.now().millisecondsSinceEpoch}.jpg',
                    contentType: DioMediaType('image', 'jpeg'),
                  );
                } else {
                  return {'success': false, 'message': 'Failed to load image'};
                }
              } catch (e) {
                return {'success': false, 'message': 'Failed to load image: ${e.toString()}'};
              }
            }
          } else {
            final fileObj = File(imagePath);
            if (await fileObj.exists()) {
              final bytes = await fileObj.readAsBytes();
              if (bytes.isEmpty) {
                return {'success': false, 'message': 'File is empty'};
              }
              file = MultipartFile.fromBytes(
                bytes,
                filename: 'maintenance_${DateTime.now().millisecondsSinceEpoch}.jpg',
              );
            } else {
              return {'success': false, 'message': 'File does not exist: $imagePath'};
            }
          }

          formData.files.add(MapEntry('image', file));
        } catch (fileError) {
          print('Error creating file part: $fileError');
          return {'success': false, 'message': 'Failed to process file: ${fileError.toString()}'};
        }
      }

      final response = await _dio.post(
        '/maintenance/request',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  // ============ DOCUMENTS ============

  Future<Map<String, dynamic>> getDocumentTypes() async {
    try {
      final response = await _dio.get('/documents/types');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> getMyDocuments() async {
    try {
      final response = await _dio.get('/documents/my-documents');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> uploadDocument({
    required String documentType,
    required String filePath,
  }) async {
    try {
      if (documentType.isEmpty) {
        return {'success': false, 'message': 'Document type is required'};
      }
      if (filePath.isEmpty) {
        return {'success': false, 'message': 'File path is required'};
      }

      final formData = FormData();
      formData.fields.add(MapEntry('document_type', documentType));

      try {
        MultipartFile file;
        
        if (kIsWeb) {
          if (filePath.startsWith('data:image')) {
            final parts = filePath.split(',');
            if (parts.length == 2) {
              final bytes = base64Decode(parts[1]);
              if (bytes.isNotEmpty) {
                file = MultipartFile.fromBytes(
                  bytes,
                  filename: 'doc_${DateTime.now().millisecondsSinceEpoch}.jpg',
                  contentType: DioMediaType('image', 'jpeg'),
                );
              } else {
                return {'success': false, 'message': 'Empty image data'};
              }
            } else {
              return {'success': false, 'message': 'Invalid image data format'};
            }
          } else if (filePath.startsWith('http')) {
            try {
              final response = await Dio().get(
                filePath,
                options: Options(responseType: ResponseType.bytes),
              );
              if (response.data != null && response.data is Uint8List) {
                file = MultipartFile.fromBytes(
                  response.data as Uint8List,
                  filename: 'doc_${DateTime.now().millisecondsSinceEpoch}.jpg',
                  contentType: DioMediaType('image', 'jpeg'),
                );
              } else {
                return {'success': false, 'message': 'Failed to download file'};
              }
            } catch (e) {
              return {'success': false, 'message': 'Failed to download file: ${e.toString()}'};
            }
          } else {
            return {'success': false, 'message': 'Invalid file path format'};
          }
        } else {
          final fileObj = File(filePath);
          if (await fileObj.exists()) {
            final bytes = await fileObj.readAsBytes();
            if (bytes.isEmpty) {
              return {'success': false, 'message': 'File is empty'};
            }
            
            String extension = 'jpg';
            final fileName = fileObj.path.split('/').last;
            if (fileName.contains('.')) {
              extension = fileName.split('.').last;
            }
            
            file = MultipartFile.fromBytes(
              bytes,
              filename: 'doc_${DateTime.now().millisecondsSinceEpoch}.$extension',
            );
          } else {
            return {'success': false, 'message': 'File does not exist: $filePath'};
          }
        }

        formData.files.add(MapEntry('document', file));
      } catch (fileError) {
        print('Error creating file part: $fileError');
        return {'success': false, 'message': 'Failed to process file: ${fileError.toString()}'};
      }

      final response = await _dio.post(
        '/documents/upload',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      
      return response.data;
    } on DioException catch (e) {
      print('DioException in uploadDocument: ${e.message}');
      if (e.response != null && e.response!.data != null) {
        if (e.response!.data is Map && (e.response!.data as Map).containsKey('message')) {
          return e.response!.data;
        }
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return {'success': false, 'message': 'Connection timeout. Please try again.'};
      }
      if (e.type == DioExceptionType.connectionError) {
        return {'success': false, 'message': 'Network error. Please check your connection.'};
      }
      if (e.type == DioExceptionType.badResponse) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 400) {
          return {'success': false, 'message': 'Invalid document type or file format.'};
        }
        if (statusCode == 401 || statusCode == 403) {
          return {'success': false, 'message': 'Authentication failed. Please login again.'};
        }
        if (statusCode == 413) {
          return {'success': false, 'message': 'File too large. Please use a smaller image.'};
        }
      }
      return {'success': false, 'message': 'Network error: ${e.message}'};
    } catch (e) {
      print('Unexpected error in uploadDocument: $e');
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  // ============ NOTIFICATIONS ============

  Future<Map<String, dynamic>> getTenantNotifications({int limit = 50, int offset = 0}) async {
    try {
      final response = await _dio.get('/tenant-notifications?limit=$limit&offset=$offset');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> getUnreadTenantNotifications({int limit = 20}) async {
    try {
      final response = await _dio.get('/tenant-notifications/unread?limit=$limit');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> getUnreadTenantCount() async {
    try {
      final response = await _dio.get('/tenant-notifications/unread/count');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> markTenantNotificationRead(int notificationId) async {
    try {
      final response = await _dio.put('/tenant-notifications/$notificationId/read');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> markAllTenantNotificationsRead() async {
    try {
      final response = await _dio.put('/tenant-notifications/read-all');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> getGuestNotifications({int limit = 50, int offset = 0}) async {
    try {
      final response = await _dio.get('/guest-notifications?limit=$limit&offset=$offset');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> getUnreadGuestNotifications({int limit = 20}) async {
    try {
      final response = await _dio.get('/guest-notifications/unread?limit=$limit');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> getUnreadGuestCount() async {
    try {
      final response = await _dio.get('/guest-notifications/unread/count');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> markGuestNotificationRead(int notificationId) async {
    try {
      final response = await _dio.put('/guest-notifications/$notificationId/read');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> markAllGuestNotificationsRead() async {
    try {
      final response = await _dio.put('/guest-notifications/read-all');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  // ============ FEEDBACK ============

  Future<Map<String, dynamic>> submitFeedback(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/feedbacks/submit', data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> getMyFeedback() async {
    try {
      final response = await _dio.get('/feedbacks/my-feedback');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> checkFeedbackStatus() async {
    try {
      final response = await _dio.get('/feedbacks/status');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  // ============================================================
  // FCM TOKEN ENDPOINTS (Add to ApiService class)
  // ============================================================

  /// Update FCM token on backend
  Future<Map<String, dynamic>> updateFCMToken(String token) async {
    try {
      final response = await _dio.post('/tenants/device/fcm-token', data: {
        'fcm_token': token,
        'device_type': Platform.isIOS ? 'ios' : 'android',
      });
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  /// Remove FCM token on logout
  Future<Map<String, dynamic>> removeFCMToken({String? token}) async {
    try {
      final data = token != null ? {'fcm_token': token} : {};
      final response = await _dio.delete('/tenants/device/fcm-token', data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data;
      }
      return {'success': false, 'message': 'Network error. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }
}
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  // Cổng HTTP thực tế từ file launchSettings.json của bạn là 5180
  static const String baseUrl = "http://10.0.2.2:5180/api";
  static const String meterOcrUrl = "http://10.0.2.2:5000/api/ocr-dong-ho";

  // --- AUTH ---
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/Auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      print('API Login trả trạng thái HTTP ${response.statusCode}.');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) {
          return {
            'success': false,
            'message': 'Phản hồi đăng nhập từ máy chủ không đúng định dạng.',
          };
        }

        final data = Map<String, dynamic>.from(decoded);
        final nested = data['data'] ?? data['user'] ?? data['taiKhoan'];
        final userData = nested is Map
            ? Map<String, dynamic>.from(nested)
            : <String, dynamic>{};
        final roleValue =
            _firstValue(data, const ['vaiTro', 'VaiTro', 'role', 'Role']) ??
            _firstValue(userData, const ['vaiTro', 'VaiTro', 'role', 'Role']);
        final role = _normalizeLoginRole(roleValue?.toString());
        if (role == null) {
          return {
            'success': false,
            'message':
                'Máy chủ chưa trả về vai trò tài khoản hợp lệ (Admin/Customer).',
          };
        }

        final rawCustomerId =
            _firstValue(data, const [
              'maKhach',
              'MaKhach',
              'customerId',
              'CustomerId',
              'maKhachThue',
              'MaKhachThue',
            ]) ??
            _firstValue(userData, const [
              'maKhach',
              'MaKhach',
              'customerId',
              'CustomerId',
              'maKhachThue',
              'MaKhachThue',
            ]);
        final customer =
            data['khachThue'] ??
            data['KhachThue'] ??
            data['maKhachNavigation'] ??
            data['MaKhachNavigation'] ??
            userData['khachThue'] ??
            userData['KhachThue'] ??
            userData['maKhachNavigation'] ??
            userData['MaKhachNavigation'];
        final customerMap = customer is Map ? customer : const {};
        final customerId = int.tryParse(
          (rawCustomerId ??
                      _firstValue(customerMap, const [
                        'maKhach',
                        'MaKhach',
                        'customerId',
                        'CustomerId',
                        'id',
                        'Id',
                      ]))
                  ?.toString() ??
              '',
        );
        if (role == 'Customer' && (customerId == null || customerId <= 0)) {
          return {
            'success': false,
            'message':
                'Tài khoản khách đã được xác thực nhưng API đăng nhập chưa trả '
                'mã khách (maKhach). Hãy cập nhật AuthController để trả mã khách '
                'thuê tương ứng.',
          };
        }

        return {
          'success': true,
          'message': 'Đăng nhập thành công',
          'vaiTro': role,
          'maKhach': customerId,
        };
      } else {
        return {
          'success': false,
          'message': 'Lỗi đăng nhập (${response.statusCode}): ${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối Server: $e'};
    }
  }

  // Backend xác thực Firebase ID token và chỉ cho đăng nhập hồ sơ khách đã tồn tại.
  static Future<Map<String, dynamic>> loginCustomerWithGoogle(
    String firebaseIdToken,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/Auth/google-login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'idToken': firebaseIdToken}),
          )
          .timeout(const Duration(seconds: 15));

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        decoded = null;
      }

      if (response.statusCode != 200 || decoded is! Map) {
        final message = decoded is Map ? decoded['message']?.toString() : null;
        return {
          'success': false,
          'message':
              message ??
              (response.statusCode == 404
                  ? 'Backend chưa có API /Auth/google-login. Cần bổ sung xác thực Google ở AuthController.'
                  : 'Đăng nhập Google thất bại (${response.statusCode}).'),
        };
      }

      final root = Map<String, dynamic>.from(decoded);
      final nested = root['data'] ?? root['user'];
      final data = nested is Map ? Map<String, dynamic>.from(nested) : root;
      final role = _normalizeLoginRole(
        (_firstValue(data, const ['vaiTro', 'VaiTro', 'role', 'Role']) ??
                _firstValue(root, const ['vaiTro', 'VaiTro', 'role', 'Role']))
            ?.toString(),
      );
      final customerId = int.tryParse(
        (_firstValue(data, const [
                      'maKhach',
                      'MaKhach',
                      'customerId',
                      'CustomerId',
                      'maKhachThue',
                      'MaKhachThue',
                    ]) ??
                    _firstValue(root, const [
                      'maKhach',
                      'MaKhach',
                      'customerId',
                      'CustomerId',
                      'maKhachThue',
                      'MaKhachThue',
                    ]))
                ?.toString() ??
            '',
      );

      if (role != 'Customer' || customerId == null || customerId <= 0) {
        return {
          'success': false,
          'message':
              'Tài khoản Google chưa được liên kết với hồ sơ khách thuê hợp lệ. '
              'Hãy dùng email đã đăng ký với chủ trọ.',
        };
      }

      return {
        'success': true,
        'message': 'Đăng nhập Google thành công.',
        'vaiTro': role,
        'maKhach': customerId,
      };
    } catch (error) {
      return {
        'success': false,
        'message': 'Không kết nối được API đăng nhập Google: $error',
      };
    }
  }

  static dynamic _firstValue(Map data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null) return value;
    }
    return null;
  }

  static String? _normalizeLoginRole(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;

    if (normalized == 'admin' ||
        normalized == 'chủ trọ' ||
        normalized == 'chu tro' ||
        normalized == 'landlord') {
      return 'Admin';
    }
    if (normalized == 'customer' ||
        normalized == 'khách' ||
        normalized == 'khách hàng' ||
        normalized == 'khách thuê' ||
        normalized == 'khach hang' ||
        normalized == 'khach thue' ||
        normalized == 'tenant') {
      return 'Customer';
    }
    return null;
  }

  static Future<bool> register(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/Auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Lỗi register: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> registerCustomerForLandlord({
    required String email,
    required String fullName,
    required String phone,
    String? cccd,
    String? address,
    http.Client? client,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return {
        'success': false,
        'message': 'Email là bắt buộc để tạo tài khoản.',
      };
    }
    if (normalizedEmail.length < 6) {
      return {
        'success': false,
        'message':
            'Email quá ngắn để dùng làm mật khẩu khởi tạo (tối thiểu 6 ký tự).',
      };
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalizedEmail)) {
      return {'success': false, 'message': 'Địa chỉ email chưa hợp lệ.'};
    }
    if (fullName.trim().isEmpty || phone.trim().isEmpty) {
      return {
        'success': false,
        'message': 'Vui lòng nhập họ tên và số điện thoại.',
      };
    }

    try {
      final response = await (client?.post ?? http.post)(
        Uri.parse('$baseUrl/Auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tenDangNhap': normalizedEmail,
          'matKhau': normalizedEmail,
          'hoTen': fullName.trim(),
          'email': normalizedEmail,
          'soDienThoai': phone.trim(),
          'vaiTro': 'Customer',
          'cccd': cccd?.trim() ?? '',
          'diaChi': address?.trim() ?? '',
        }),
      ).timeout(const Duration(seconds: 15));

      dynamic decoded;
      try {
        decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      } on FormatException {
        decoded = null;
      }
      final body = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          body['success'] != false) {
        return {
          ...body,
          'success': true,
          'message':
              body['message']?.toString() ?? 'Đã tạo khách và tài khoản.',
          'username': normalizedEmail,
          'initialPassword': normalizedEmail,
        };
      }
      return {
        'success': false,
        'message': body['message']?.toString().trim().isNotEmpty == true
            ? body['message'].toString()
            : 'Không thể tạo tài khoản khách (${response.statusCode}): ${response.body}',
      };
    } catch (error) {
      return {
        'success': false,
        'message': 'Không thể kết nối để tạo tài khoản khách: $error',
      };
    }
  }

  static Future<void> logout() async {
    try {
      await http
          .post(Uri.parse('$baseUrl/Auth/logout'))
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      // Logout cục bộ vẫn hoàn tất; ghi log để có thể kiểm tra API khi cần.
      print('Lỗi gọi API logout: $e');
    }
  }

  // --- ROOMS (Phòng) ---
  static Future<List<dynamic>> getRooms() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Phong'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Lỗi getRooms: $e');
    }
    return [];
  }

  static Future<List<dynamic>> getRoomsForContractCreation({
    http.Client? client,
  }) async {
    final uri = Uri.parse('$baseUrl/Phong');
    final request = client == null
        ? http.get(uri, headers: {'Content-Type': 'application/json'})
        : client.get(uri, headers: {'Content-Type': 'application/json'});
    final response = await request.timeout(const Duration(seconds: 10));
    return _decodeListResponse(response, 'Không thể tải danh sách phòng');
  }

  static Future<bool> createRoom(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Phong'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Lỗi createRoom: $e');
      return false;
    }
  }

  // --- ROOM TYPES (Loại Phòng) ---
  static Future<List<dynamic>> getRoomTypes() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/LoaiPhong'));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      print('Lỗi getRoomTypes: $e');
    }
    return [];
  }

  static Future<bool> createRoomType(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/LoaiPhong'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('Lỗi createRoomType: $e');
      return false;
    }
  }

  static Future<bool> deleteRoomType(int typeId) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/LoaiPhong/$typeId'));
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      print('Lỗi deleteRoomType: $e');
      return false;
    }
  }

  // --- CUSTOMERS (Khách Thuê) ---
  static Future<List<dynamic>> getCustomers() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/KhachThue'));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      print('Lỗi getCustomers: $e');
    }
    return [];
  }

  static Future<bool> createCustomer(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/KhachThue'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('Lỗi createCustomer: $e');
      return false;
    }
  }

  // --- CONTRACTS (Hợp Đồng) ---
  static Future<List<dynamic>> getContracts() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/HopDong'));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      print('Lỗi getContracts: $e');
    }
    return [];
  }

  static Future<List<dynamic>> getContractsForRentBilling({
    http.Client? client,
  }) async {
    final uri = Uri.parse('$baseUrl/HopDong');
    final request = client == null
        ? http.get(uri, headers: {'Content-Type': 'application/json'})
        : client.get(uri, headers: {'Content-Type': 'application/json'});
    final response = await request.timeout(const Duration(seconds: 10));
    return _decodeListResponse(response, 'Không thể tải danh sách hợp đồng');
  }

  static Future<List<dynamic>> getCustomersForRentBilling({
    http.Client? client,
  }) async {
    final uri = Uri.parse('$baseUrl/KhachThue');
    final request = client == null
        ? http.get(uri, headers: {'Content-Type': 'application/json'})
        : client.get(uri, headers: {'Content-Type': 'application/json'});
    final response = await request.timeout(const Duration(seconds: 10));
    return _decodeListResponse(response, 'Không thể tải danh sách khách thuê');
  }

  static Future<Map<String, dynamic>> getCustomerProfile(
    int customerId, {
    http.Client? client,
  }) async {
    if (customerId <= 0) {
      throw ArgumentError.value(
        customerId,
        'customerId',
        'Mã khách không hợp lệ.',
      );
    }
    final uri = Uri.parse('$baseUrl/KhachThue/$customerId');
    final request = client == null
        ? http.get(uri, headers: {'Content-Type': 'application/json'})
        : client.get(uri, headers: {'Content-Type': 'application/json'});
    final response = await request.timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception(
        'Không thể tải hồ sơ khách thuê (${response.statusCode}): ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException(
        'API hồ sơ khách thuê trả dữ liệu không hợp lệ.',
      );
    }
    return Map<String, dynamic>.from(decoded);
  }

  static Future<Map<String, dynamic>> updateCustomerProfile({
    required int customerId,
    required Map<String, dynamic> profile,
    http.Client? client,
  }) async {
    if (customerId <= 0) {
      throw ArgumentError.value(
        customerId,
        'customerId',
        'Mã khách không hợp lệ.',
      );
    }
    final response = await (client?.put ?? http.put)(
      Uri.parse('$baseUrl/KhachThue/$customerId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(profile),
    ).timeout(const Duration(seconds: 15));
    return _decodeMutationResponse(
      response,
      operation: 'Cập nhật hồ sơ khách thuê',
      defaultSuccessMessage: 'Cập nhật thông tin thành công.',
    );
  }

  static Future<Map<String, dynamic>> changeCustomerPassword({
    required int customerId,
    required String currentPassword,
    required String newPassword,
    http.Client? client,
  }) async {
    if (customerId <= 0) {
      throw ArgumentError.value(
        customerId,
        'customerId',
        'Mã khách không hợp lệ.',
      );
    }
    final response = await (client?.post ?? http.post)(
      Uri.parse('$baseUrl/Auth/change-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'maKhach': customerId,
        'matKhauHienTai': currentPassword,
        'matKhauMoi': newPassword,
      }),
    ).timeout(const Duration(seconds: 15));
    return _decodeMutationResponse(
      response,
      operation: 'Đổi mật khẩu',
      defaultSuccessMessage: 'Đổi mật khẩu thành công.',
      notFoundMessage:
          'Backend chưa có API /Auth/change-password. Hãy bổ sung endpoint '
          'đổi mật khẩu vào AuthController rồi thử lại.',
    );
  }

  static Map<String, dynamic> _decodeMutationResponse(
    http.Response response, {
    required String operation,
    required String defaultSuccessMessage,
    String? notFoundMessage,
  }) {
    dynamic decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      decoded = null;
    }
    final body = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};
    final serverSuccess = body['success'] != false;
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        serverSuccess) {
      return {
        ...body,
        'success': true,
        'message': body['message']?.toString() ?? defaultSuccessMessage,
      };
    }
    final message = response.statusCode == 404 && notFoundMessage != null
        ? notFoundMessage
        : body['message']?.toString().trim().isNotEmpty == true
        ? body['message'].toString()
        : '$operation thất bại (${response.statusCode}): ${response.body}';
    return {'success': false, 'message': message};
  }

  static Future<List<dynamic>> getContractsByCustomer(int maKhach) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/HopDong/customer/$maKhach'),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print('Lỗi getContractsByCustomer: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> createContract(
    Map<String, dynamic> data, {
    http.Client? client,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/HopDong');
      final res = await (client?.post ?? http.post)(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 || res.statusCode == 201) {
        dynamic decoded;
        try {
          decoded = res.body.isEmpty ? null : jsonDecode(res.body);
        } on FormatException {
          decoded = null;
        }
        final responseData = decoded is Map
            ? Map<String, dynamic>.from(decoded)
            : <String, dynamic>{};
        if (responseData['success'] == false) {
          return {
            'success': false,
            'message':
                responseData['message']?.toString() ??
                'Máy chủ từ chối tạo hợp đồng.',
          };
        }
        return {
          ...responseData,
          'success': true,
          'message':
              responseData['message']?.toString() ?? 'Tạo hợp đồng thành công',
        };
      } else {
        dynamic decoded;
        try {
          decoded = jsonDecode(res.body);
        } on FormatException {
          decoded = null;
        }
        return {
          'success': false,
          'message': decoded is Map && decoded['message'] != null
              ? decoded['message'].toString()
              : 'Lỗi (${res.statusCode}): ${res.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối API: $e'};
    }
  }

  static Future<bool> checkOut(int contractId, String note) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/HopDong/$contractId/checkout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'note': note}),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Lỗi checkOut: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> createCheckoutRequest({
    required int contractId,
    required int customerId,
    required String reason,
    required String expectedReturnDate,
    required String bankInfo,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/BaoTraPhong'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'maHopDong': contractId,
              'maKhach': customerId,
              'lyDo': reason,
              'ngayTraDuKien': expectedReturnDate,
              'ghiChu':
                  'Ngày dự kiến bàn giao: $expectedReturnDate'
                  '${bankInfo.isEmpty ? '' : ' | Thông tin nhận cọc: $bankInfo'}',
            }),
          )
          .timeout(const Duration(seconds: 10));

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        decoded = null;
      }
      final data = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message':
              data['message']?.toString() ??
              'Đã gửi thông báo trả phòng đến chủ trọ.',
        };
      }

      return {
        'success': false,
        'message': data['message']?.toString().trim().isNotEmpty == true
            ? data['message'].toString()
            : 'Gửi yêu cầu trả phòng thất bại (${response.statusCode}).',
      };
    } catch (error) {
      return {
        'success': false,
        'message': 'Không thể kết nối để gửi yêu cầu trả phòng: $error',
      };
    }
  }

  // --- BOOKINGS (Đặt Phòng) ---
  static Future<List<dynamic>> getBookings() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/DatPhong'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw Exception('Không thể tải đặt phòng (${res.statusCode})');
    } catch (e) {
      print('Lỗi getBookings: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createBooking(
    Map<String, dynamic> data,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/DatPhong');
      final res = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'success': true, 'message': 'Đặt cọc thành công'};
      } else {
        return {
          'success': false,
          'message': 'Lỗi (${res.statusCode}): ${res.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối API: $e'};
    }
  }

  // Cập nhật một lượt đặt phòng bằng khóa maDatPhong để lưu trạng thái quản lý.
  static Future<Map<String, dynamic>> updateBooking(
    int bookingId,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl/DatPhong/$bookingId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 || res.statusCode == 204) {
        return {'success': true, 'message': 'Cập nhật đặt phòng thành công'};
      }
      return {
        'success': false,
        'message': 'Lỗi (${res.statusCode}): ${res.body}',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối API: $e'};
    }
  }

  // --- REPAIR REQUESTS (Yêu Cầu Sửa Chữa) ---
  static Future<List<dynamic>> getRepairRequests({http.Client? client}) async {
    final uri = Uri.parse('$baseUrl/SuaChua');
    final request = client == null ? http.get(uri) : client.get(uri);
    final response = await request.timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception(
        'Không thể tải yêu cầu sửa chữa (${response.statusCode}): '
        '${response.body}',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException(
        'API sửa chữa trả về danh sách không đúng định dạng.',
      );
    }
    return decoded;
  }

  static Future<Map<String, dynamic>> sendRepairRequest(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/SuaChua'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));
      return _repairApiResult(response, 'Gửi yêu cầu sửa chữa thành công.');
    } catch (error) {
      return {
        'success': false,
        'message': 'Không thể kết nối API sửa chữa: $error',
      };
    }
  }

  static Future<List<dynamic>> getRepairRequestsByCustomer(int maKhach) async {
    if (maKhach <= 0) {
      throw ArgumentError.value(maKhach, 'maKhach', 'Mã khách không hợp lệ.');
    }
    final decoded = await getRepairRequests();
    return decoded.where((request) {
      if (request is! Map) return false;
      final customerId = int.tryParse(
        (request['maKhach'] ?? request['MaKhach'] ?? '').toString(),
      );
      return customerId == maKhach;
    }).toList();
  }

  static Future<Map<String, dynamic>> updateRepairRequest(
    int requestId,
    Map<String, dynamic> data, {
    http.Client? client,
  }) async {
    if (requestId <= 0) {
      return {'success': false, 'message': 'Mã yêu cầu sửa chữa không hợp lệ.'};
    }
    try {
      final uri = Uri.parse('$baseUrl/SuaChua/$requestId');
      final request = client == null
          ? http.put(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(data),
            )
          : client.put(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(data),
            );
      final response = await request.timeout(const Duration(seconds: 10));
      return _repairApiResult(response, 'Đã cập nhật yêu cầu sửa chữa.');
    } catch (error) {
      return {
        'success': false,
        'message': 'Không thể kết nối API cập nhật sửa chữa: $error',
      };
    }
  }

  static Future<Map<String, dynamic>> confirmRepairRequest(int maYeuCau) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/SuaChua/$maYeuCau'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'khachXacNhan': true}),
          )
          .timeout(const Duration(seconds: 10));
      return _repairApiResult(response, 'Đã xác nhận hoàn thành sửa chữa.');
    } catch (error) {
      return {
        'success': false,
        'message': 'Không thể kết nối API xác nhận sửa chữa: $error',
      };
    }
  }

  static Future<Map<String, dynamic>> deleteRepairRequest(int maYeuCau) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/SuaChua/$maYeuCau'))
          .timeout(const Duration(seconds: 10));
      return _repairApiResult(response, 'Đã hủy yêu cầu sửa chữa.');
    } catch (error) {
      return {
        'success': false,
        'message': 'Không thể kết nối API hủy yêu cầu sửa chữa: $error',
      };
    }
  }

  static Map<String, dynamic> _repairApiResult(
    http.Response response,
    String defaultMessage,
  ) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      decoded = null;
    }
    final data = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};
    final isSuccess =
        response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] != false;
    return {
      'success': isSuccess,
      'message': data['message']?.toString().trim().isNotEmpty == true
          ? data['message'].toString()
          : isSuccess
          ? defaultMessage
          : 'API sửa chữa trả về lỗi (${response.statusCode}).',
      'data': data['data'],
    };
  }

  static Future<List<dynamic>> getInvoicesByCustomer(int maKhach) async {
    return getInvoicesForCustomer(maKhach);
  }

  static Future<List<dynamic>> getInvoicesForCustomer(
    int maKhach, {
    http.Client? client,
  }) async {
    final contractsData = await _getCustomerContractsForHistory(
      maKhach,
      client: client,
    );

    final invoicesByContract = await Future.wait(
      contractsData.whereType<Map>().map((contractValue) async {
        final contract = Map<String, dynamic>.from(contractValue);
        final contractId = int.tryParse(
          (contract['maHopDong'] ?? contract['MaHopDong'] ?? '').toString(),
        );
        if (contractId == null) return <Map<String, dynamic>>[];

        final invoices = await getInvoicesForContract(
          contractId,
          client: client,
        );
        return invoices.map((invoiceValue) {
          final invoice = Map<String, dynamic>.from(invoiceValue as Map);
          invoice.putIfAbsent(
            'maPhong',
            () => contract['maPhong'] ?? contract['MaPhong'],
          );
          return invoice;
        }).toList();
      }),
    );

    final invoices = invoicesByContract.expand((items) => items).toList();
    invoices.sort((left, right) {
      final leftYear =
          int.tryParse((left['nam'] ?? left['Nam'] ?? '').toString()) ?? 0;
      final rightYear =
          int.tryParse((right['nam'] ?? right['Nam'] ?? '').toString()) ?? 0;
      final yearOrder = rightYear.compareTo(leftYear);
      if (yearOrder != 0) return yearOrder;
      final leftMonth =
          int.tryParse((left['thang'] ?? left['Thang'] ?? '').toString()) ?? 0;
      final rightMonth =
          int.tryParse((right['thang'] ?? right['Thang'] ?? '').toString()) ??
          0;
      return rightMonth.compareTo(leftMonth);
    });
    return invoices;
  }

  static Future<List<dynamic>> getInvoicesByContract(int maHopDong) async {
    return getInvoicesForContract(maHopDong);
  }

  static Future<List<dynamic>> getInvoicesForContract(
    int maHopDong, {
    http.Client? client,
  }) async {
    final uri = Uri.parse('$baseUrl/HoaDon/hop-dong/$maHopDong');
    final request = client == null
        ? http.get(uri, headers: {'Content-Type': 'application/json'})
        : client.get(uri, headers: {'Content-Type': 'application/json'});
    final response = await request.timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception(
        'Không thể tải hóa đơn hợp đồng #$maHopDong '
        '(${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('API hóa đơn trả về dữ liệu không hợp lệ.');
    }
    return decoded;
  }

  static Future<Map<String, dynamic>> createManualInvoice({
    required int contractId,
    required int month,
    required int year,
    required double total,
    required String note,
    http.Client? client,
  }) async {
    try {
      final response = await (client?.post ?? http.post)(
        Uri.parse('$baseUrl/HoaDon'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'maHopDong': contractId,
          'thang': month,
          'nam': year,
          'tongTien': total,
          'ghiChu': note,
        }),
      ).timeout(const Duration(seconds: 15));

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        decoded = null;
      }

      final result = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          result['success'] == true) {
        return {
          ...result,
          'success': true,
          'message': result['message']?.toString() ?? 'Đã lập hóa đơn.',
        };
      }
      return {
        'success': false,
        'message': result['message']?.toString().trim().isNotEmpty == true
            ? result['message'].toString()
            : 'Không thể lập hóa đơn (${response.statusCode}).',
      };
    } catch (error) {
      return {
        'success': false,
        'message': 'Không thể kết nối để lập hóa đơn: $error',
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getPendingInvoiceViolations({
    required int contractId,
    http.Client? client,
  }) async {
    if (contractId <= 0) {
      throw ArgumentError.value(contractId, 'contractId', 'Must be positive.');
    }

    final uri = Uri.parse(
      '$baseUrl/HoaDon/hop-dong/$contractId/vi-pham-chua-tinh',
    );
    final response = await (client?.get ?? http.get)(
      uri,
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));
    final violations = _decodeListResponse(
      response,
      'Không thể tải các khoản phạt chưa tính vào hóa đơn',
    );
    return violations
        .whereType<Map>()
        .map((violation) => Map<String, dynamic>.from(violation))
        .toList();
  }

  static Future<Map<String, dynamic>> recognizeElectricMeter({
    required Uint8List imageBytes,
    required String filename,
    required int roomId,
    required double oldReading,
    required int month,
    required int year,
    http.Client? client,
    Duration timeout = const Duration(seconds: 35),
    Future<void>? abortTrigger,
  }) async {
    if (imageBytes.isEmpty) {
      return {
        'success': false,
        'message': 'Ảnh đồng hồ điện không có dữ liệu.',
      };
    }
    if (roomId <= 0 || oldReading < 0 || month < 1 || month > 12 || year < 1) {
      return {
        'success': false,
        'message': 'Thông tin đọc chỉ số không hợp lệ.',
      };
    }

    final request =
        http.AbortableMultipartRequest(
            'POST',
            Uri.parse(meterOcrUrl),
            abortTrigger: abortTrigger,
          )
          ..fields.addAll({
            'maPhong': roomId.toString(),
            'chiSoCu': oldReading.toString(),
            'thang': month.toString(),
            'nam': year.toString(),
          })
          ..files.add(
            http.MultipartFile.fromBytes(
              'image',
              imageBytes,
              filename: filename,
            ),
          );

    final requestClient = client ?? http.Client();
    try {
      final response = await requestClient
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
      dynamic decoded;
      try {
        decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      } on FormatException {
        decoded = null;
      }

      final body = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return {
          'success': false,
          'message':
              body['error']?.toString() ??
              body['message']?.toString() ??
              'OCR không đọc được ảnh (${response.statusCode}).',
        };
      }

      final reading = _firstValue(body, const [
        'chiSoMoi',
        'ChiSoMoi',
        'reading',
        'value',
      ]);
      final parsedReading = reading is num
          ? reading.toDouble()
          : double.tryParse(reading?.toString() ?? '');
      if (parsedReading == null || !parsedReading.isFinite) {
        return {
          'success': false,
          'message': 'OCR không trả về chỉ số điện hợp lệ.',
        };
      }
      if (parsedReading < oldReading) {
        return {
          'success': false,
          'message':
              'Chỉ số OCR ($parsedReading kWh) nhỏ hơn chỉ số cũ '
              '($oldReading kWh). Hãy kiểm tra lại ảnh và chỉ số.',
        };
      }

      return {
        'success': true,
        'chiSoMoi': parsedReading,
        'tieuThu': parsedReading - oldReading,
      };
    } on http.RequestAbortedException {
      return {
        'success': false,
        'message': 'Đã dừng nhận diện ảnh đồng hồ điện.',
      };
    } on http.ClientException catch (error) {
      return {
        'success': false,
        'message': 'Không kết nối được máy chủ OCR: $error',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message':
            'Máy chủ OCR không phản hồi sau ${timeout.inSeconds} giây. '
            'Kiểm tra Flask và Ollama đang chạy, rồi thử lại.',
      };
    } catch (error) {
      return {
        'success': false,
        'message': 'Không thể xử lý ảnh đồng hồ điện: $error',
      };
    } finally {
      if (client == null) requestClient.close();
    }
  }

  static Future<List<dynamic>> getCustomerMeterReadings(
    int customerId, {
    http.Client? client,
  }) async {
    final contracts = await _getCustomerContractsForHistory(
      customerId,
      client: client,
    );
    final rooms = <int, dynamic>{};
    for (final value in contracts.whereType<Map>()) {
      final contract = Map<String, dynamic>.from(value);
      final roomId = int.tryParse(
        (contract['maPhong'] ?? contract['MaPhong'] ?? '').toString(),
      );
      if (roomId != null) {
        rooms[roomId] = contract['tenPhong'] ?? contract['TenPhong'];
      }
    }
    if (rooms.isEmpty) return [];

    final uri = Uri.parse('$baseUrl/ChiSoDienNuoc');
    final request = client == null
        ? http.get(uri, headers: {'Content-Type': 'application/json'})
        : client.get(uri, headers: {'Content-Type': 'application/json'});
    final response = await request.timeout(const Duration(seconds: 10));
    final readings = _decodeListResponse(
      response,
      'Không thể tải lịch sử chỉ số điện/nước',
    );
    final filtered = readings
        .whereType<Map>()
        .where((value) {
          final reading = Map<String, dynamic>.from(value);
          final roomId = int.tryParse(
            (reading['maPhong'] ?? reading['MaPhong'] ?? '').toString(),
          );
          return roomId != null && rooms.containsKey(roomId);
        })
        .map((value) {
          final reading = Map<String, dynamic>.from(value);
          final roomId = int.tryParse(
            (reading['maPhong'] ?? reading['MaPhong'] ?? '').toString(),
          );
          if (reading['tenPhong'] == null && reading['TenPhong'] == null) {
            reading['tenPhong'] = rooms[roomId] ?? 'Phòng $roomId';
          }
          return reading;
        })
        .toList();
    filtered.sort(_compareHistoryPeriodDescending);
    return filtered;
  }

  static Future<List<dynamic>> getCustomerServiceHistory(
    int customerId, {
    http.Client? client,
  }) async {
    final contracts = await _getCustomerContractsForHistory(
      customerId,
      client: client,
    );
    final historyByContract = await Future.wait(
      contracts.whereType<Map>().map((value) async {
        final contract = Map<String, dynamic>.from(value);
        final contractId = int.tryParse(
          (contract['maHopDong'] ?? contract['MaHopDong'] ?? '').toString(),
        );
        if (contractId == null) return <Map<String, dynamic>>[];
        final uri = Uri.parse('$baseUrl/DangKyDichVu?maHopDong=$contractId');
        final request = client == null
            ? http.get(uri, headers: {'Content-Type': 'application/json'})
            : client.get(uri, headers: {'Content-Type': 'application/json'});
        final response = await request.timeout(const Duration(seconds: 10));
        final registrations = _decodeListResponse(
          response,
          'Không thể tải dịch vụ của hợp đồng #$contractId',
        );
        return registrations.whereType<Map>().map((entry) {
          final registration = Map<String, dynamic>.from(entry);
          registration.putIfAbsent('maHopDong', () => contractId);
          registration.putIfAbsent(
            'maPhong',
            () => contract['maPhong'] ?? contract['MaPhong'],
          );
          return registration;
        }).toList();
      }),
    );
    final history = historyByContract.expand((entries) => entries).toList();
    history.sort((left, right) {
      final leftDate = DateTime.tryParse(
        (left['ngayBatDau'] ?? left['NgayBatDau'] ?? '').toString(),
      );
      final rightDate = DateTime.tryParse(
        (right['ngayBatDau'] ?? right['NgayBatDau'] ?? '').toString(),
      );
      return (rightDate ?? DateTime(0)).compareTo(leftDate ?? DateTime(0));
    });
    return history;
  }

  static Future<List<dynamic>> _getCustomerContractsForHistory(
    int customerId, {
    http.Client? client,
  }) async {
    if (customerId <= 0) {
      throw ArgumentError.value(
        customerId,
        'customerId',
        'Mã khách không hợp lệ.',
      );
    }
    final uri = Uri.parse('$baseUrl/HopDong/customer/$customerId');
    final request = client == null
        ? http.get(uri, headers: {'Content-Type': 'application/json'})
        : client.get(uri, headers: {'Content-Type': 'application/json'});
    final response = await request.timeout(const Duration(seconds: 10));
    return _decodeListResponse(response, 'Không thể tải hợp đồng khách thuê');
  }

  static List<dynamic> _decodeListResponse(
    http.Response response,
    String operation,
  ) {
    if (response.statusCode != 200) {
      throw Exception('$operation (${response.statusCode}): ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('API trả về danh sách không đúng định dạng.');
    }
    return decoded;
  }

  static int _compareHistoryPeriodDescending(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
  ) {
    final leftYear =
        int.tryParse((left['nam'] ?? left['Nam'] ?? '').toString()) ?? 0;
    final rightYear =
        int.tryParse((right['nam'] ?? right['Nam'] ?? '').toString()) ?? 0;
    final yearOrder = rightYear.compareTo(leftYear);
    if (yearOrder != 0) return yearOrder;
    final leftMonth =
        int.tryParse((left['thang'] ?? left['Thang'] ?? '').toString()) ?? 0;
    final rightMonth =
        int.tryParse((right['thang'] ?? right['Thang'] ?? '').toString()) ?? 0;
    return rightMonth.compareTo(leftMonth);
  }

  static Future<Map<String, dynamic>> collectInvoicePayment({
    required int invoiceId,
    required double amount,
    required String paymentMethod,
    String? note,
    http.Client? client,
  }) async {
    try {
      final response = await (client?.put ?? http.put)(
        Uri.parse('$baseUrl/HoaDon/$invoiceId/thu-tien'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'soTienThu': amount,
          'phuongThuc': paymentMethod,
          'ghiChu': note,
        }),
      ).timeout(const Duration(seconds: 15));

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        decoded = null;
      }
      final result = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          result['success'] == true) {
        return {
          'success': true,
          'message': result['message']?.toString() ?? 'Đã ghi nhận thanh toán.',
          'data': result['data'] is Map
              ? Map<String, dynamic>.from(result['data'] as Map)
              : <String, dynamic>{},
        };
      }

      return {
        'success': false,
        'message': result['message']?.toString().trim().isNotEmpty == true
            ? result['message'].toString()
            : 'Không thể thanh toán hóa đơn (${response.statusCode}).',
      };
    } catch (error) {
      return {
        'success': false,
        'message': 'Không thể kết nối để thanh toán hóa đơn: $error',
      };
    }
  }

  // --- VI PHAM (Vi phạm nội quy) ---
  static Future<List<dynamic>> getViPhams() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/ViPham'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw Exception('Không thể tải vi phạm (${res.statusCode})');
    } catch (e) {
      print('Lỗi getViPhams: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createViPham(
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/ViPham'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final decodedBody = res.body.isEmpty ? null : jsonDecode(res.body);
        if (decodedBody is Map) {
          final body = Map<String, dynamic>.from(decodedBody);
          return {...body, 'success': body['success'] ?? true};
        }
        return {'success': true, 'message': 'Ghi nhận vi phạm thành công'};
      }
      dynamic errorBody;
      try {
        errorBody = jsonDecode(res.body);
      } on FormatException {
        errorBody = null;
      }
      return {
        'success': false,
        'message': errorBody is Map
            ? errorBody['message'] ?? 'Lỗi (${res.statusCode})'
            : 'Lỗi (${res.statusCode}): ${res.body}',
      };
    } catch (e) {
      print('Lỗi createViPham: $e');
      return {'success': false, 'message': 'Lỗi kết nối API: $e'};
    }
  }

  // --- MESSAGES (Tin nhắn & Thông báo) ---
  static Future<List<dynamic>> getMessages(int senderId) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/TinNhan/$senderId'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return jsonDecode(res.body);
      // Báo lỗi rõ ràng để màn hình chat không nhầm lỗi kết nối thành hội thoại trống.
      throw Exception('Không thể tải tin nhắn (${res.statusCode})');
    } catch (e) {
      print('Lỗi getMessages: $e');
      rethrow;
    }
  }

  static Future<bool> sendMessage(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/TinNhan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('Lỗi sendMessage: $e');
      return false;
    }
  }

  static Future<bool> registerDeviceToken({
    required int customerId,
    required String token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/TinNhan/register-device'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'customerIdentity': customerId,
              'deviceToken': token,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      print(
        'Không đăng ký được FCM token (${response.statusCode}): '
        '${response.body}',
      );
      return false;
    } catch (error) {
      print('Lỗi registerDeviceToken: $error');
      return false;
    }
  }

  // --- THONG KE (Thống kê tài chính) ---
  static Future<Map<String, dynamic>> getFinancialStats() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/ThongKe'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw Exception('Không thể tải báo cáo (${res.statusCode})');
    } catch (e) {
      print('Lỗi getFinancialStats: $e');
      rethrow;
    }
  }

  // Báo cáo dùng trực tiếp hai API đang có để không phụ thuộc endpoint /ThongKe riêng.
  static Future<Map<String, List<dynamic>>> getReportSourceData() async {
    final responses = await Future.wait([
      http
          .get(Uri.parse('$baseUrl/Phong'))
          .timeout(const Duration(seconds: 10)),
      http
          .get(Uri.parse('$baseUrl/HoaDon'))
          .timeout(const Duration(seconds: 10)),
    ]);

    final roomResponse = responses[0];
    if (roomResponse.statusCode != 200) {
      throw Exception(
        'Không thể tải danh sách phòng (${roomResponse.statusCode}): '
        '${roomResponse.body}',
      );
    }

    final invoiceResponse = responses[1];
    if (invoiceResponse.statusCode != 200) {
      throw Exception(
        'Không thể tải danh sách hóa đơn (${invoiceResponse.statusCode}): '
        '${invoiceResponse.body}',
      );
    }

    final decodedRooms = jsonDecode(roomResponse.body);
    final decodedInvoices = jsonDecode(invoiceResponse.body);
    if (decodedRooms is! List || decodedInvoices is! List) {
      throw const FormatException(
        'API phòng hoặc hóa đơn không trả về danh sách JSON hợp lệ.',
      );
    }

    return {'rooms': decodedRooms, 'invoices': decodedInvoices};
  }
}

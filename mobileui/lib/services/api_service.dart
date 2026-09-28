import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Cổng HTTP thực tế từ file launchSettings.json của bạn là 5180
  static const String baseUrl = "http://10.0.2.2:5180/api";

  // --- AUTH ---
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      print('Phản hồi từ API Login (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true, 
          'message': 'Đăng nhập thành công',
          'vaiTro': data['vaiTro'] ?? 'Customer',
          'maKhach': data['maKhach']
        };
      } else {
        return {
          'success': false, 
          'message': 'Lỗi đăng nhập (${response.statusCode}): ${response.body}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối Server: $e'};
    }
  }

  static Future<bool> register(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Lỗi register: $e');
      return false;
    }
  }

  static Future<void> logout() async {
    try {
      await http.post(Uri.parse('$baseUrl/Auth/logout'));
    } catch (_) {}
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

  // Lấy danh sách hợp đồng lọc theo mã khách thuê (Đã thêm mới ở Bước 2)
  static Future<List<dynamic>> getContractsByCustomer(int maKhach) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/HopDong/customer/$maKhach'));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print('Lỗi getContractsByCustomer: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> createContract(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$baseUrl/HopDong');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'success': true, 'message': 'Tạo hợp đồng thành công'};
      } else {
        return {'success': false, 'message': 'Lỗi (${res.statusCode}): ${res.body}'};
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

  // --- BOOKINGS (Đặt Phòng) ---
  static Future<List<dynamic>> getBookings() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/DatPhong'));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      print('Lỗi getBookings: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$baseUrl/DatPhong');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'success': true, 'message': 'Đặt cọc thành công'};
      } else {
        return {'success': false, 'message': 'Lỗi (${res.statusCode}): ${res.body}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối API: $e'};
    }
  }
  // --- REPAIR REQUESTS (Yêu Cầu Sửa Chữa) ---
  static Future<bool> sendRepairRequest(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/YeuCauSuaChua'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      print('DEBUG Gửi Yêu Cầu - Status: ${response.statusCode}');
      print('DEBUG Gửi Yêu Cầu - Body: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Lỗi sendRepairRequest: $e');
      return false;
    }
  }
  static Future<List<dynamic>> getRepairRequestsByCustomer(int maKhach) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/YeuCauSuaChua/customer/$maKhach'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Lỗi getRepairRequestsByCustomer: $e');
    }
    return [];
  }
  static Future<List<dynamic>> getInvoicesByCustomer(int maKhach) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/HoaDon/customer/$maKhach'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Lỗi lấy hóa đơn: $e');
      return [];
    }
  }
}
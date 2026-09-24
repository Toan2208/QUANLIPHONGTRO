import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Đã sửa thành HTTPS cổng 7005 để tránh lỗi Redirect 307
  static const String baseUrl = 'https://192.168.2.8:7005/api';

  // --- AUTH ---
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Đăng nhập thành công'};
      } else {
        return {'success': false, 'message': 'Tài khoản hoặc mật khẩu không chính xác!'};
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

  // --- ROOMS ---
  static Future<List<dynamic>> getRooms() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Rooms'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Lỗi getRooms: $e');
    }
    return [];
  }

  static Future<bool> createRoom(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Rooms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Lỗi createRoom: $e');
      return false;
    }
  }

  // --- ROOM TYPES ---
  static Future<List<dynamic>> getRoomTypes() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/RoomTypes'));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      print('Lỗi getRoomTypes: $e');
    }
    return [];
  }

  static Future<bool> createRoomType(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/RoomTypes'),
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
      final res = await http.delete(Uri.parse('$baseUrl/RoomTypes/$typeId'));
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      print('Lỗi deleteRoomType: $e');
      return false;
    }
  }

  // --- CUSTOMERS ---
  static Future<List<dynamic>> getCustomers() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/Customers'));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      print('Lỗi getCustomers: $e');
    }
    return [];
  }

  static Future<bool> createCustomer(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/Customers'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('Lỗi createCustomer: $e');
      return false;
    }
  }

  // --- CONTRACTS ---
  static Future<List<dynamic>> getContracts() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/Contracts'));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      print('Lỗi getContracts: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> createContract(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$baseUrl/Contracts');
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
        Uri.parse('$baseUrl/Contracts/$contractId/checkout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'note': note}),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Lỗi checkOut: $e');
      return false;
    }
  }

  // --- BOOKINGS ---
  static Future<List<dynamic>> getBookings() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/Bookings'));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      print('Lỗi getBookings: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$baseUrl/Bookings');
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
}
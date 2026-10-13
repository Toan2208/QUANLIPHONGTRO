import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../services/api_service.dart';

// Import các màn hình chức năng của khách hàng
import 'customer_contract_screen.dart';
import 'customer_invoice_screen.dart';
import 'repair_request_screen.dart';
import 'checkout_request_screen.dart';
import 'customer_chat_screen.dart'; // Đảm bảo đã import đúng tệp này
import 'customer_profile_screen.dart';
import '../services/push_notification_service.dart';

class CustomerHomeScreen extends StatefulWidget {
  final int maKhach; // Nhận biến maKhach từ LoginScreen

  const CustomerHomeScreen({super.key, required this.maKhach});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _customerScreens;

  @override
  void initState() {
    super.initState();
    // Gắn FCM token của thiết bị với mã khách để backend gửi đúng người nhận.
    unawaited(PushNotificationService.registerCustomer(widget.maKhach));
    // Khởi tạo danh sách màn hình bao gồm cả tính năng Nhận thông báo / Trò chuyện
    _customerScreens = [
      CustomerContractScreen(maKhach: widget.maKhach),
      CustomerInvoiceScreen(maKhach: widget.maKhach),
      RepairRequestScreen(maKhach: widget.maKhach),
      CustomerChatScreen(
        maKhach: widget.maKhach,
      ), // Tab Thông báo & Tin nhắn từ chủ trọ
      CheckoutRequestScreen(maKhach: widget.maKhach),
    ];
  }

  Future<void> _logout() async {
    // Ẩn bàn phím đang mở trước khi hiển thị hộp thoại xác nhận.
    FocusManager.instance.primaryFocus?.unfocus();
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận đăng xuất',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi khu vực khách hàng?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context, true);
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (shouldLogout != true || !mounted) return;

    // Mở màn hình đăng nhập ngay cả khi API logout phản hồi chậm hoặc lỗi.
    await PushNotificationService.clearCustomer();
    if (!mounted) return;
    unawaited(ApiService.logout());
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Color(0xFF2563EB),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cổng Khách Hàng',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Mã KH: #${widget.maKhach}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Thông tin cá nhân',
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Color(0xFF2563EB),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CustomerProfileScreen(maKhach: widget.maKhach),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _customerScreens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: const Color(0xFF2563EB).withOpacity(0.15),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.description_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(
                Icons.description_rounded,
                color: Color(0xFF2563EB),
              ),
              label: 'Hợp đồng',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFF2563EB),
              ),
              label: 'Thanh toán',
            ),
            NavigationDestination(
              icon: Icon(Icons.build_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.build_rounded, color: Color(0xFF2563EB)),
              label: 'Sửa chữa',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.notifications_outlined,
                color: Color(0xFF64748B),
              ),
              selectedIcon: Icon(
                Icons.notifications_rounded,
                color: Color(0xFF2563EB),
              ),
              label: 'Thông báo',
            ),
            NavigationDestination(
              icon: Icon(Icons.exit_to_app_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(
                Icons.exit_to_app_rounded,
                color: Color(0xFF2563EB),
              ),
              label: 'Trả phòng',
            ),
          ],
        ),
      ),
    );
  }
}

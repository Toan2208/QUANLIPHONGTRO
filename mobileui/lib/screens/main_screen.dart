import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'room_list_screen.dart';
import 'contract_list_screen.dart';
import 'booking_list_screen.dart';
import 'customer_list_screen.dart';
import 'room_type_screen.dart';
import 'vi_pham_screen.dart';
import 'thong_ke_screen.dart';
import 'repair_management_screen.dart';
import 'rent_billing_screen.dart';

// Màn hình chính của Chủ trọ (Giao diện Mobile gọn gàng, không tích hợp OCR)
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    RoomListScreen(),
    ContractListScreen(),
    BookingListScreen(),
    CustomerListScreen(),
  ];

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
          'Bạn có chắc chắn muốn đăng xuất khỏi hệ thống quản lý phòng trọ?',
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

    // Không để request mạng làm người dùng mắc kẹt ở màn hình hiện tại.
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
        title: const Text(
          'Quản Lý Phòng Trọ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Công cụ quản lý',
            onSelected: (value) {
              final Widget destination = switch (value) {
                'violations' => const ViPhamScreen(),
                'reports' => const ThongKeScreen(),
                'repairs' => const RepairManagementScreen(),
                'rent-billing' => const RentBillingScreen(),
                _ => const RoomTypeScreen(),
              };
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => destination),
              );
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'violations',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.warning_amber_rounded),
                  title: Text('Vi phạm nội quy'),
                ),
              ),
              PopupMenuItem(
                value: 'repairs',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.handyman_outlined),
                  title: Text('Yêu cầu sửa chữa'),
                ),
              ),
              PopupMenuItem(
                value: 'rent-billing',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.request_quote_outlined),
                  title: Text('Lập tiền thuê theo ngày'),
                ),
              ),
              PopupMenuItem(
                value: 'reports',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.bar_chart_rounded),
                  title: Text('Báo cáo thống kê'),
                ),
              ),
              PopupMenuItem(
                value: 'room-types',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.category_outlined),
                  title: Text('Quản lý loại phòng'),
                ),
              ),
            ],
            icon: const Icon(
              Icons.dashboard_customize_outlined,
              color: Color(0xFF2563EB),
            ),
          ),
          // Nút Đăng xuất
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        elevation: 2,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room, color: Color(0xFF2563EB)),
            label: 'Phòng trọ',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description, color: Color(0xFF2563EB)),
            label: 'Hợp đồng',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark, color: Color(0xFF2563EB)),
            label: 'Đặt chỗ',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: Color(0xFF2563EB)),
            label: 'Khách thuê',
          ),
        ],
      ),
    );
  }
}

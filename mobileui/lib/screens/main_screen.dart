import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'room_list_screen.dart';
import 'contract_list_screen.dart';
import 'booking_list_screen.dart';
import 'customer_list_screen.dart';
import 'room_type_screen.dart';

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

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi hệ thống quản lý phòng trọ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService.logout();
              } catch (_) {}
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Quản Lý Phòng Trọ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          // Nút Quản lý loại phòng
          IconButton(
            icon: const Icon(Icons.category_outlined, color: Color(0xFF2563EB)),
            tooltip: 'Quản lý loại phòng',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RoomTypeScreen()),
              );
            },
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
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
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
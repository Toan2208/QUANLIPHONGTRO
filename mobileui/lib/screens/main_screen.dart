import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'room_list_screen.dart';
import 'contract_list_screen.dart';
import 'booking_list_screen.dart';
import 'customer_list_screen.dart';
import 'room_type_screen.dart';

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
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi hệ thống?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.logout();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Phòng Trọ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C5CE7))),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          // Nút Quản lý loại phòng
          IconButton(
            icon: const Icon(Icons.category_outlined, color: Color(0xFF6C5CE7)),
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
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF6C5CE7),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.meeting_room_rounded), label: 'Phòng trọ'),
          BottomNavigationBarItem(icon: Icon(Icons.description_rounded), label: 'Hợp đồng'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_rounded), label: 'Đặt chỗ'),
          BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Khách thuê'),
        ],
      ),
    );
  }
}
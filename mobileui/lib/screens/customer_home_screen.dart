import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../services/api_service.dart';

// Import các màn hình chức năng của khách hàng
import 'customer_contract_screen.dart';
import 'customer_invoice_screen.dart';
import 'repair_request_screen.dart';
import 'checkout_request_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  final int maKhach; // Thêm nhận biến maKhach từ LoginScreen

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
    // Khởi tạo danh sách màn hình và truyền thẳng widget.maKhach vào từng màn hình
    _customerScreens = [
      CustomerContractScreen(maKhach: widget.maKhach),
      CustomerInvoiceScreen(maKhach: widget.maKhach),
      RepairRequestScreen(maKhach: widget.maKhach),
      CheckoutRequestScreen(maKhach: widget.maKhach),
    ];
  }

  void _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Khu vực Khách hàng (Mã KH: ${widget.maKhach})',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C5CE7)),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          )
        ],
      ),
      body: _customerScreens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF6C5CE7),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.description_rounded), label: 'Hợp đồng'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Thanh toán'),
          BottomNavigationBarItem(icon: Icon(Icons.build_rounded), label: 'Sửa chữa'),
          BottomNavigationBarItem(icon: Icon(Icons.exit_to_app_rounded), label: 'Trả phòng'),
        ],
      ),
    );
  }
}
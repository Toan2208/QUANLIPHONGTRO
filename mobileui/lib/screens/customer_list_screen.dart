import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  late Future<List<dynamic>> _customersFuture;

  @override
  void initState() {
    super.initState();
    // Khởi tạo Future trực tiếp không cần dùng setState trong initState
    _customersFuture = ApiService.getCustomers();
  }

  // Sử dụng ngoặc nhọn { } thay vì => để không trả về Future cho setState
  void _loadData() {
    setState(() {
      _customersFuture = ApiService.getCustomers();
    });
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final cccdCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm Khách Hàng Mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Họ tên')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Số điện thoại')),
            TextField(controller: cccdCtrl, decoration: const InputDecoration(labelText: 'Số CCCD')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) return;
              
              await ApiService.createCustomer({
                'fullName': nameCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'cccd': cccdCtrl.text.trim(),
              });

              if (mounted) {
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text('Thêm', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C5CE7),
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _customersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
          }

          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('Chưa có khách hàng nào'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF6C5CE7),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(item['fullName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('SĐT: ${item['phone'] ?? "Chưa có"} | CCCD: ${item['cccd'] ?? "Chưa có"}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
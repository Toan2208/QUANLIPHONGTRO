import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CreateBookingScreen extends StatefulWidget {
  final Map<String, dynamic> room;

  const CreateBookingScreen({super.key, required this.room});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  List<dynamic> _customers = [];
  int? _selectedCustomerId;
  DateTime _expectedDate = DateTime.now().add(const Duration(days: 3));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    // Đọc giá phòng linh hoạt (price hoặc basePrice)
    final initialPrice = widget.room['price'] ?? widget.room['basePrice'] ?? 0;
    _amountController.text = initialPrice.toString();
  }

  void _loadCustomers() async {
    try {
      final list = await ApiService.getCustomers();
      if (mounted) {
        setState(() {
          _customers = list;
          if (_customers.isNotEmpty) {
            _selectedCustomerId = _customers.first['customerId'] ?? _customers.first['id'];
          }
        });
      }
    } catch (e) {
      print('Lỗi tải khách hàng: $e');
    }
  }

  void _handleCreateBooking() async {
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có khách hàng! Vui lòng qua Tab "Khách thuê" để tạo khách hàng trước.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền cọc!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Chuyển đổi ngày tháng về chuẩn YYYY-MM-DD (Chống lỗi 400 DateOnly của C#)
      String formattedExpectedDate = _expectedDate.toIso8601String().split('T')[0];
      String formattedToday = DateTime.now().toIso8601String().split('T')[0];

      // 2. Đóng gói dữ liệu chuẩn
      final data = {
        'roomId': widget.room['roomId'] ?? widget.room['id'],
        'customerId': _selectedCustomerId,
        'depositAmount': double.tryParse(_amountController.text.trim()) ?? 0,
        'bookingDate': formattedToday,
        'expectedDate': formattedExpectedDate,
        'expectedCheckIn': formattedExpectedDate, // Đồng bộ cả 2 tên thuộc tính
        'status': 'Active',
        'note': _noteController.text.trim(),
        'notes': _noteController.text.trim(),
      };

      final result = await ApiService.createBooking(data);

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nhận đặt cọc thành công!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Đặt cọc thất bại!'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi Server: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomNumber = widget.room['roomNumber'] ?? widget.room['name'] ?? '';

    return Scaffold(
      appBar: AppBar(title: Text('Đặt Cọc Phòng $roomNumber')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chọn khách hàng cọc *', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _customers.isEmpty
                ? const Text(
                    '❌ Chưa có khách hàng nào! Vui lòng qua Tab "Khách thuê" để tạo mới.',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  )
                : DropdownButtonFormField<int>(
                    value: _selectedCustomerId,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: _customers.map<DropdownMenuItem<int>>((c) {
                      final id = c['customerId'] ?? c['id'];
                      final name = c['fullName'] ?? c['name'] ?? 'Khách';
                      final phone = c['phone'] ?? '';
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text('$name - $phone'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCustomerId = val),
                  ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số tiền đặt cọc (VNĐ) *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ngày dự kiến nhận phòng:'),
              subtitle: Text(
                '${_expectedDate.day}/${_expectedDate.month}/${_expectedDate.year}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_month, color: Color(0xFF6C5CE7)),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _expectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) setState(() => _expectedDate = picked);
                },
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: _isLoading ? null : _handleCreateBooking,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'XÁC NHẬN ĐẶT CỌC',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
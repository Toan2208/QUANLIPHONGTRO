import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CheckoutRequestScreen extends StatefulWidget {
  final int maKhach;
  const CheckoutRequestScreen({super.key, required this.maKhach});

  @override
  State<CheckoutRequestScreen> createState() => _CheckoutRequestScreenState();
}

class _CheckoutRequestScreenState extends State<CheckoutRequestScreen> {
  final _reasonController = TextEditingController();
  final _bankInfoController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7)); // Mặc định báo trước 7 ngày
  bool _isSubmitting = false;
  List<dynamic> _activeContracts = [];
  int? _selectedContractId;
  bool _isLoadingContracts = true;

  @override
  void initState() {
    super.initState();
    _loadCustomerContracts();
  }

  // Tải danh sách hợp đồng đang có hiệu lực của khách này
  void _loadCustomerContracts() async {
    try {
      final res = await http.get(Uri.parse('http://10.0.2.2:5180/api/HopDong/customer/${widget.maKhach}'));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _activeContracts = data.where((c) => c['trangThai'] != 'Đã thanh lý').toList();
          if (_activeContracts.isNotEmpty) {
            _selectedContractId = _activeContracts[0]['maHopDong'];
          }
          _isLoadingContracts = false;
        });
        return;
      }
    } catch (e) {
      print('Lỗi tải hợp đồng: $e');
    }
    setState(() => _isLoadingContracts = false);
  }

  void _submitCheckout() {
    if (_selectedContractId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn không có hợp đồng nào đang hiệu lực để trả phòng!')));
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập lý do trả phòng!')));
      return;
    }

    setState(() => _isSubmitting = true);

    // Giả lập hoặc gọi API gửi yêu cầu trả phòng
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => _isSubmitting = false);
      _reasonController.clear();
      _bankInfoController.clear();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thành công'),
          content: const Text('Yêu cầu trả phòng đã được gửi tới chủ trọ. Chủ trọ sẽ liên hệ kiểm tra phòng và quyết toán tiền cọc cho bạn.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu Cầu Trả Phòng & Thanh Lý', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
      ),
      body: _isLoadingContracts
          ? const Center(child: CircularProgressIndicator())
          : _activeContracts.isEmpty
              ? const Center(
                  child: Text('Bạn hiện không có phòng nào đang thuê để trả.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Chọn hợp đồng muốn trả
                      const Text('Chọn phòng / hợp đồng muốn trả:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _selectedContractId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                        ),
                        items: _activeContracts.map<DropdownMenuItem<int>>((contract) {
                          return DropdownMenuItem<int>(
                            value: contract['maHopDong'],
                            child: Text('HĐ #${contract['maHopDong']} - Phòng ${contract['tenPhong'] ?? contract['maPhong']} (Cọc: ${contract['tienCoc'] ?? 0}đ)'),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedContractId = val),
                      ),
                      const SizedBox(height: 20),

                      // 2. Chọn ngày dự kiến trả phòng
                      const Text('Ngày dự kiến bàn giao phòng:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(fontSize: 16)),
                              const Icon(Icons.calendar_today, color: Color(0xFF6C5CE7)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. Nhập số tài khoản nhận lại tiền cọc
                      const Text('Thông tin nhận lại tiền cọc (Ngân hàng / STK / Chủ tài khoản):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _bankInfoController,
                        decoration: InputDecoration(
                          hintText: 'Ví dụ: MB Bank - 0901234567 - Nguyen Van A',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 4. Lý do trả phòng
                      const Text('Lý do trả phòng:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _reasonController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Ví dụ: Chuyển công tác về quê, đổi chỗ ở gần trường...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Nút gửi
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isSubmitting ? null : _submitCheckout,
                          child: _isSubmitting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Gửi Yêu Cầu Trả Phòng', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
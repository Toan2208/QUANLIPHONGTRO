import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CreateContractScreen extends StatefulWidget {
  final Map<String, dynamic> room;

  const CreateContractScreen({super.key, required this.room});

  @override
  State<CreateContractScreen> createState() => _CreateContractScreenState();
}

class _CreateContractScreenState extends State<CreateContractScreen> {
  final _rentCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();

  List<dynamic> _customers = [];
  int? _selectedCustomerId;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Đọc linh hoạt giá phòng (basePrice hoặc price)
    final initialPrice = widget.room['basePrice'] ?? widget.room['price'] ?? 0;
    _rentCtrl.text = initialPrice.toString();
    _depositCtrl.text = initialPrice.toString();
    _loadCustomers();
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
      print('Lỗi tải danh sách khách hàng: $e');
    }
  }

  void _handleCreateContract() async {
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có khách hàng nào! Vui lòng sang tab "Khách thuê" tạo khách hàng trước.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_rentCtrl.text.trim().isEmpty || _depositCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ tiền thuê và tiền cọc!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Format ngày về chuẩn YYYY-MM-DD (Chống lỗi 400 C# DateOnly)
      String formattedStartDate = _startDate.toIso8601String().split('T')[0];
      String formattedEndDate = _endDate.toIso8601String().split('T')[0];

      final depositVal = double.tryParse(_depositCtrl.text.trim()) ?? 0;

      final payload = {
        'roomId': widget.room['roomId'] ?? widget.room['id'],
        'customerId': _selectedCustomerId,
        'startDate': formattedStartDate,
        'endDate': formattedEndDate,
        'monthlyRent': double.tryParse(_rentCtrl.text.trim()) ?? 0,
        'deposit': depositVal,
        'depositAmount': depositVal, // Gửi cả 2 biến để khớp với Model Backend
        'status': 'Active',
      };

      final result = await ApiService.createContract(payload);

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tạo hợp đồng (Nhận phòng) thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Tạo hợp đồng thất bại!'),
              backgroundColor: Colors.red,
            ),
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
      appBar: AppBar(title: Text('Nhận Phòng $roomNumber')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chọn khách thuê *', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _customers.isEmpty
                ? const Text(
                    '❌ Chưa có khách hàng nào trong CSDL! Vui lòng qua Tab "Khách thuê" để tạo mới.',
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
              controller: _rentCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tiền thuê tháng (VNĐ) *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _depositCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tiền cọc (VNĐ) *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Ô chọn Ngày bắt đầu
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ngày bắt đầu hợp đồng:'),
              subtitle: Text(
                '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today, color: Color(0xFF6C5CE7)),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _startDate = picked);
                },
              ),
            ),

            // Ô chọn Ngày kết thúc
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ngày hết hạn hợp đồng:'),
              subtitle: Text(
                '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.event, color: Color(0xFF6C5CE7)),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _endDate = picked);
                },
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
                onPressed: _isLoading ? null : _handleCreateContract,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'XÁC NHẬN NHẬN PHÒNG',
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
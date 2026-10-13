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
  bool _loadingCustomers = true;
  String? _customerLoadError;

  @override
  void initState() {
    super.initState();
    final initialPrice =
        widget.room['basePrice'] ?? widget.room['giaThue'] ?? 0;
    _rentCtrl.text = initialPrice.toString();
    _depositCtrl.text = initialPrice.toString();
    _loadCustomers();
  }

  @override
  void dispose() {
    _rentCtrl.dispose();
    _depositCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _loadingCustomers = true;
      _customerLoadError = null;
    });
    try {
      final list = await ApiService.getCustomersForRentBilling();
      if (mounted) {
        final validCustomers = list
            .where((customer) => _customerId(customer) != null)
            .toList();
        setState(() {
          _customers = validCustomers;
          if (_customers.isNotEmpty) {
            _selectedCustomerId = _customerId(_customers.first);
          }
          _loadingCustomers = false;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _customerLoadError = error.toString();
        _loadingCustomers = false;
      });
    }
  }

  int? _customerId(dynamic customer) {
    if (customer is! Map) return null;
    for (final key in [
      'maKhach',
      'MaKhach',
      'customerId',
      'CustomerId',
      'id',
      'Id',
    ]) {
      final id = int.tryParse(customer[key]?.toString() ?? '');
      if (id != null && id > 0) return id;
    }
    return null;
  }

  String _customerName(dynamic customer) {
    if (customer is! Map) return 'Khách thuê';
    for (final key in [
      'hoTen',
      'HoTen',
      'fullName',
      'FullName',
      'customerName',
      'CustomerName',
    ]) {
      final name = customer[key]?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return 'Khách #${_customerId(customer) ?? 'không rõ mã'}';
  }

  Future<void> _handleCreateContract() async {
    final roomId = int.tryParse(
      (widget.room['maPhong'] ??
              widget.room['MaPhong'] ??
              widget.room['roomId'] ??
              widget.room['RoomId'] ??
              '')
          .toString(),
    );
    final rent = double.tryParse(_rentCtrl.text.trim());
    final deposit = double.tryParse(_depositCtrl.text.trim());
    if (roomId == null || roomId <= 0) {
      _showSnackBar(
        'Phòng không có mã hợp lệ, không thể lập hợp đồng.',
        isError: true,
      );
      return;
    }
    if (_selectedCustomerId == null) {
      _showSnackBar('Vui lòng chọn khách thuê hợp lệ.', isError: true);
      return;
    }

    if (rent == null || rent <= 0 || deposit == null || deposit < 0) {
      _showSnackBar(
        'Tiền thuê phải lớn hơn 0 và tiền cọc không được âm.',
        isError: true,
      );
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      _showSnackBar(
        'Ngày kết thúc phải bằng hoặc sau ngày bắt đầu hợp đồng.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = {
        'maPhong': roomId,
        'maKhachDaiDien': _selectedCustomerId,
        'ngayBatDau': _startDate.toIso8601String().split('T')[0],
        'ngayKetThuc': _endDate.toIso8601String().split('T')[0],
        'giaThueThang': rent,
        'tienCoc': deposit,
        'trangThai': 'Active',
      };

      final result = await ApiService.createContract(payload);

      if (mounted) {
        if (result['success'] == true) {
          _showSnackBar('Tạo hợp đồng nhận phòng thành công!', isError: false);
          Navigator.pop(context, true);
        } else {
          _showSnackBar(
            result['message'] ?? 'Tạo hợp đồng thất bại!',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Lỗi Server: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomNumber =
        widget.room['roomNumber'] ??
        widget.room['RoomNumber'] ??
        widget.room['tenPhong'] ??
        widget.room['TenPhong'] ??
        '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Lập hợp đồng $roomNumber',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chọn khách thuê *',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_loadingCustomers)
                    const Center(child: CircularProgressIndicator())
                  else if (_customerLoadError != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Không tải được danh sách khách thuê.\n$_customerLoadError',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                        TextButton.icon(
                          onPressed: _loadCustomers,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử tải lại'),
                        ),
                      ],
                    )
                  else if (_customers.isEmpty)
                    const Text(
                      'Chưa có khách hàng hợp lệ trong hệ thống. Hãy tạo khách thuê trước.',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    )
                  else
                    DropdownButtonFormField<int>(
                      initialValue: _selectedCustomerId,
                      isExpanded: true,
                      decoration: _inputDecoration('', Icons.person_outline),
                      items: _customers.map<DropdownMenuItem<int>>((c) {
                        final id = _customerId(c);
                        final name = _customerName(c);
                        final phone =
                            c['phone'] ??
                            c['Phone'] ??
                            c['soDienThoai'] ??
                            c['SoDienThoai'] ??
                            '';
                        return DropdownMenuItem<int>(
                          value: id!,
                          child: Text(
                            '$name - $phone',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCustomerId = val),
                    ),
                  const SizedBox(height: 20),

                  const Text(
                    'Tiền thuê tháng (VNĐ) *',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _rentCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                      'Nhập tiền thuê hàng tháng',
                      Icons.payments_outlined,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Tiền cọc (VNĐ) *',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _depositCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                      'Nhập số tiền cọc',
                      Icons.account_balance_wallet_outlined,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Ngày bắt đầu hợp đồng *',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _startDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: Color(0xFF2563EB),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Ngày hết hạn hợp đồng *',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate.isBefore(_startDate)
                            ? _startDate
                            : _endDate,
                        firstDate: _startDate,
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _endDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const Icon(
                            Icons.event_rounded,
                            color: Color(0xFF2563EB),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed:
                    _isLoading ||
                        _loadingCustomers ||
                        _customerLoadError != null ||
                        _selectedCustomerId == null
                    ? null
                    : _handleCreateContract,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'XÁC NHẬN NHẬN PHÒNG',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

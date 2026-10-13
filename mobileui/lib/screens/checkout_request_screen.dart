import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CheckoutRequestScreen extends StatefulWidget {
  final int maKhach;
  const CheckoutRequestScreen({super.key, required this.maKhach});

  @override
  State<CheckoutRequestScreen> createState() => _CheckoutRequestScreenState();
}

class _CheckoutRequestScreenState extends State<CheckoutRequestScreen> {
  final _reasonController = TextEditingController();
  final _bankInfoController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _activeContracts = [];
  int? _selectedContractId;
  bool _isLoadingContracts = true;

  @override
  void initState() {
    super.initState();
    _loadCustomerContracts();
  }

  Future<void> _loadCustomerContracts() async {
    if (mounted) setState(() => _isLoadingContracts = true);
    try {
      final data = await ApiService.getContractsByCustomer(widget.maKhach);
      final contracts = data
          .whereType<Map>()
          .map((contract) => Map<String, dynamic>.from(contract))
          .where((contract) => !_isContractEnded(contract))
          .toList();
      if (!mounted) return;
      setState(() {
        _activeContracts = contracts;
        _selectedContractId = contracts.isEmpty
            ? null
            : int.tryParse((contracts.first['maHopDong'] ?? '').toString());
        _isLoadingContracts = false;
      });
    } catch (e) {
      debugPrint('Lỗi tải hợp đồng: $e');
      if (mounted) setState(() => _isLoadingContracts = false);
    }
  }

  Future<void> _submitCheckout() async {
    if (_selectedContractId == null) {
      _showSnackBar(
        'Bạn không có hợp đồng nào đang hiệu lực để trả phòng!',
        isError: true,
      );
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập lý do trả phòng!', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await ApiService.createCheckoutRequest(
        contractId: _selectedContractId!,
        customerId: widget.maKhach,
        reason: _reasonController.text.trim(),
        bankInfo: _bankInfoController.text.trim(),
        expectedReturnDate:
            '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (result['success'] == true) {
          _reasonController.clear();
          _bankInfoController.clear();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Gửi thông báo thành công',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Text(
                '${result['message']}\n\nChủ trọ sẽ liên hệ kiểm tra phòng và quyết toán tiền cọc cho bạn.',
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Đóng'),
                ),
              ],
            ),
          );
        } else {
          _showSnackBar(
            result['message']?.toString() ??
                'Gửi yêu cầu trả phòng thất bại từ server.',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnackBar('Lỗi kết nối: $e', isError: true);
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _bankInfoController.dispose();
    super.dispose();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Yêu Cầu Trả Phòng',
          style: TextStyle(
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
      body: _isLoadingContracts
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : _activeContracts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.room_service_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bạn hiện không có phòng nào đang thuê để trả.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
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
                          'Chọn phòng / hợp đồng muốn trả:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedContractId,
                          isExpanded:
                              true, // Khắc phục lỗi tràn màn hình ngang (Overflow)
                          decoration: _inputDecoration(
                            '',
                            Icons.description_outlined,
                          ),
                          items: _activeContracts
                              .where(
                                (contract) =>
                                    int.tryParse(
                                      (contract['maHopDong'] ?? '').toString(),
                                    ) !=
                                    null,
                              )
                              .map<DropdownMenuItem<int>>((contract) {
                                final contractId = int.parse(
                                  contract['maHopDong'].toString(),
                                );
                                final roomName = contract['maPhong'] ?? '—';
                                final deposit = _formatAmount(
                                  contract['tienCoc'],
                                );
                                return DropdownMenuItem<int>(
                                  value: contractId,
                                  child: Text(
                                    'HĐ #$contractId - Mã phòng $roomName (Cọc: $deposit đ)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              })
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedContractId = val),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Ngày dự kiến bàn giao phòng:',
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
                              initialDate: _selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 90),
                              ),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
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
                          'Thông tin nhận lại tiền cọc (Ngân hàng / STK / Chủ TK):',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _bankInfoController,
                          decoration: _inputDecoration(
                            'VD: MB Bank - 0901234567 - Nguyen Van A',
                            Icons.account_balance_outlined,
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Lý do trả phòng:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _reasonController,
                          maxLines: 3,
                          decoration: _inputDecoration(
                            'VD: Chuyển công tác về quê, đổi chỗ ở...',
                            Icons.edit_note_rounded,
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
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isSubmitting ? null : _submitCheckout,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'GỬI YÊU CẦU TRẢ PHÒNG',
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

  bool _isContractEnded(Map<String, dynamic> contract) {
    final status = (contract['trangThai'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    return status.contains('thanh lý') ||
        status.contains('thanh ly') ||
        status.contains('kết thúc') ||
        status.contains('ket thuc') ||
        status.contains('hết hạn') ||
        status.contains('het han') ||
        status.contains('hủy') ||
        status.contains('huy') ||
        status == 'terminated' ||
        status == 'cancelled';
  }

  String _formatAmount(dynamic value) {
    final amount = num.tryParse(value?.toString() ?? '');
    if (amount == null) return '—';
    return amount.round().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
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

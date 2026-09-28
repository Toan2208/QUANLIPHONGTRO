import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CustomerContractScreen extends StatefulWidget {
  final int maKhach; // Nhận mã khách từ lúc đăng nhập thành công

  const CustomerContractScreen({super.key, required this.maKhach});

  @override
  State<CustomerContractScreen> createState() => _CustomerContractScreenState();
}

class _CustomerContractScreenState extends State<CustomerContractScreen> {
  List<dynamic> _contracts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  void _loadContracts() async {
    setState(() => _isLoading = true);
    // Gọi API lấy hợp đồng của riêng khách hàng này
    final data = await ApiService.getContractsByCustomer(widget.maKhach);
    setState(() {
      _contracts = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hợp Đồng Thuê Trọ Của Tôi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contracts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.description_outlined, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Bạn chưa có hợp đồng thuê phòng nào.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _loadContracts,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tải lại'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7), foregroundColor: Colors.white),
                      )
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _loadContracts(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _contracts.length,
                    itemBuilder: (context, index) {
                      final item = _contracts[index];
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Hợp đồng #${item['maHopDong'] ?? index + 1}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6C5CE7)),
                                  ),
                                  Chip(
                                    label: Text(
                                      item['trangThai'] ?? 'Đang hiệu lực',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              _buildInfoRow(Icons.meeting_room, 'Phòng:', item['tenPhong'] ?? 'Phòng ${item['maPhong'] ?? ''}'),
                              const SizedBox(height: 8),
                              _buildInfoRow(Icons.attach_money, 'Tiền thuê hàng tháng:', '${item['giaThue'] ?? 0} đ'),
                              const SizedBox(height: 8),
                              _buildInfoRow(Icons.money, 'Tiền cọc:', '${item['tienCoc'] ?? 0} đ'),
                              const SizedBox(height: 8),
                             _buildInfoRow(Icons.date_range, 'Thời hạn:', '${item['ngayBatDau'] ?? ''} -> ${item['ngayKetThuc'] ?? ''}'),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF6C5CE7),
                                    side: const BorderSide(color: Color(0xFF6C5CE7)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    _showContractDetailModal(context, item);
                                  },
                                  icon: const Icon(Icons.info_outline),
                                  label: const Text('Xem chi tiết hợp đồng'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ],
    );
  }

  // Hộp thoại hiển thị chi tiết đầy đủ của hợp đồng
  void _showContractDetailModal(BuildContext context, dynamic contract) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi Tiết Hợp Đồng #${contract['maHopDong']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Phòng: ${contract['tenPhong'] ?? 'Chưa cập nhật'}'),
              const SizedBox(height: 8),
              Text('Khách thuê: ${contract['tenKhach'] ?? 'Chính chủ'}'),
              const SizedBox(height: 8),
              Text('Giá thuê: ${contract['giaThue'] ?? 0} VNĐ'),
              const SizedBox(height: 8),
              Text('Tiền đặt cọc: ${contract['tienCoc'] ?? 0} VNĐ'),
              const SizedBox(height: 8),
              Text('Ngày bắt đầu: ${contract['ngayBatDau'] ?? ''}'),
              const SizedBox(height: 8),
              Text('Ngày kết thúc: ${contract['ngayKetThuc'] ?? ''}'),
              const SizedBox(height: 8),
              Text('Ghi chú / Điều khoản: ${contract['ghiChu'] ?? 'Không có ghi chú thêm.'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
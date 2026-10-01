import 'package:flutter/material.dart';
import 'create_contract_screen.dart';
import 'create_booking_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  final Map<String, dynamic> room;

  const RoomDetailScreen({super.key, required this.room});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'Occupied':
        return Colors.blueAccent;
      case 'Booked':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'Available':
        return 'Còn trống';
      case 'Occupied':
        return 'Đang ở';
      case 'Booked':
        return 'Đã cọc';
      default:
        return 'Bảo trì';
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final status = room['status'] ?? 'Available';
    final statusColor = _getStatusColor(status);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Chi Tiết Phòng ${room['roomNumber'] ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
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
            // Thẻ thông tin chi tiết phòng
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Phòng ${room['roomNumber'] ?? ''}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(status),
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32, color: Color(0xFFE2E8F0)),
                  _buildInfoRow(Icons.layers_outlined, 'Tầng số', '${room['floor'] ?? 1}'),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.category_outlined, 'Loại phòng', room['typeName'] ?? 'Phòng tiêu chuẩn'),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.payments_outlined,
                    'Giá thuê / tháng',
                    '${room['basePrice'] ?? 0} VNĐ',
                    isHighlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Khu vực xử lý nghiệp vụ theo trạng thái phòng
            if (status == 'Available') ...[
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_task_rounded, size: 20),
                  label: const Text(
                    'TẠO HỢP ĐỒNG (NHẬN PHÒNG)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateContractScreen(room: room),
                      ),
                    );
                    if (result == true && mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.bookmark_add_outlined, color: Colors.orange, size: 20),
                  label: const Text(
                    'NHẬN ĐẶT CỌC GIỮ PHÒNG',
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateBookingScreen(room: room),
                      ),
                    );
                    if (result == true && mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                ),
              ),
            ] else if (status == 'Occupied') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.redAccent),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Phòng này đang có người ở. Để trả phòng, vui lòng vào tab "Hợp đồng" và thực hiện thao tác trả phòng.',
                        style: TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (status == 'Booked') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bookmark_rounded, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Phòng này hiện đã được đặt cọc giữ chỗ.", style: TextStyle(color: Color(0xFF9A3412), fontSize: 13)',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Widget hỗ trợ hiển thị dòng thông tin gọn gàng
  Widget _buildInfoRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2563EB), size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: isHighlight ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
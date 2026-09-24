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
        return Colors.red;
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
      appBar: AppBar(
        title: Text(
          'Chi Tiết Phòng ${room['roomNumber'] ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Phòng ${room['roomNumber'] ?? ''}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getStatusText(status),
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 30),
                    ListTile(
                      leading: const Icon(Icons.layers, color: Color(0xFF6C5CE7)),
                      title: const Text('Tầng số'),
                      trailing: Text('${room['floor'] ?? 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.category, color: Color(0xFF6C5CE7)),
                      title: const Text('Loại phòng'),
                      trailing: Text(room['typeName'] ?? 'Thường',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.attach_money, color: Color(0xFF6C5CE7)),
                      title: const Text('Giá thuê / tháng'),
                      trailing: Text(
                        '${room['basePrice'] ?? 0} VNĐ',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF6C5CE7)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (status == 'Available') ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_task, color: Colors.white),
                  label: const Text(
                    'TẠO HỢP ĐỒNG (NHẬN PHÒNG)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.bookmark_add, color: Colors.orange),
                  label: const Text(
                    'NHẬN ĐẶT CỌC GIỮ PHÒNG',
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
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
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Phòng này đang có người ở. Để trả phòng, vui lòng vào tab "Hợp đồng" và bấm Trả phòng.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (status == 'Booked') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bookmark, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Phòng này đã được đặt cọc giữ chỗ.',
                        style: TextStyle(color: Colors.orange),
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
}
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'room_detail_screen.dart';

class RoomListScreen extends StatefulWidget {
  const RoomListScreen({super.key});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  late Future<List<dynamic>> _roomsFuture;
  List<dynamic> _currentRooms = [];

  @override
  void initState() {
    super.initState();
    _roomsFuture = ApiService.getRooms();
  }

  void _loadRooms() {
    setState(() {
      _roomsFuture = ApiService.getRooms();
    });
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Available': return Colors.green;
      case 'Occupied': return Colors.blueAccent;
      case 'Booked': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'Available': return 'Còn trống';
      case 'Occupied': return 'Đang ở';
      case 'Booked': return 'Đã cọc';
      default: return 'Bảo trì';
    }
  }

  // Dialog Thêm phòng mới với giao diện hiện đại và kiểm tra trùng tên
  void _showAddRoomDialog() async {
    final roomNumberCtrl = TextEditingController();
    final floorCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    
    int? selectedRoomTypeId;
    List<dynamic> roomTypes = [];

    try {
      roomTypes = await ApiService.getRoomTypes();
      if (roomTypes.isNotEmpty) {
        selectedRoomTypeId = roomTypes.first['roomTypeId'];
      }
    } catch (_) {}

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Thêm Phòng Mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: roomNumberCtrl,
                    decoration: _dialogInputDecoration('Số/Tên phòng (VD: P101)', Icons.meeting_room_outlined),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: floorCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _dialogInputDecoration('Tầng số', Icons.layers_outlined),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _dialogInputDecoration('Giá thuê hàng tháng (VNĐ)', Icons.payments_outlined),
                  ),
                  const SizedBox(height: 14),
                  if (roomTypes.isNotEmpty)
                    DropdownButtonFormField<int>(
                      value: selectedRoomTypeId,
                      decoration: _dialogInputDecoration('Loại phòng', Icons.category_outlined),
                      items: roomTypes.map<DropdownMenuItem<int>>((type) {
                        return DropdownMenuItem<int>(
                          value: type['roomTypeId'],
                          child: Text('${type['typeName']} (${type['basePrice']} đ)'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedRoomTypeId = val;
                        });
                      },
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final roomNum = roomNumberCtrl.text.trim();
                  final floorText = floorCtrl.text.trim();
                  final priceText = priceCtrl.text.trim();

                  if (roomNum.isEmpty || floorText.isEmpty || priceText.isEmpty) {
                    _showSnackBar('Vui lòng điền đầy đủ thông tin!', isError: true);
                    return;
                  }

                  // Kiểm tra trùng tên phòng
                  bool isDuplicate = _currentRooms.any((r) =>
                      r['roomNumber'].toString().trim().toLowerCase() == roomNum.toLowerCase());

                  if (isDuplicate) {
                    _showSnackBar('Phòng "$roomNum" đã tồn tại trong hệ thống!', isError: true);
                    return;
                  }

                  final data = {
                    'roomNumber': roomNum,
                    'floor': int.parse(floorText),
                    'basePrice': double.parse(priceText),
                    'status': 'Available',
                    'roomTypeId': selectedRoomTypeId,
                  };

                  bool success = await ApiService.createRoom(data);

                  if (mounted) {
                    Navigator.pop(context);
                    if (success) {
                      _showSnackBar('Thêm phòng mới thành công!', isError: false);
                      _loadRooms();
                    } else {
                      _showSnackBar('Thêm phòng thất bại!', isError: true);
                    }
                  }
                },
                child: const Text('Thêm phòng', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
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

  InputDecoration _dialogInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 2,
        onPressed: _showAddRoomDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm phòng', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _roomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          final rooms = snapshot.data ?? [];
          _currentRooms = rooms;

          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.meeting_room_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('Chưa có phòng nào trong hệ thống', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF2563EB),
            onRefresh: () async => _loadRooms(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                final color = _getStatusColor(room['status']);

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RoomDetailScreen(room: room)),
                      );
                      _loadRooms();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.door_front_door_rounded, color: color, size: 26),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Phòng ${room['roomNumber']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tầng ${room['floor']} • ${room['typeName'] ?? "Phòng tiêu chuẩn"}',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${room['basePrice']} VNĐ/tháng',
                                  style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getStatusText(room['status']),
                              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
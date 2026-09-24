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
  List<dynamic> _currentRooms = []; // Lưu danh sách phòng hiện tại để kiểm tra trùng tên

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
      case 'Occupied': return Colors.red;
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

  // Dialog Thêm phòng mới với kiểm tra trùng tên/số phòng
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
            title: const Text('Thêm Phòng Mới', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: roomNumberCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Số/Tên phòng (VD: P101, P102) *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: floorCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tầng số *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Giá thuê hàng tháng (VNĐ) *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (roomTypes.isNotEmpty)
                    DropdownButtonFormField<int>(
                      value: selectedRoomTypeId,
                      decoration: const InputDecoration(
                        labelText: 'Loại phòng',
                        border: OutlineInputBorder(),
                      ),
                      items: roomTypes.map<DropdownMenuItem<int>>((type) {
                        return DropdownMenuItem<int>(
                          value: type['roomTypeId'],
                          child: Text('${type['typeName']} (${type['basePrice']} VNĐ)'),
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
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
                onPressed: () async {
                  final roomNum = roomNumberCtrl.text.trim();
                  final floorText = floorCtrl.text.trim();
                  final priceText = priceCtrl.text.trim();

                  if (roomNum.isEmpty || floorText.isEmpty || priceText.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin!')),
                    );
                    return;
                  }

                  // 🔴 ĐIỀU KIỆN KIỂM TRA TRÙNG TÊN/SỐ PHÒNG
                  bool isDuplicate = _currentRooms.any((r) =>
                      r['roomNumber'].toString().trim().toLowerCase() == roomNum.toLowerCase());

                  if (isDuplicate) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Phòng "$roomNum" đã tồn tại trong hệ thống! Vui lòng nhập tên/số phòng khác.'),
                        backgroundColor: Colors.red,
                      ),
                    );
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thêm phòng mới thành công!')),
                      );
                      _loadRooms();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thêm phòng thất bại!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Thêm phòng', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6C5CE7),
        onPressed: _showAddRoomDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm phòng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _roomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));

          final rooms = snapshot.data ?? [];
          _currentRooms = rooms; // Lưu danh sách phòng hiện tại để kiểm tra trùng tên

          if (rooms.isEmpty) {
            return const Center(child: Text('Chưa có phòng nào. Hãy thêm phòng mới!'));
          }

          return RefreshIndicator(
            onRefresh: () async => _loadRooms(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                final color = _getStatusColor(room['status']);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.door_front_door_rounded, color: color, size: 28),
                    ),
                    title: Text('Phòng ${room['roomNumber']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Tầng ${room['floor']} - ${room['typeName'] ?? "Thường"}'),
                        Text('${room['basePrice']} VNĐ/tháng', style: const TextStyle(color: Color(0xFF6C5CE7), fontWeight: FontWeight.bold)),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                      child: Text(_getStatusText(room['status']), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RoomDetailScreen(room: room)),
                      );
                      _loadRooms();
                    },
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
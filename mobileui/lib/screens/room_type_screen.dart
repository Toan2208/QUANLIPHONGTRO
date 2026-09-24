import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RoomTypeScreen extends StatefulWidget {
  const RoomTypeScreen({super.key});

  @override
  State<RoomTypeScreen> createState() => _RoomTypeScreenState();
}

class _RoomTypeScreenState extends State<RoomTypeScreen> {
  late Future<List<dynamic>> _roomTypesFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _roomTypesFuture = ApiService.getRoomTypes();
    });
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm Loại Phòng Mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Tên loại phòng (Ví dụ: Phòng VIP)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Giá chuẩn (VNĐ)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
            onPressed: () async {
              if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
              bool ok = await ApiService.createRoomType({
                'typeName': nameCtrl.text.trim(),
                'basePrice': double.parse(priceCtrl.text.trim()),
                'description': descCtrl.text.trim(),
              });
              if (mounted) {
                Navigator.pop(context);
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm loại phòng thành công!')));
                  _loadData();
                }
              }
            },
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _deleteRoomType(int id) async {
    bool ok = await ApiService.deleteRoomType(id);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa loại phòng!')));
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Loại Phòng'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6C5CE7),
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm loại phòng', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _roomTypesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));

          final types = snapshot.data ?? [];
          if (types.isEmpty) {
            return const Center(child: Text('Chưa có loại phòng nào'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: types.length,
            itemBuilder: (context, index) {
              final t = types[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF6C5CE7),
                    child: Icon(Icons.category, color: Colors.white),
                  ),
                  title: Text(t['typeName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Giá chuẩn: ${t['basePrice']} VNĐ/tháng', style: const TextStyle(color: Color(0xFF6C5CE7), fontWeight: FontWeight.bold)),
                      if (t['description'] != null && t['description'].toString().isNotEmpty)
                        Text('Mô tả: ${t['description']}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _deleteRoomType(t['roomTypeId']),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
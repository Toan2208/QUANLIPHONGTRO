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

  // Dialog Thêm loại phòng với giao diện đồng bộ
  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Thêm Loại Phòng Mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: _dialogInputDecoration('Tên loại phòng (VD: Phòng VIP)', Icons.category_outlined),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: _dialogInputDecoration('Giá chuẩn hàng tháng (VNĐ)', Icons.payments_outlined),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: _dialogInputDecoration('Mô tả tiện ích, diện tích...', Icons.description_outlined),
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
              if (nameCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) {
                _showSnackBar('Vui lòng nhập tên và giá chuẩn của loại phòng!', isError: true);
                return;
              }

              bool ok = await ApiService.createRoomType({
                'typeName': nameCtrl.text.trim(),
                'basePrice': double.parse(priceCtrl.text.trim()),
                'description': descCtrl.text.trim(),
              });

              if (mounted) {
                Navigator.pop(context);
                if (ok) {
                  _showSnackBar('Thêm loại phòng thành công!', isError: false);
                  _loadData();
                } else {
                  _showSnackBar('Thêm loại phòng thất bại!', isError: true);
                }
              }
            },
            child: const Text('Lưu loại phòng', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // Dialog xác nhận xóa loại phòng an toàn
  void _confirmDelete(int id, String typeName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn xóa loại phòng "$typeName" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              bool ok = await ApiService.deleteRoomType(id);
              if (ok && mounted) {
                _showSnackBar('Đã xóa loại phòng thành công!', isError: false);
                _loadData();
              } else if (mounted) {
                _showSnackBar('Không thể xóa loại phòng đang được sử dụng!', isError: true);
              }
            },
            child: const Text('Xóa'),
          ),
        ],
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
      appBar: AppBar(
        title: const Text('Quản Lý Loại Phòng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 2,
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm loại phòng', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _roomTypesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          final types = snapshot.data ?? [];
          if (types.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('Chưa có loại phòng nào', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF2563EB),
            onRefresh: () async => _loadData(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: types.length,
              itemBuilder: (context, index) {
                final t = types[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.category_rounded, color: Color(0xFF2563EB), size: 26),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t['typeName'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Giá chuẩn: ${t['basePrice']} VNĐ/tháng',
                                style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              if (t['description'] != null && t['description'].toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Mô tả: ${t['description']}',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          tooltip: 'Xóa loại phòng',
                          onPressed: () => _confirmDelete(t['roomTypeId'], t['typeName'] ?? ''),
                        ),
                      ],
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
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
  String _selectedFilter = 'Tất cả';

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
      case 'Trống':
        return Colors.green;
      case 'Đang thuê':
        return Colors.blueAccent;
      case 'Đã đặt cọc':
        return Colors.orange;
      case 'Bảo trì':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  void _showAddRoomDialog() async {
    final tenPhongCtrl = TextEditingController();
    final tangCtrl = TextEditingController();
    final giaThueCtrl = TextEditingController();
    final moTaCtrl = TextEditingController();

    int? selectedMaLoaiPhong;
    List<dynamic> roomTypes = [];

    try {
      roomTypes = await ApiService.getRoomTypes();
      if (roomTypes.isNotEmpty) {
        final firstType = roomTypes.first;
        if (firstType is Map) {
          selectedMaLoaiPhong = int.tryParse(
            (firstType['maLoaiPhong'] ??
                        firstType['MaLoaiPhong'] ??
                        firstType['roomTypeId'] ??
                        firstType['RoomTypeId'])
                    ?.toString() ??
                '',
          );
        }
      }
    } catch (_) {}

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Thêm Phòng Mới',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: tenPhongCtrl,
                    decoration: _dialogInputDecoration(
                      'Tên phòng (VD: Phòng A105)',
                      Icons.meeting_room_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: tangCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _dialogInputDecoration(
                      'Tầng số',
                      Icons.layers_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: giaThueCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _dialogInputDecoration(
                      'Giá thuê hàng tháng (VNĐ)',
                      Icons.payments_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: moTaCtrl,
                    maxLines: 2,
                    decoration: _dialogInputDecoration(
                      'Mô tả tiện ích phòng',
                      Icons.description_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (roomTypes.isNotEmpty)
                    DropdownButtonFormField<int>(
                      value: selectedMaLoaiPhong,
                      isExpanded: true,
                      decoration: _dialogInputDecoration(
                        'Loại phòng',
                        Icons.category_outlined,
                      ),
                      items: roomTypes.map<DropdownMenuItem<int>>((type) {
                        final typeId = int.tryParse(
                          (type['maLoaiPhong'] ??
                                      type['MaLoaiPhong'] ??
                                      type['roomTypeId'] ??
                                      type['RoomTypeId'])
                                  ?.toString() ??
                              '',
                        );
                        final typeName =
                            type['tenLoaiPhong'] ??
                            type['TenLoaiPhong'] ??
                            type['typeName'] ??
                            type['TypeName'] ??
                            'Loại phòng';
                        final basePrice =
                            type['giaMacDinh'] ??
                            type['GiaMacDinh'] ??
                            type['basePrice'] ??
                            type['BasePrice'] ??
                            0;
                        if (typeId == null) {
                          return const DropdownMenuItem<int>(
                            value: null,
                            enabled: false,
                            child: Text('Loại phòng không có mã hợp lệ'),
                          );
                        }
                        return DropdownMenuItem<int>(
                          value: typeId,
                          child: Text(
                            '$typeName ($basePrice đ)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedMaLoaiPhong = val;
                        });
                      },
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Hủy',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final tenPhong = tenPhongCtrl.text.trim();
                  final tangText = tangCtrl.text.trim();
                  final giaThueText = giaThueCtrl.text.trim();

                  if (tenPhong.isEmpty ||
                      tangText.isEmpty ||
                      giaThueText.isEmpty) {
                    _showSnackBar(
                      'Vui lòng điền đầy đủ thông tin bắt buộc!',
                      isError: true,
                    );
                    return;
                  }

                  bool isDuplicate = _currentRooms.any(
                    (r) =>
                        (r['tenPhong'] ?? r['roomNumber'] ?? '')
                            .toString()
                            .trim()
                            .toLowerCase() ==
                        tenPhong.toLowerCase(),
                  );

                  if (isDuplicate) {
                    _showSnackBar(
                      'Phòng "$tenPhong" đã tồn tại trong hệ thống!',
                      isError: true,
                    );
                    return;
                  }

                  final data = {
                    'tenPhong': tenPhong,
                    'tang': int.parse(tangText),
                    'giaThue': double.parse(giaThueText),
                    'trangThai': 'Trống',
                    'moTa': moTaCtrl.text.trim(),
                    'maLoaiPhong': selectedMaLoaiPhong,
                    'maCoSo': 1,
                  };

                  bool success = await ApiService.createRoom(data);

                  if (mounted) {
                    Navigator.pop(context);
                    if (success) {
                      _showSnackBar(
                        'Thêm phòng mới thành công!',
                        isError: false,
                      );
                      _loadRooms();
                    } else {
                      _showSnackBar(
                        'Thêm phòng thất bại từ server!',
                        isError: true,
                      );
                    }
                  }
                },
                child: const Text(
                  'Thêm phòng',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
        label: const Text(
          'Thêm phòng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _roomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi tải dữ liệu: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          _currentRooms = snapshot.data ?? [];

          // Lọc danh sách theo trạng thái được chọn trên giao diện
          final filteredRooms = _selectedFilter == 'Tất cả'
              ? _currentRooms
              : _currentRooms
                    .where(
                      (r) => (r['trangThai'] ?? r['status']) == _selectedFilter,
                    )
                    .toList();

          return Column(
            children: [
              // Thanh lọc trạng thái phòng nhanh chóng cho Admin
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children:
                      [
                        'Tất cả',
                        'Trống',
                        'Đang thuê',
                        'Đã đặt cọc',
                        'Bảo trì',
                      ].map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: isSelected,
                            selectedColor: const Color(0xFF2563EB),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onSelected: (selected) {
                              setState(() => _selectedFilter = filter);
                            },
                          ),
                        );
                      }).toList(),
                ),
              ),
              Expanded(
                child: filteredRooms.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.meeting_room_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Không có phòng nào ở trạng thái "$_selectedFilter"',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: const Color(0xFF2563EB),
                        onRefresh: () async => _loadRooms(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: filteredRooms.length,
                          itemBuilder: (context, index) {
                            final room = filteredRooms[index];
                            final tenPhong =
                                room['tenPhong'] ??
                                room['roomNumber'] ??
                                'Phòng';
                            final tang = room['tang'] ?? room['floor'] ?? 1;
                            final giaThue =
                                room['giaThue'] ?? room['basePrice'] ?? 0;
                            final trangThai =
                                room['trangThai'] ?? room['status'] ?? 'Trống';
                            final color = _getStatusColor(trangThai);

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          RoomDetailScreen(room: room),
                                    ),
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.door_front_door_rounded,
                                          color: color,
                                          size: 26,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tenPhong,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Tầng $tang • ${room['moTa'] ?? "Phòng trọ tiện nghi"}',
                                              style: const TextStyle(
                                                color: Color(0xFF64748B),
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '$giaThue VNĐ/tháng',
                                              style: const TextStyle(
                                                color: Color(0xFF2563EB),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          trangThai,
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

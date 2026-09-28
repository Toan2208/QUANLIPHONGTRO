import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'room_list_screen.dart';
import 'contract_list_screen.dart';
import 'booking_list_screen.dart';
import 'customer_list_screen.dart';
import 'room_type_screen.dart';

// Màn hình chính của Chủ trọ
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    RoomListScreen(),
    ContractListScreen(),
    BookingListScreen(),
    CustomerListScreen(),
  ];

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi hệ thống?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService.logout();
              } catch (e) {
                // Bỏ qua lỗi API cục bộ
              }
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Phòng Trọ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C5CE7))),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          // Nút Chọn ảnh OCR Đồng Hồ Điện (Nhiệm vụ Tuần 6)
          IconButton(
            icon: const Icon(Icons.photo_library_rounded, color: Color(0xFF6C5CE7)),
            tooltip: 'Chọn ảnh đồng hồ điện OCR',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NhapDienOcrScreen()),
              );
            },
          ),
          // Nút Quản lý loại phòng
          IconButton(
            icon: const Icon(Icons.category_outlined, color: Color(0xFF6C5CE7)),
            tooltip: 'Quản lý loại phòng',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RoomTypeScreen()),
              );
            },
          ),
          // Nút Đăng xuất
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF6C5CE7),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.meeting_room_rounded), label: 'Phòng trọ'),
          BottomNavigationBarItem(icon: Icon(Icons.description_rounded), label: 'Hợp đồng'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_rounded), label: 'Đặt chỗ'),
          BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Khách thuê'),
        ],
      ),
    );
  }
}

// ==========================================
// MÀN HÌNH CHỌN ẢNH OCR ĐỒNG HỒ ĐIỆN (MOBILE)
// ==========================================
class NhapDienOcrScreen extends StatefulWidget {
  const NhapDienOcrScreen({super.key});

  @override
  State<NhapDienOcrScreen> createState() => _NhapDienOcrScreenState();
}

class _NhapDienOcrScreenState extends State<NhapDienOcrScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String _ketQuaAI = '';
  
  final TextEditingController _maPhongController = TextEditingController();
  final TextEditingController _chiSoCuController = TextEditingController();
  final TextEditingController _thangController = TextEditingController(text: '9');
  final TextEditingController _namController = TextEditingController(text: '2026');

  @override
  void initState() {
    super.initState();
    _checkLostData();
  }

  Future<void> _checkLostData() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty) return;
      if (response.file != null) {
        setState(() {
          _imageFile = File(response.file!.path);
        });
      }
    } catch (e) {
      print('Lỗi khôi phục ảnh: $e');
    }
  }

  Future<void> _chonAnh() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF6C5CE7)),
                title: const Text('Chụp ảnh mới bằng Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
                    if (pickedFile != null) {
                      setState(() {
                        _imageFile = File(pickedFile.path);
                        _ketQuaAI = '';
                      });
                    }
                  } catch (e) {
                    print('Lỗi mở camera: $e');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF6C5CE7)),
                title: const Text('Chọn ảnh sẵn từ Thư viện'),
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setState(() {
                        _imageFile = File(pickedFile.path);
                        _ketQuaAI = '';
                      });
                    }
                  } catch (e) {
                    print('Lỗi chọn thư viện: $e');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _xuLyOcrVaTinhTien() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ảnh đồng hồ điện trước!')));
      return;
    }

    if (_maPhongController.text.isEmpty || _chiSoCuController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập mã phòng và chỉ số cũ!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse('http://10.0.2.2:5000/api/ocr-dong-ho'));
      request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));
      request.fields['maPhong'] = _maPhongController.text;
      request.fields['chiSoCu'] = _chiSoCuController.text;
      request.fields['thang'] = _thangController.text;
      request.fields['nam'] = _namController.text;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          _ketQuaAI = 'Thành công!\n- Chỉ số mới: ${data['chiSoMoi']} kWh\n- Tiêu thụ: ${data['tieuThu']} kWh\n- Tổng tiền hóa đơn: ${data['tongTienHoaDon']} đ';
        });
      } else {
        setState(() {
          _ketQuaAI = 'Lỗi từ server: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _ketQuaAI = 'Không kết nối được đến dịch vụ OCR: $e\n(Hãy đảm bảo dịch vụ Python đang bật)';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập Điện Bằng OCR (Mobile)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _maPhongController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Mã Phòng', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _chiSoCuController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Chỉ số điện tháng trước (kWh)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _thangController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Tháng', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _namController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Năm', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey),
              ),
              child: _imageFile == null
                  ? const Center(child: Text('Chưa chọn ảnh đồng hồ điện', style: TextStyle(color: Colors.grey)))
                  : Image.file(_imageFile!, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
              onPressed: _chonAnh,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Chọn hoặc Chụp Ảnh Đồng Hồ'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7), 
                      foregroundColor: Colors.white, 
                      padding: const EdgeInsets.all(14),
                    ),
                    onPressed: _xuLyOcrVaTinhTien,
                    child: const Text('Phân Tích OCR & Tạo Hóa Đơn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
            const SizedBox(height: 20),
            if (_ketQuaAI.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50], 
                  border: Border.all(color: Colors.green), 
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_ketQuaAI, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.green)),
              ),
          ],
        ),
      ),
    );
  }
}
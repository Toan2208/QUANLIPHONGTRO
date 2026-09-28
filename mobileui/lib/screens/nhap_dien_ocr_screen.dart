import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  // Hàm chụp ảnh từ camera điện thoại
  Future<void> _chupAnh() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _ketQuaAI = '';
      });
    }
  }

  // Gửi ảnh sang Python/API để OCR và tính tiền
  Future<void> _xuLyOcrVaTinhTien() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chụp ảnh đồng hồ điện trước!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Giả sử bạn tạo một API trung gian hoặc Python chạy sẵn endpoint nhận ảnh
      // Hoặc gọi thẳng tới API Python xử lý OCR: http://10.0.2.2:5000/ocr-dhd
      var request = http.MultipartRequest('POST', Uri.parse('http://10.0.2.2:5000/api/ocr-dong-ho'));
      request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));
      request.fields['maPhong'] = _maPhongController.text;
      request.fields['chiSoCu'] = _chiSoCuController.text;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          _ketQuaAI = 'Đọc thành công!\n- Chỉ số mới: ${data['chiSoMoi']} kWh\n- Tiêu thụ: ${data['tieuThu']} kWh\n- Tổng tiền: ${data['tongTien']} đ';
        });
      } else {
        setState(() {
          _ketQuaAI = 'Lỗi xử lý từ hệ thống: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _ketQuaAI = 'Không kết nối được đến dịch vụ OCR: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập Số Điện Bằng OCR (Camera)', style: TextStyle(fontWeight: FontWeight.bold)),
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
              decoration: const InputDecoration(labelText: 'Nhập Mã Phòng cần ghi điện', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _chiSoCuController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nhập Chỉ số điện tháng trước (kWh)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            
            // Khu vực hiển thị ảnh chụp
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey),
              ),
              child: _imageFile == null
                  ? const Center(child: Text('Chưa có ảnh đồng hồ điện', style: TextStyle(color: Colors.grey)))
                  : Image.file(_imageFile!, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
              onPressed: _chupAnh,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Mở Camera Chụp Đồng Hồ Điện'),
            ),
            const SizedBox(height: 20),

            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7), foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
                    onPressed: _xuLyOcrVaTinhTien,
                    child: const Text('Phân Tích OCR & Tạo Hóa Đơn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
            
            const SizedBox(height: 20),
            if (_ketQuaAI.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green[50], border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(8)),
                child: Text(_ketQuaAI, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color.fromARGB(255, 7, 74, 9))),
              ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RepairRequestScreen extends StatefulWidget {
  final int maKhach;
  const RepairRequestScreen({super.key, required this.maKhach});

  @override
  State<RepairRequestScreen> createState() => _RepairRequestScreenState();
}

class _RepairRequestScreenState extends State<RepairRequestScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final _contentController = TextEditingController();
  String _priority = 'Bình thường';
  bool _isSubmitting = false;
  bool _isLoadingHistory = true;
  
  List<dynamic> _historyRequests = [];
  int? _customerMaPhong; // Biến lưu tự động mã phòng của khách

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
    _fetchCustomerRoom(); // Tự động lấy phòng của khách khi vừa mở trang
  }

  // Tự động lấy mã phòng từ hợp đồng đang hiệu lực của khách
  void _fetchCustomerRoom() async {
    try {
      final contracts = await ApiService.getContractsByCustomer(widget.maKhach);
      if (contracts.isNotEmpty) {
        // Lấy mã phòng từ hợp đồng đầu tiên tìm được của khách
        setState(() {
          _customerMaPhong = contracts[0]['maPhong'] ?? contracts[0]['MaPhong'];
        });
      }
    } catch (e) {
      print('Lỗi lấy phòng của khách: $e');
    }
  }

  // Tải lịch sử sửa chữa từ API / Database
  void _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    final data = await ApiService.getRepairRequestsByCustomer(widget.maKhach);
    setState(() {
      _historyRequests = data;
      _isLoadingHistory = false;
    });
  }

  void _submitRequest() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung cần sửa chữa!'), backgroundColor: Colors.red),
      );
      return;
    }

    // Nếu khách chưa có hợp đồng/phòng trên hệ thống, mặc định tạm gán phòng 1 hoặc yêu cầu liên hệ chủ trọ
    if (_customerMaPhong == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin phòng của bạn. Vui lòng kiểm tra lại hợp đồng!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final requestData = {
        'MaPhong': _customerMaPhong ?? 1,
        'maPhong': _customerMaPhong ?? 1,
        'MaKhach': widget.maKhach,
        'maKhach': widget.maKhach,
        'NoiDung': content,
        'noiDung': content,
        'TrangThai': 'Chờ tiếp nhận',
        'trangThai': 'Chờ tiếp nhận',
        'MucDo': _priority,
        'mucDo': _priority,
        'NgayBao': DateTime.now().toIso8601String(),
        'ngayBao': DateTime.now().toIso8601String(),
      };

      bool success = await ApiService.sendRepairRequest(requestData);

      if (success && mounted) {
        _contentController.clear();
        _loadHistory(); // Tải lại danh sách từ server
        _tabController.animateTo(1); // Chuyển sang tab lịch sử

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gửi yêu cầu sửa chữa thành công!')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gửi yêu cầu thất bại, vui lòng thử lại.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo Cáo & Xử Lý Sửa Chữa', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.add_comment), text: 'Gửi yêu cầu mới'),
            Tab(icon: Icon(Icons.history), text: 'Lịch sử & Tiến độ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: FORM GỬI YÊU CẦU
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hiển thị thông tin phòng tự động nhận diện cho khách yên tâm
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.meeting_room, color: Color(0xFF6C5CE7)),
                      const SizedBox(width: 10),
                      Text(
                        _customerMaPhong != null ? 'Phòng gửi báo cáo: Phòng $_customerMaPhong' : 'Đang nhận diện phòng thuê...',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C5CE7)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Mức độ hư hỏng:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Bình thường'),
                        value: 'Bình thường',
                        groupValue: _priority,
                        onChanged: (val) => setState(() => _priority = val!),
                        activeColor: const Color(0xFF6C5CE7),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Khẩn cấp', style: TextStyle(color: Colors.red)),
                        value: 'Khẩn cấp',
                        groupValue: _priority,
                        onChanged: (val) => setState(() => _priority = val!),
                        activeColor: Colors.red,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Mô tả chi tiết sự cố cần sửa:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                TextField(
                  controller: _contentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: Điều hòa không lạnh, bóng đèn phòng ngủ cháy...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSubmitting ? null : _submitRequest,
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Gửi Yêu Cầu Sửa Chữa', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // TAB 2: LỊCH SỬ & THEO DÕI TRẠNG THÁI
          _isLoadingHistory
              ? const Center(child: CircularProgressIndicator())
              : _historyRequests.isEmpty
                  ? const Center(child: Text('Chưa có lịch sử báo cáo sửa chữa nào.', style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: () async => _loadHistory(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _historyRequests.length,
                        itemBuilder: (context, index) {
                          final req = _historyRequests[index];
                          final String status = req['trangThai'] ?? 'Chờ tiếp nhận';
                          
                          Color statusColor = Colors.orange;
                          if (status == 'Đang xử lý') statusColor = Colors.blue;
                          if (status == 'Đã hoàn thành') statusColor = Colors.green;
                          if (status == 'Chờ tiếp nhận') statusColor = Colors.purple;

                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Yêu cầu #${req['maYeuCau'] ?? index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C5CE7))),
                                      Chip(
                                        label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 11)),
                                        backgroundColor: statusColor,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Text('Nội dung: ${req['noiDung'] ?? ''}', style: const TextStyle(fontSize: 15)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Ngày gửi: ${req['ngayBao'] != null ? req['ngayBao'].toString().substring(0, 10) : ''}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                      Text('Phòng: ${req['maPhong'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }
}
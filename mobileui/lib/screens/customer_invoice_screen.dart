import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CustomerInvoiceScreen extends StatefulWidget {
  final int maKhach;
  const CustomerInvoiceScreen({super.key, required this.maKhach});

  @override
  State<CustomerInvoiceScreen> createState() => _CustomerInvoiceScreenState();
}

class _CustomerInvoiceScreenState extends State<CustomerInvoiceScreen> {
  List<dynamic> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  void _loadInvoices() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('http://10.0.2.2:5180/api/HoaDon/customer/${widget.maKhach}'));
      if (res.statusCode == 200) {
        setState(() {
          _invoices = jsonDecode(res.body);
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      print('Lỗi tải hóa đơn: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hóa Đơn Hàng Tháng', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invoices.isEmpty
              ? const Center(
                  child: Text('Không có hóa đơn nào.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _invoices.length,
                  itemBuilder: (context, index) {
                    final inv = _invoices[index];
                    final bool isPaid = inv['trangThai'] == 'Đã thanh toán';
                    final int thang = inv['thang'] ?? 1;
                    final int nam = inv['nam'] ?? 2026;
                    final double tongTien = (inv['tongTien'] ?? 0).toDouble();

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          'Hóa đơn tháng $thang/$nam',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text('Tổng tiền: ${tongTien.toStringAsFixed(0)} đ', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Chip(
                              label: Text(inv['trangThai'] ?? 'Chưa thanh toán', style: const TextStyle(color: Colors.white, fontSize: 11)),
                              backgroundColor: isPaid ? Colors.green : Colors.orange,
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Bấm vào để mở màn hình chi tiết và thanh toán QR
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InvoiceDetailScreen(invoice: inv),
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

// Màn hình chi tiết hóa đơn & quét mã QR thanh toán
class InvoiceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final double tongTien = (invoice['tongTien'] ?? 0).toDouble();
    final String trangThai = invoice['trangThai'] ?? 'Chưa thanh toán';
    final int thang = invoice['thang'] ?? 1;
    final int nam = invoice['nam'] ?? 2026;
    final String hanThanhToan = invoice['hanThanhToan'] != null ? invoice['hanThanhToan'].toString().substring(0, 10) : 'N/A';

    // Tạo link VietQR tự động điền số tiền và nội dung
    String bankId = 'VCB'; // Mã ngân hàng (ví dụ: VCB, MB, Techcombank...)
    String accountNo = '1234567890'; // Số tài khoản chủ trọ
    String accountName = 'CHU TRO';
    String qrUrl = 'https://img.vietqr.io/image/$bankId-$accountNo-compact2.png?amount=$tongTien&addInfo=Thanh%20toan%20HD%20thang%20$thang%20nam%20$nam&accountName=$accountName';

    return Scaffold(
      appBar: AppBar(
        title: Text('Chi Tiết Hóa Đơn Tháng $thang/$nam'),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Kỳ hóa đơn: Tháng $thang/$nam', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Chip(
                          label: Text(trangThai, style: const TextStyle(color: Colors.white)),
                          backgroundColor: trangThai == 'Đã thanh toán' ? Colors.green : Colors.orange,
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Hạn thanh toán:', style: TextStyle(color: Colors.grey)),
                        Text(hanThanhToan, style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tổng tiền thanh toán:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('${tongTien.toStringAsFixed(0)} đ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Quét mã QR để thanh toán (Ngân hàng / MoMo):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
                ),
                child: Column(
                  children: [
                    Image.network(
                      qrUrl,
                      height: 220,
                      width: 220,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          height: 220,
                          width: 220,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const Text('Không thể tải mã QR.'),
                    ),
                    const SizedBox(height: 10),
                    const Text('Sử dụng App Ngân hàng hoặc MoMo để quét', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã gửi yêu cầu xác nhận thanh toán tới chủ trọ!')),
                  );
                },
                child: const Text('Xác nhận đã chuyển khoản', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
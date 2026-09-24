import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ContractListScreen extends StatefulWidget {
  const ContractListScreen({super.key});

  @override
  State<ContractListScreen> createState() => _ContractListScreenState();
}

class _ContractListScreenState extends State<ContractListScreen> {
  late Future<List<dynamic>> _contractsFuture;

  @override
  void initState() {
    super.initState();
    // Khởi tạo Future trực tiếp
    _contractsFuture = ApiService.getContracts();
  }

  // Dùng ngoặc nhọn { } để không vô tình return Future cho setState
  void _loadData() {
    setState(() {
      _contractsFuture = ApiService.getContracts();
    });
  }

  void _handleCheckOut(int contractId) async {
    bool ok = await ApiService.checkOut(contractId, "Khách trả phòng đúng hạn");
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trả phòng thành công!')),
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _contractsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
        }

        final contracts = snapshot.data ?? [];
        if (contracts.isEmpty) {
          return const Center(child: Text('Chưa có hợp đồng nào'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contracts.length,
          itemBuilder: (context, index) {
            final c = contracts[index];
            final isActive = c['status'] == 'Active';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  'Phòng ${c['roomNumber'] ?? ""} - Khách: ${c['customerName'] ?? ""}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Giá: ${c['monthlyRent']} VNĐ | Cọc: ${c['deposit']} VNĐ'),
                    const SizedBox(height: 2),
                    Text(
                      'Trạng thái: ${isActive ? "Đang hiệu lực" : "Đã thanh lý"}',
                      style: TextStyle(
                        color: isActive ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                trailing: isActive
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: () => _handleCheckOut(c['contractId']),
                        child: const Text('Trả phòng', style: TextStyle(color: Colors.white)),
                      )
                    : const Chip(label: Text('Đã xong')),
              ),
            );
          },
        );
      },
    );
  }
}
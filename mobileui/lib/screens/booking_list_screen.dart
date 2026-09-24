import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: ApiService.getBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final bookings = snapshot.data ?? [];

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final b = bookings[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.bookmark, color: Colors.orange),
                title: Text('Phòng ${b['roomNumber']} - Khách: ${b['customerName']}'),
                subtitle: Text('Tiền cọc: ${b['depositAmount']} VNĐ\nTrạng thái: ${b['status']}'),
              ),
            );
          },
        );
      },
    );
  }
}
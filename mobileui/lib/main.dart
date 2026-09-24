import 'dart:io'; // 1. Thêm import này ở đầu file
import 'package:flutter/material.dart';
import 'screens/main_screen.dart';

// 2. Tạo Class bỏ qua kiểm tra chứng chỉ SSL
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  // 3. Kích hoạt bỏ qua SSL trước khi chạy ứng dụng
  HttpOverrides.global = MyHttpOverrides();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý Phòng Trọ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const MainScreen(),
    );
  }
}
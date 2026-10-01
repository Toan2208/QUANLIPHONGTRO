import 'package:flutter/material.dart';
// Nếu MainNavigatorScreen hoặc LoginScreen của bạn nằm ở file main_screen.dart, hãy đảm bảo import đúng:
// import 'screens/main_screen.dart'; 
import 'screens/login_screen.dart'; // Bắt đầu từ màn hình đăng nhập hoặc main_screen tùy logic của bạn

void main() {
  runApp(const QuanLyPhongTroApp());
}

class QuanLyPhongTroApp extends StatelessWidget {
  const QuanLyPhongTroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý Phòng Trọ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // Xanh dương hiện đại, chuyên nghiệp
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Màu nền sáng sủa, sạch sẽ (Slate 50)
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1E293B),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
      ),
      // Bạn có thể đổi điểm khởi đầu là LoginScreen hoặc MainScreen tùy ý
      home: const LoginScreen(), 
    );
  }
}
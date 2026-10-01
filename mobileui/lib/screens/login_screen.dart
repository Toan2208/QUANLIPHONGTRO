import 'package:flutter/material.dart';
import 'main_screen.dart'; // Màn hình chính của Chủ trọ
import 'customer_home_screen.dart'; // Màn hình chính của Khách hàng
import 'register_screen.dart'; // Màn hình đăng ký
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Mặc định chọn vai trò là Khách hàng
  String _selectedRole = 'Customer'; 
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.login(username, password);

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (response['success'] == true) {
        final String serverRole = response['vaiTro'] ?? _selectedRole;

        if (serverRole == 'Admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
          final int maKhach = response['maKhach'] ?? 0;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerHomeScreen(maKhach: maKhach),
            ),
          );
        }
      } else {
        _showSnackBar(response['message'] ?? 'Sai thông tin đăng nhập!', isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      _showSnackBar('Đăng nhập thất bại: $e', isError: true);
    }
  }

  // Hàm giả lập đăng nhập mạng xã hội (Google / Facebook)
  void _handleSocialLogin(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đang kết nối với tài khoản $provider...')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Nền sáng sủa, hiện đại
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo hoặc Biểu tượng ứng dụng
                Container(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      size: 64,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chào mừng trở lại!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Đăng nhập để quản lý phòng trọ thông minh',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 32),

                // Thẻ chứa form đăng nhập (Card nổi bật, sạch sẽ)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Chọn vai trò đăng nhập
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: InputDecoration(
                          labelText: 'Đăng nhập với tư cách',
                          labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                          prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF2563EB)),
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
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Customer', child: Text('Khách hàng (Người thuê trọ)')),
                          DropdownMenuItem(value: 'Admin', child: Text('Chủ trọ (Quản lý)')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Ô nhập Tên đăng nhập
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Tên đăng nhập',
                          labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                          prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF2563EB)),
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
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Ô nhập Mật khẩu
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2563EB)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: const Color(0xFF64748B),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
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
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Nút Đăng nhập
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Đăng nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Đường phân cách Hoặc đăng nhập bằng mạng xã hội
                Row(
                  children: [
                    const Expanded(child: Divider(color: Color(0xFFCBD5E1))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Hoặc tiếp tục với', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ),
                    const Expanded(child: Divider(color: Color(0xFFCBD5E1))),
                  ],
                ),
                const SizedBox(height: 20),

                // Nút Đăng nhập nhanh qua Google & Facebook
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          backgroundColor: Colors.white,
                        ),
                        onPressed: () => _handleSocialLogin('Google'),
                        icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
                        label: const Text('Google', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          backgroundColor: Colors.white,
                        ),
                        onPressed: () => _handleSocialLogin('Facebook'),
                        icon: const Icon(Icons.facebook, size: 20, color: Color(0xFF1877F2)),
                        label: const Text('Facebook', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Chuyển sang màn hình Đăng ký
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Chưa có tài khoản? ', style: TextStyle(color: Color(0xFF64748B))),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                    
                      child: const Text(
                        'Đăng ký ngay',
                        style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:chat_app/routes/app_navigator.dart';
import 'package:chat_app/service/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() {
    return _RegisterPageState();
  }
}

class _RegisterPageState extends State<RegisterPage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController1 = TextEditingController();
  final passwordController2 = TextEditingController();

  // Biến quản lý UI
  bool _isLoading = false;
  bool _isPassword1Visible = false;
  bool _isPassword2Visible = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> register() async {
    // Validate UI trước
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Logic kiểm tra mật khẩu khớp nhau (giữ nguyên logic của bạn nhưng đưa vào try block)
      if (passwordController1.text != passwordController2.text) {
        throw Exception("Mật khẩu xác nhận không khớp!");
      }

      final dio = ApiClient.instance.dio;
      dio.options.headers["Content-Type"] = "application/json";

      final response = await dio.post(
        "/users/register",
        data: {
          "username": usernameController.text.trim(),
          "email": emailController.text.trim(),
          "password": passwordController1.text,
        },
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đăng ký thành công! Vui lòng đăng nhập."),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        AppNavigator.goToLogin(context);
      }
    } catch (err) {
      if (!mounted) return;
      String message = "Đã xảy ra lỗi";

      if (err is DioException) {
        // Xử lý lỗi từ server (thường server trả về message trong response)
        if (err.response != null && err.response!.statusCode == 409) {
          message = "Email này đã được sử dụng!";
        } else {
          message = "Lỗi kết nối hoặc server";
        }
      } else if (err is Exception) {
        // Lỗi logic client (ví dụ password không khớp)
        // Xoá chữ "Exception: " ở đầu chuỗi để thông báo đẹp hơn
        message = err.toString().replaceAll("Exception: ", "");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Mở rộng body ra toàn màn hình đè lên cả status bar
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // AppBar trong suốt
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => AppNavigator.goToLogin(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6A11CB),
              Color(0xFF2575FC),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // --- Header ---
                  const Text(
                    "Tạo tài khoản",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tham gia cộng đồng Z-Chat ngay",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- Form Card ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Username Field
                          _buildTextField(
                            controller: usernameController,
                            label: "Tên người dùng",
                            icon: Icons.person_outline,
                            validator: (val) => (val == null || val.isEmpty)
                                ? "Vui lòng nhập tên"
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Email Field
                          _buildTextField(
                            controller: emailController,
                            label: "Email",
                            icon: Icons.email_outlined,
                            inputType: TextInputType.emailAddress,
                            validator: (val) =>
                                (val == null || !val.contains("@"))
                                    ? "Email không hợp lệ"
                                    : null,
                          ),
                          const SizedBox(height: 16),

                          // Password 1 Field
                          _buildPasswordField(
                            controller: passwordController1,
                            label: "Mật khẩu",
                            isVisible: _isPassword1Visible,
                            onVisibilityChanged: () => setState(() =>
                                _isPassword1Visible = !_isPassword1Visible),
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return "Nhập mật khẩu";
                              if (val.length < 6)
                                return "Mật khẩu phải >= 6 ký tự";
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password 2 Field
                          _buildPasswordField(
                            controller: passwordController2,
                            label: "Nhập lại mật khẩu",
                            isVisible: _isPassword2Visible,
                            onVisibilityChanged: () => setState(() =>
                                _isPassword2Visible = !_isPassword2Visible),
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return "Xác nhận mật khẩu";
                              if (val != passwordController1.text)
                                return "Mật khẩu không khớp";
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2575FC),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Đăng ký",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- Footer Login Link ---
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Đã có tài khoản? ",
                        style: TextStyle(color: Colors.white70),
                      ),
                      GestureDetector(
                        onTap: () => AppNavigator.goToLogin(context),
                        child: const Text(
                          "Đăng nhập",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget tách riêng cho TextField thường để code gọn hơn
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // Widget tách riêng cho Password Field
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onVisibilityChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: onVisibilityChanged,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

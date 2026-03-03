// ไฟล์: lib/pages/signup_screen.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>(); 
  
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // เพิ่ม Controller สำหรับ Confirm Password
  
  final AuthService _auth = AuthService();
  bool _isLoading = false;

  void _showAlert(String title, String message, {bool isSuccess = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: TextStyle(color: isSuccess ? Colors.green : Colors.red)),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); 
              if (isSuccess) {
                Navigator.pushReplacementNamed(context, '/trip-list-screen');
              }
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _handleSignup() async {
    // โค้ดจะทำงานต่อเมื่อข้อมูลผ่าน Validation ทั้งหมด (ไม่มีตัวหนังสือแดงขึ้นเตือน)
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? errorMessage = await _auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (errorMessage == null) {
        _showAlert('สำเร็จ', 'สมัครสมาชิกเรียบร้อยแล้ว', isSuccess: true);
      } else {
        _showAlert('เกิดข้อผิดพลาด', errorMessage);
      }
    }
  }

  // ฟังก์ชันตรวจสอบความปลอดภัยของรหัสผ่าน
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'กรุณากรอกรหัสผ่าน';
    if (value.length < 8) return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
    
    // ใช้ Regular Expression เช็คว่าต้องมีทั้งตัวอักษรภาษาอังกฤษและตัวเลข
    bool hasLetterAndNumber = RegExp(r'(?=.*[a-zA-Z])(?=.*[0-9])').hasMatch(value);
    if (!hasLetterAndNumber) {
      return 'รหัสผ่านต้องประกอบด้วยตัวอักษรและตัวเลข';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent, iconTheme: const IconThemeData(color: Colors.black)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                
                Row(
                  children: [
                    Expanded(child: _buildInput(_firstNameController, 'First Name')),
                    const SizedBox(width: 15),
                    Expanded(child: _buildInput(_lastNameController, 'Last Name')),
                  ],
                ),
                const SizedBox(height: 15),
                
                _buildInput(_phoneController, 'Phone Number', isPhone: true),
                const SizedBox(height: 15),
                
                _buildInput(_emailController, 'Email', isEmail: true),
                const SizedBox(height: 15),
                
                // ช่องรหัสผ่าน (ส่งฟังก์ชัน _validatePassword เข้าไปเช็ค)
                _buildInput(
                  _passwordController, 
                  'Password', 
                  isObscure: true,
                  customValidator: _validatePassword,
                ),
                const SizedBox(height: 15),

                // ช่องยืนยันรหัสผ่าน
                _buildInput(
                  _confirmPasswordController, 
                  'Confirm Password', 
                  isObscure: true,
                  customValidator: (value) {
                    if (value == null || value.isEmpty) return 'กรุณายืนยันรหัสผ่าน';
                    if (value != _passwordController.text) return 'รหัสผ่านไม่ตรงกัน'; // เช็คว่าตรงกับช่องด้านบนไหม
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B71FE), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('Sign Up', style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ปรับปรุง _buildInput ให้รับ customValidator ได้
  Widget _buildInput(
    TextEditingController controller, 
    String hint, 
    {bool isObscure = false, bool isPhone = false, bool isEmail = false, String? Function(String?)? customValidator}
  ) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: isPhone ? TextInputType.phone : (isEmail ? TextInputType.emailAddress : TextInputType.text),
      validator: customValidator ?? (value) {
        // Validation พื้นฐานสำหรับช่องที่ไม่ได้ส่ง customValidator มา
        if (value == null || value.trim().isEmpty) return 'กรุณากรอก $hint';
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        // ทำให้ช่อง Error สีแดงดูเนียนตาขึ้น
        errorStyle: const TextStyle(color: Colors.red),
      ),
    );
  }
}
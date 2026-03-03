import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 80.0),
          child: Column(
            children: [
              const Text('My Trips', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              const SizedBox(height: 40),
              Icon(Icons.public, size: 100, color: Colors.blue.shade200),
              const SizedBox(height: 40),
              _buildInput(_emailController, 'Email', Icons.email_outlined),
              const SizedBox(height: 15),
              _buildInput(_passwordController, 'Password', Icons.lock_outline, isObscure: true),
              const SizedBox(height: 25),
              _buildButton('Log In', const Color(0xFF3B71FE), Colors.white, () async {
                final user = await _auth.signIn(_emailController.text, _passwordController.text);
                if (user != null) Navigator.pushReplacementNamed(context, '/trip-list-screen');
              }),
              TextButton(onPressed: () {}, child: const Text('Forgot Password?', style: TextStyle(color: Colors.grey))),
              const SizedBox(height: 20),
              _buildGoogleButton(),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/signup'),
                    child: const Text('Sign Up', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, IconData icon, {bool isObscure = false}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildButton(String label, Color bg, Color text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: bg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        child: Text(label, style: TextStyle(color: text, fontSize: 18)),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton.icon(
        onPressed: () {}, // เชื่อมต่อ Google Sign In ที่นี่
        icon: const Icon(Icons.g_mobiledata, size: 30, color: Colors.red),
        label: const Text('Continue with Google', style: TextStyle(color: Colors.black, fontSize: 16)),
        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      ),
    );
  }
}
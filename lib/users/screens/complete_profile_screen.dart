import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../trips/services/database_service.dart';

class CompleteProfileScreen extends StatefulWidget {
  final User user; // รับข้อมูล User ที่ได้จาก Google
  const CompleteProfileScreen({super.key, required this.user});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  final DatabaseService _dbService = DatabaseService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // พยายามแยกชื่อ-นามสกุล ที่ Google ส่งมาให้ (ถ้ามี)
    List<String> nameParts = (widget.user.displayName ?? '').split(' ');
    if (nameParts.isNotEmpty) {
      _firstNameController.text = nameParts[0];
      if (nameParts.length > 1) {
        _lastNameController.text = nameParts.sublist(1).join(' ');
      }
    }
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // เช็คเบอร์ซ้ำ
      bool isDuplicate = await _dbService.checkPhoneDuplicate(_phoneController.text);
      if (isDuplicate) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เบอร์โทรนี้ถูกใช้งานแล้ว')));
        return;
      }

      // บันทึกข้อมูลลง Database
      await _dbService.saveUser(
        uid: widget.user.uid,
        email: widget.user.email ?? '',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      // ถ้า Google มีรูปโปรไฟล์มาให้ ก็อัปเดต URL ไปเลย (แถม)
      if (widget.user.photoURL != null) {
        await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
          'photoUrl': widget.user.photoURL // เก็บ URL ของ Google ไว้ใช้ได้เลย
        });
      }

      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(context, '/trip-list-screen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Profile'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('เกือบเสร็จแล้ว!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('กรุณากรอกข้อมูลเพิ่มเติมเพื่อตั้งค่าโปรไฟล์ของคุณ'),
              const SizedBox(height: 30),

              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(labelText: 'First Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                validator: (val) => val!.isEmpty ? 'กรุณากรอกชื่อ' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: 'Last Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                validator: (val) => val!.isEmpty ? 'กรุณากรอกนามสกุล' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                validator: (val) => val!.isEmpty ? 'กรุณากรอกเบอร์โทร' : null,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('ยืนยันข้อมูล'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

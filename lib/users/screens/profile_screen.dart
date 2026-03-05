import 'dart:io';
import 'dart:convert'; // เพิ่มตัวนี้
import 'dart:typed_data'; // เพิ่มตัวนี้สำหรับ Uint8List
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../trips/services/database_service.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  
  String? _photoBase64; // เปลี่ยนจาก _photoUrl เป็น _photoBase64
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (currentUser != null) {
      final userData = await _dbService.getUserProfile(currentUser!.uid);
      if (userData != null) {
        setState(() {
          _firstNameController.text = userData['firstName'] ?? '';
          _lastNameController.text = userData['lastName'] ?? '';
          _photoBase64 = userData['photoBase64']; // ดึง String รูปมา
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAndSaveImage() async {
    final ImagePicker picker = ImagePicker();
    // สำคัญ: ต้องบีบอัดรูปหนักๆ เพื่อไม่ให้เกิน 1MB ของ Firestore
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 30, // ลดคุณภาพเหลือ 30%
      maxWidth: 400, // บังคับย่อขนาดความกว้าง
      maxHeight: 400, // บังคับย่อขนาดความสูง
    );

    if (image != null && currentUser != null) {
      setState(() => _isLoading = true);
      
      File imageFile = File(image.path);
      
      // อัปเดตลง Database ทันที
      await _dbService.uploadProfileImageBase64(currentUser!.uid, imageFile);
      
      // แปลงรูปมาโชว์ที่หน้าจอทันทีโดยไม่ต้องดึงใหม่
      final bytes = await imageFile.readAsBytes();
      setState(() {
        _photoBase64 = base64Encode(bytes);
        _isLoading = false;
      });
      
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เปลี่ยนรูปโปรไฟล์สำเร็จ')));
    }
  }

  Future<void> _saveProfile() async {
    if (currentUser != null) {
      setState(() => _isSaving = true);
      await _dbService.updateProfile(
        currentUser!.uid, 
        _firstNameController.text.trim(), 
        _lastNameController.text.trim()
      );
      setState(() => _isSaving = false);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')));
    }
  }

  // ฟังก์ชันช่วยแปลง String กลับเป็นรูปภาพ
  ImageProvider? _getProfileImage() {
    if (_photoBase64 != null && _photoBase64!.isNotEmpty) {
      try {
        Uint8List imageBytes = base64Decode(_photoBase64!);
        return MemoryImage(imageBytes);
      } catch (e) {
        return null; // ถ้าโค้ดพังให้คืนค่า null
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await _authService.signOut();
              if(mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _getProfileImage(), // เรียกใช้ฟังก์ชันดึงรูป
                      child: _photoBase64 == null 
                          ? const Icon(Icons.person, size: 60, color: Colors.grey)
                          : null,
                    ),
                    GestureDetector(
                      onTap: _pickAndSaveImage, // เรียกฟังก์ชันเลือกรูป
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(currentUser?.email ?? '', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),

                TextField(
                  controller: _firstNameController,
                  decoration: InputDecoration(labelText: 'First Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                ),
                const SizedBox(height: 20),
                
                TextField(
                  controller: _lastNameController,
                  decoration: InputDecoration(labelText: 'Last Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: CustomBottomBar.getIndexFromRoute('/profile-screen'),
        onTap: (index) => CustomBottomBar.navigateToIndex(context, index),
      ),
    );
  }
}

// ไฟล์: lib/widgets/custom_bottom_bar.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Custom bottom navigation bar for TripPulse application
class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final BottomBarVariant variant;
  final bool showLabels;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double elevation;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.variant = BottomBarVariant.material3,
    this.showLabels = true,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case BottomBarVariant.material3:
        return _buildMaterial3NavigationBar(context);
      case BottomBarVariant.classic:
        return _buildClassicBottomNavigationBar(context);
      case BottomBarVariant.floating:
        return _buildFloatingNavigationBar(context);
    }
  }

  // ----------------------------------------------------------------
  // ฟังก์ชันใหม่: ดึงรูปโปรไฟล์แบบ Base64 มาทำเป็น Icon
  // ----------------------------------------------------------------
  Widget _buildProfileIcon(BuildContext context, {required bool isSelected}) {
    final user = FirebaseAuth.instance.currentUser;
    
    // ถ้ายังไม่ได้ Login ให้ใช้ Icon ธรรมดา
    if (user == null) {
      return Icon(isSelected ? Icons.person : Icons.person_outline);
    }

    // ใช้ StreamBuilder เพื่อให้รูปเปลี่ยนทันทีที่มีการอัปเดตใน Database
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final base64String = data?['photoBase64'] as String?;
          
          if (base64String != null && base64String.isNotEmpty) {
            try {
              Uint8List imageBytes = base64Decode(base64String);
              return Container(
                width: 28, // ขนาดรูปโปรไฟล์ใน Nav Bar
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // ถ้าถูกเลือก (Active) ให้มีขอบสีวงกลมล้อมรอบ
                  border: isSelected 
                      ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) 
                      : null,
                  image: DecorationImage(
                    image: MemoryImage(imageBytes),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            } catch (e) {
              // ถ้าแปลงรูปพัง ให้หลุดไปโชว์ Icon ปกติด้านล่าง
            }
          }
        }
        // รูปเริ่มต้น (Fallback) ถ้ายังไม่มีรูป
        return Icon(isSelected ? Icons.person : Icons.person_outline);
      },
    );
  }

  Widget _buildMaterial3NavigationBar(BuildContext context) {
    final theme = Theme.of(context);

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: backgroundColor ?? theme.navigationBarTheme.backgroundColor,
      elevation: elevation,
      height: 80,
      labelBehavior: showLabels
          ? NavigationDestinationLabelBehavior.alwaysShow
          : NavigationDestinationLabelBehavior.alwaysHide,
      destinations: _buildNavigationDestinations(context),
    );
  }

  Widget _buildClassicBottomNavigationBar(BuildContext context) {
    final theme = Theme.of(context);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: backgroundColor ?? theme.bottomNavigationBarTheme.backgroundColor,
      selectedItemColor: selectedItemColor ?? theme.bottomNavigationBarTheme.selectedItemColor,
      unselectedItemColor: unselectedItemColor ?? theme.bottomNavigationBarTheme.unselectedItemColor,
      type: BottomNavigationBarType.fixed,
      elevation: elevation,
      showSelectedLabels: showLabels,
      showUnselectedLabels: showLabels,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: _buildBottomNavigationBarItems(context),
    );
  }

  Widget _buildFloatingNavigationBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          height: 72,
          labelBehavior: showLabels
              ? NavigationDestinationLabelBehavior.alwaysShow
              : NavigationDestinationLabelBehavior.alwaysHide,
          destinations: _buildNavigationDestinations(context),
        ),
      ),
    );
  }

  List<NavigationDestination> _buildNavigationDestinations(BuildContext context) {
    return [
      const NavigationDestination(
        icon: Icon(Icons.explore_outlined),
        selectedIcon: Icon(Icons.explore),
        label: 'Trips',
        tooltip: 'View all trips',
      ),
      const NavigationDestination(
        icon: Icon(Icons.search_outlined),
        selectedIcon: Icon(Icons.search),
        label: 'Search',
        tooltip: 'Search places',
      ),
      const NavigationDestination(
        icon: Icon(Icons.map_outlined),
        selectedIcon: Icon(Icons.map),
        label: 'Map',
        tooltip: 'View map',
      ),
      NavigationDestination(
        // เรียกใช้ฟังก์ชันรูปโปรไฟล์ตรงนี้
        icon: _buildProfileIcon(context, isSelected: false),
        selectedIcon: _buildProfileIcon(context, isSelected: true),
        label: 'Profile',
        tooltip: 'User profile',
      ),
    ];
  }

  List<BottomNavigationBarItem> _buildBottomNavigationBarItems(BuildContext context) {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.explore_outlined),
        activeIcon: Icon(Icons.explore),
        label: 'Trips',
        tooltip: 'View all trips',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.search_outlined),
        activeIcon: Icon(Icons.search),
        label: 'Search',
        tooltip: 'Search places',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.map_outlined),
        activeIcon: Icon(Icons.map),
        label: 'Map',
        tooltip: 'View map',
      ),
      BottomNavigationBarItem(
        // เรียกใช้ฟังก์ชันรูปโปรไฟล์ตรงนี้
        icon: _buildProfileIcon(context, isSelected: false),
        activeIcon: _buildProfileIcon(context, isSelected: true),
        label: 'Profile',
        tooltip: 'User profile',
      ),
    ];
  }

  static void navigateToIndex(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/trip-list-screen');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/places-search-screen');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/general-map-screen');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile-screen');
        break;
    }
  }

  static int getIndexFromRoute(String? routeName) {
    switch (routeName) {
      case '/trip-list-screen':
        return 0;
      case '/places-search-screen':
        return 1;
      case '/general-map-screen':
        return 2;
      case '/profile-screen':
        return 3;
      case '/trip-detail-screen':
      case '/day-itinerary-screen':
        return 0;
      default:
        return 0;
    }
  }
}

enum BottomBarVariant {
  material3,
  classic,
  floating,
}
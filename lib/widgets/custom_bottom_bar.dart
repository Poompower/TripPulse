import 'package:flutter/material.dart';

/// Custom bottom navigation bar for TripPulse application
/// Implements thumb-reachable navigation with Material 3 design
/// Supports primary navigation between core screens
class CustomBottomBar extends StatelessWidget {
  /// Current selected index
  final int currentIndex;

  /// Callback when navigation item is tapped
  final ValueChanged<int> onTap;

  /// Navigation bar variant
  final BottomBarVariant variant;

  /// Whether to show labels
  final bool showLabels;

  /// Custom background color (optional, uses theme if null)
  final Color? backgroundColor;

  /// Custom selected item color (optional, uses theme if null)
  final Color? selectedItemColor;

  /// Custom unselected item color (optional, uses theme if null)
  final Color? unselectedItemColor;

  /// Elevation of the bottom bar
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

  /// Builds Material 3 NavigationBar with indicator
  Widget _buildMaterial3NavigationBar(BuildContext context) {
    final theme = Theme.of(context);

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor:
          backgroundColor ?? theme.navigationBarTheme.backgroundColor,
      elevation: elevation,
      height: 80,
      labelBehavior: showLabels
          ? NavigationDestinationLabelBehavior.alwaysShow
          : NavigationDestinationLabelBehavior.alwaysHide,
      destinations: _buildNavigationDestinations(context),
    );
  }

  /// Builds classic BottomNavigationBar
  Widget _buildClassicBottomNavigationBar(BuildContext context) {
    final theme = Theme.of(context);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor:
          backgroundColor ?? theme.bottomNavigationBarTheme.backgroundColor,
      selectedItemColor:
          selectedItemColor ?? theme.bottomNavigationBarTheme.selectedItemColor,
      unselectedItemColor:
          unselectedItemColor ??
          theme.bottomNavigationBarTheme.unselectedItemColor,
      type: BottomNavigationBarType.fixed,
      elevation: elevation,
      showSelectedLabels: showLabels,
      showUnselectedLabels: showLabels,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: _buildBottomNavigationBarItems(context),
    );
  }

  /// Builds floating navigation bar with rounded corners
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

  /// Builds navigation destinations for Material 3 NavigationBar
  List<NavigationDestination> _buildNavigationDestinations(
    BuildContext context,
  ) {
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
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profile',
        tooltip: 'User profile',
      ),
    ];
  }

  /// Builds items for classic BottomNavigationBar
  List<BottomNavigationBarItem> _buildBottomNavigationBarItems(
    BuildContext context,
  ) {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.explore_outlined),
        activeIcon: Icon(Icons.explore),
        label: 'Trips',
        tooltip: 'View all trips',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.search_outlined),
        activeIcon: Icon(Icons.search),
        label: 'Search',
        tooltip: 'Search places',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.map_outlined),
        activeIcon: Icon(Icons.map),
        label: 'Map',
        tooltip: 'View map',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
        tooltip: 'User profile',
      ),
    ];
  }

  /// Helper method to navigate to the appropriate screen based on index
  static void navigateToIndex(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/trip-list-screen');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/places-search-screen');
        break;
      case 2:
        // Map view - navigate to general map screen
        Navigator.pushReplacementNamed(context, '/general-map-screen');
        break;
      case 3:
        // Profile/Settings - would need to be implemented
        // For now, navigate to trip list
        Navigator.pushReplacementNamed(context, '/trip-list-screen');
        break;
    }
  }

  /// Helper method to get current index based on route
  static int getIndexFromRoute(String? routeName) {
    switch (routeName) {
      case '/trip-list-screen':
        return 0;
      case '/places-search-screen':
        return 1;
      case '/general-map-screen':
        return 2;
      case '/trip-detail-screen':
      case '/day-itinerary-screen':
        return 0; // Keep trips selected when viewing trip details
      default:
        return 0;
    }
  }
}

/// Enum defining bottom bar variants
enum BottomBarVariant {
  /// Material 3 NavigationBar with indicator
  material3,

  /// Classic BottomNavigationBar
  classic,

  /// Floating navigation bar with rounded corners
  floating,
}

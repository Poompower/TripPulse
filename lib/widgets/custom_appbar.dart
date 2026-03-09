import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// CustomAppBar
/// - UI only
/// - Used for "Search place" header
/// - Does NOT handle controller, filter, or API logic
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar.searchPlace({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      automaticallyImplyLeading: true,
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      systemOverlayStyle: theme.brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      title: const _SearchPlaceBar(),
      centerTitle: false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// ===============================
/// Search Place Bar (UI ONLY)
/// ===============================
/// This widget is intentionally non-interactive.
/// Screen layer should handle actual search logic.
class _SearchPlaceBar extends StatelessWidget {
  const _SearchPlaceBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Search place (e.g. Tokyo, Japan)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

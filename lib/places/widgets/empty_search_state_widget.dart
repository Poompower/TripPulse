import 'package:flutter/material.dart';

// Empty UI state shown before or without meaningful search results.
class EmptySearchStateWidget extends StatelessWidget {
  const EmptySearchStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.travel_explore, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Search for attractions or places',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Try searching by city, landmark, or category',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

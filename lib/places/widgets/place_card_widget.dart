import 'package:flutter/material.dart';

import '../models/place.dart';
import '../services/wikimedia_image_service.dart';

class PlaceCardWidget extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const PlaceCardWidget({
    super.key,
    required this.place,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Image =====
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _PlaceImage(place: place),
              ),
              const SizedBox(width: 12),

              // ===== Content =====
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + Category badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _CategoryBadge(text: place.category),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Rating + Distance (mock rating for now)
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        const Text('4.8', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 12),
                        if (place.distanceKm != null) ...[
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${place.distanceKm!.toStringAsFixed(1)} km from center',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Description
                    Text(
                      place.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              // ===== Add Button =====
              const SizedBox(width: 8),
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceImage extends StatelessWidget {
  final Place place;

  const _PlaceImage({required this.place});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: WikimediaImageService.instance.resolveImageUrl(place),
      builder: (context, snapshot) {
        final imageUrl = snapshot.data;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return Image.network(
            imageUrl,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _placeholder(),
          );
        }
        return _placeholder();
      },
    );
  }

  Widget _placeholder() {
    return Container(
      width: 64,
      height: 64,
      color: Colors.grey.shade200,
      child: const Icon(Icons.place, size: 32),
    );
  }
}

// ===== Category Badge =====
class _CategoryBadge extends StatelessWidget {
  final String text;

  const _CategoryBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.blue,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

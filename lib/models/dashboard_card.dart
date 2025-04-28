import 'package:flutter/material.dart';
import 'event.dart';

/// A little UI wrapper: given an [Event], it renders
/// a tappable card with the first image (or banner) + title.
class DashboardCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;

  const DashboardCard({
    Key? key,
    required this.event,
    this.onTap,
  }) : super(key: key);

  /// Convenience constructor: pass raw Firestore data + docId
  factory DashboardCard.fromMap(
    Map<String, dynamic> data,
    String id, {
    VoidCallback? onTap,
  }) {
    return DashboardCard(
      event: Event.fromMap(data, id),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Choose banner first, else any uploaded image, else placeholder
    final imageUrl = event.bannerUrl != null
        ? event.bannerUrl!
        : (event.imageUrls.isNotEmpty
            ? event.imageUrls.first
            : 'https://via.placeholder.com/300x200?text=No+Image');

    return InkWell(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
            // Dark overlay
            Positioned.fill(
              child: Container(color: Colors.black26),
            ),
            // Title & date
            Positioned(
              left: 8,
              bottom: 8,
              right: 8,
              child: Text(
                event.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
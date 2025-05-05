import 'package:flutter/material.dart';
import 'event.dart';

/// A UI card for an [Event], with tap, edit, hide, and robust image fetching.
class DashboardCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onHide;

  const DashboardCard({
    Key? key,
    required this.event,
    this.onTap,
    this.onEdit,
    this.onHide,
  }) : super(key: key);

  factory DashboardCard.fromMap(
    Map<String, dynamic> data,
    String id, {
    VoidCallback? onTap,
    VoidCallback? onEdit,
    VoidCallback? onHide,
  }) {
    return DashboardCard(
      event: Event.fromMap(data, id),
      onTap: onTap,
      onEdit: onEdit,
      onHide: onHide,
    );
  }

  String formatDriveUrl(String url) {
    url = url.trim();
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('drive.google.com') && uri.pathSegments.contains('d')) {
        final fileId = uri.pathSegments[uri.pathSegments.indexOf('d') + 1];
        return 'https://drive.google.com/uc?id=$fileId';
      }
    } catch (_) {}
    return url;
  }

  static const List<String> _fallbackUrls = [
    'https://hips.hearstapps.com/hmg-prod/images/ginger-maine-coon-kitten-running-on-lawn-in-royalty-free-image-1719608142.jpg',
    'https://images.unsplash.com/photo-1495360010541-f48722b34f7d?fm=jpg',
    'https://images.pexels.com/photos/57416/cat-sweet-kitty-animals-57416.jpeg?cs=srgb&dl=pexels-pixabay-57416.jpg&fm=jpg',
    'https://images.pexels.com/photos/45201/kitty-cat-kitten-pet-45201.jpeg',
    'https://t4.ftcdn.net/jpg/02/66/72/41/360_F_266724172_Iy8gdKgMa7XmrhYYxLCxyhx6J7070Pr8.jpg',
  ];
  static int _errorIndex = 0;

  Widget _buildNetworkImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (ctx, error, stack) {
        final fallback = _fallbackUrls[_errorIndex % _fallbackUrls.length];
        _errorIndex++;
        return Image.network(
          fallback,
          fit: BoxFit.cover,
          loadingBuilder: (ctx2, child2, progress2) {
            if (progress2 == null) return child2;
            return Center(
              child: CircularProgressIndicator(),
            );
          },
          errorBuilder: (ctx3, err3, stack3) => const Center(
            child: Icon(Icons.broken_image, size: 48, color: Colors.white70),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawUrl = event.bannerUrl?.trim().isNotEmpty == true
        ? event.bannerUrl!
        : event.imageUrls.isNotEmpty
            ? event.imageUrls.first
            : 'https://via.placeholder.com/300x200?text=No+Image';
    final imageUrl = formatDriveUrl(rawUrl);

    return InkWell(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            Positioned.fill(
              child: _buildNetworkImage(imageUrl),
            ),
            Positioned.fill(child: Container(color: Colors.black26)),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
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
            Positioned(
              top: 4,
              right: 4,
              child: PopupMenuButton<String>(
                onSelected: (choice) {
                  if (choice == 'view') {
                    onTap?.call();
                  } else if (choice == 'edit') {
                    onEdit?.call();
                  } else if (choice == 'hide') {
                    onHide?.call();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'view', child: Text('View')),
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'hide', child: Text('Hide')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'organization.dart';
class OrgCard extends StatelessWidget {
  final Organization org;
  final VoidCallback? onTap;

  const OrgCard({
    Key? key,
    required this.org,
    this.onTap,
  }) : super(key: key);


  factory OrgCard.fromMap(
    Map<String, dynamic> data,
    String id, {
    VoidCallback? onTap,
  }) {
    return OrgCard(
      org: Organization.fromMap(data, id),
      onTap: onTap,
    );
  }

  String _resolveDriveUrl(String raw) {
    if (!raw.startsWith('http')) {
      return 'https://drive.google.com/uc?export=view&id=$raw';
    }
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.host.contains('drive.google.com')) {
      final id = uri.queryParameters['id'];
      if (id != null && id.isNotEmpty) {
        return Uri.https(
          'drive.google.com',
          '/uc',
          {'export': 'view', 'id': id},
        ).toString();
      }
    }
    return raw;
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
      width: double.infinity,
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
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (ctx2, child2, progress2) {
            if (progress2 == null) return child2;
            return Center(child: CircularProgressIndicator());
          },
          errorBuilder: (ctx3, err3, stack3) => const Center(
            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawUrl = org.bannerUrl?.trim().isNotEmpty == true
        ? org.bannerUrl!
        : 'https://via.placeholder.com/300x150?text=No+Banner';
    final imageUrl = _resolveDriveUrl(rawUrl);

    return InkWell(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Expanded(
              child: _buildNetworkImage(imageUrl),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                org.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
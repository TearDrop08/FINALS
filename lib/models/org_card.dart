import 'package:flutter/material.dart';
import 'organization.dart';

/// A UI widget that turns an [Organization] into a tappable Card.
class OrgCard extends StatelessWidget {
  final Organization org;
  final VoidCallback? onTap;

  const OrgCard({
    Key? key,
    required this.org,
    this.onTap,
  }) : super(key: key);

  /// Convenience ctor: raw map + docId → Organization → Card
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

  @override
  Widget build(BuildContext context) {
    final imageUrl = org.bannerUrl ??
        'https://via.placeholder.com/300x150?text=No+Banner';

    return InkWell(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Expanded(
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
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
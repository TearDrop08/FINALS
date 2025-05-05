import 'package:cloud_firestore/cloud_firestore.dart';
class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String type;
  final List<String> tags;
  final String organizationId;
  final List<String> imageUrls;
  final String? bannerUrl;
  final DateTime createdAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.type,
    required this.tags,
    required this.organizationId,
    required this.imageUrls,
    this.bannerUrl,
    required this.createdAt,
  });

  factory Event.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic raw) {
      if (raw is Timestamp) {
        return raw.toDate();
      }
      if (raw is String) {
        try {
          return DateTime.parse(raw);
        } catch (_) {}
      }
      return DateTime.now();
    }

    List<String> parseTags(String? raw) {
      if (raw == null || raw.trim().isEmpty) return [];
      return raw.split(',').map((t) => t.trim()).toList();
    }

    final rawOrg = data['orguid'];
    String orgId;
    if (rawOrg is DocumentReference) {
      orgId = rawOrg.id;
    } else if (rawOrg is String) {
      final parts = rawOrg.split('/');
      orgId = parts.isNotEmpty ? parts.last : rawOrg;
    } else {
      orgId = '';
    }

    List<String> urls = [];
    if (data['imageUrls'] is List) {
      urls = List<String>.from(data['imageUrls'] as List);
    } else if (data['imageUrl'] is String) {
      urls = [data['imageUrl'] as String];
    }

    final rawCreated = data['createdAt'];
    final created =
        rawCreated is Timestamp ? rawCreated.toDate() : DateTime.now();

    return Event(
      id: id,
      title:          data['title']       as String? ?? '[No title]',
      description:    data['description'] as String? ?? '',
      location:       data['location']    as String? ?? '',
      startDate:      parseDate(data['datetimestart']),
      endDate:        parseDate(data['datetimeend']),
      status:         data['status']      as String? ?? '',
      type:           data['type']        as String? ?? '',
      tags:           parseTags(data['tags'] as String?),
      organizationId: orgId,
      bannerUrl:      data['banner']      as String?,
      imageUrls:      urls,
      createdAt:      created,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title':         title,
      'description':   description,
      'location':      location,
      'datetimestart': startDate.toIso8601String(),
      'datetimeend':   endDate.toIso8601String(),
      'status':        status,
      'type':          type,
      'tags':          tags.join(', '),
      'orguid':        '/organizations/$organizationId',
      if (bannerUrl != null) 'banner': bannerUrl!,
      'imageUrls':     imageUrls,
      'createdAt':     FieldValue.serverTimestamp(),
    };
  }
}
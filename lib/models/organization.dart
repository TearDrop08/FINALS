import 'package:cloud_firestore/cloud_firestore.dart';
class Organization {
  final String id;
  final String name;
  final String description;
  final String? bannerUrl;
  final DateTime createdAt;

  Organization({
    required this.id,
    required this.name,
    required this.description,
    this.bannerUrl,
    required this.createdAt,
  });

  factory Organization.fromMap(Map<String, dynamic> data, String id) {
    final ts = data['createdAt'];
    return Organization(
      id: id,
      name:        (data['name']        as String?) ?? '[No name]',
      description: (data['description'] as String?) ?? '',
      bannerUrl:   data['banner']      as String?,
      createdAt:   ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name':        name,
      'description': description,
      if (bannerUrl != null) 'banner': bannerUrl,
      'createdAt':   FieldValue.serverTimestamp(),
    };
  }
}
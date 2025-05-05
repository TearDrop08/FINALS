import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventJoinersScreen extends StatelessWidget {
  final String eventId;

  const EventJoinersScreen({
    Key? key,
    required this.eventId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Joiners'),
        backgroundColor: const Color(0xFF2E318F),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .collection('joiners')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: \${snapshot.error}'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text('No joiners yet.'),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final name = data['name'] as String? ?? 'Unknown User';
              final ts = data['joinedAt'];
              String subtitle = '';
              if (ts is Timestamp) {
                subtitle = ts.toDate().toString();
              }

              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(name),
                subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
              );
            },
          );
        },
      ),
    );
  }
}
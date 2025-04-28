import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;
  const EventDetailScreen({Key? key, required this.eventId}) : super(key: key);

  Future<Event> _fetchEvent() async {
    final snap = await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .get();
    final data = snap.data()!;
    return Event.fromMap(data, snap.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Event>(
      future: _fetchEvent(),
      builder: (ctx, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(backgroundColor: const Color(0xFF2E318F)),
            body: Center(child: Text('Error: ${snap.error}')),
          );
        }
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(backgroundColor: const Color(0xFF2E318F)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final evt = snap.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(evt.title),
            backgroundColor: const Color(0xFF2E318F),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image carousel
                SizedBox(
                  height: 250,
                  child: evt.imageUrls.isEmpty
                      ? const Center(child: Text('No images.'))
                      : PageView.builder(
                          itemCount: evt.imageUrls.length,
                          itemBuilder: (ctx, i) => Image.network(
                            evt.imageUrls[i],
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    evt.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Dates
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'From ${evt.startDate.toLocal().toIso8601String().split("T")[0]}'
                    ' to ${evt.endDate  .toLocal().toIso8601String().split("T")[0]}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(evt.description),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
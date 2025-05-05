import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'event_detail_screen.dart';
import 'event_form_screen.dart';
import 'organization_list_screen.dart';
import 'event_joiners_screen.dart';
import '../models/dashboard_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext ctx) async {
    Navigator.pushReplacement(
      ctx,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _hideEvent(String eventId) async {
    await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .update({'hidden': true});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0B0C69),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.business),
            tooltip: 'Organizations',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrganizationListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('events').snapshots(),
        builder: (ctx, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: \${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No events found.'));
          }
          return LayoutBuilder(
            builder: (ctx, constraints) {
              final width = constraints.maxWidth;
              final cols = width > 1000 ? 3 : (width > 600 ? 2 : 1);

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 4 / 3,
                ),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data();
                  final eventId = docs[i].id;
                  return _HoverableDashboardCard(
                    data: data,
                    eventId: eventId,
                    onView: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventJoinersScreen(eventId: eventId),
                        ),
                      );
                    },
                    onEdit: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventFormScreen(
                            eventId: eventId,
                            initialData: data,
                          ),
                        ),
                      );
                    },
                    onHide: () => _hideEvent(eventId),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventDetailScreen(eventId: eventId),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0B0C69),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EventFormScreen()),
          );
        },
      ),
    );
  }
}

class _HoverableDashboardCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String eventId;
  final VoidCallback onTap;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onHide;

  const _HoverableDashboardCard({
    Key? key,
    required this.data,
    required this.eventId,
    required this.onTap,
    required this.onView,
    required this.onEdit,
    required this.onHide,
  }) : super(key: key);

  @override
  __HoverableDashboardCardState createState() => __HoverableDashboardCardState();
}

class __HoverableDashboardCardState extends State<_HoverableDashboardCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Stack(
          children: [
            DashboardCard.fromMap(
              widget.data,
              widget.eventId,
              onTap: widget.onTap,
              onEdit: widget.onEdit,
              onHide: widget.onHide,
            ),
            AnimatedOpacity(
              opacity: _hovered ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: true,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    widget.data['description'] ?? '',
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: PopupMenuButton<String>(
                onSelected: (choice) {
                  if (choice == 'view') widget.onView();
                  else if (choice == 'edit') widget.onEdit();
                  else if (choice == 'hide') widget.onHide();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'view', child: Text('View Joiners')),
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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/org_card.dart';
import 'login_screen.dart';
import 'organization_form_screen.dart';

class OrganizationListScreen extends StatelessWidget {
  const OrganizationListScreen({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext ctx) async {
    Navigator.pushReplacement(
      ctx,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _hideOrganization(String orgId) async {
    await FirebaseFirestore.instance
        .collection('organizations')
        .doc(orgId)
        .update({'hidden': true});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Organizations',
          style: TextStyle(color: Colors.white), // Title text color set to white
        ),
        backgroundColor: const Color(0xFF0B0C69),
        iconTheme: const IconThemeData(color: Colors.white), // Leading icons white
        actionsIconTheme: const IconThemeData(color: Colors.white), // Action icons white
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('organizations')
            .snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No organizations found.'));
          }

          return LayoutBuilder(builder: (ctx, constraints) {
            final width = constraints.maxWidth;
            final crossCount = width > 1000
                ? 3
                : (width > 600 ? 2 : 1);

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 4 / 3,
              ),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final data = docs[i].data();
                final orgId = docs[i].id;

                return Stack(
                  children: [
                    OrgCard.fromMap(
                      data,
                      orgId,
                      onTap: () {
                      },
                    ),

                    Positioned(
                      top: 4,
                      right: 4,
                      child: PopupMenuButton<String>(
                        onSelected: (choice) {
                          if (choice == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrganizationFormScreen(
                                  orgId: orgId,
                                  initialData: data,
                                ),
                              ),
                            );
                          } else if (choice == 'hide') {
                            _hideOrganization(orgId);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'hide', child: Text('Hide')),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          });
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0B0C69),
        tooltip: 'Add Organization',
        child: const Icon(Icons.add_business, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const OrganizationFormScreen(),
            ),
          );
        },
      ),
    );
  }
}
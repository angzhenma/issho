// ignore_for_file: use_build_context_synchronously, unused_local_variable, unnecessary_brace_in_string_interps, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:issho/models/button.dart';
import 'package:issho/pages/community/chat.dart';
import 'package:issho/pages/community/create.dart';
import 'package:issho/pages/profile.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  final userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _query = _controller.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Search for users or communities',
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
        ),
      ),
      body: _query.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(
                      0.15,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.amber, width: 1.0),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: Colors.amber,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'All searches are case-sensitive! \nPlease use exact capitalization to find accurate matches.',
                          style: Theme.of(context).textTheme.bodySmall!
                              .copyWith(color: Colors.white),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Users', _searchUsers()),
                  _buildSection('Communities', _searchCommunities()),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String label, Stream<QuerySnapshot> stream) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const LinearProgressIndicator(),
            ],
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final docs = snapshot.data!.docs;

        if (label == 'Communities' && docs.isEmpty && _query.isNotEmpty) {
          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('communities').get(),
            builder: (context, existingActivitySnapshot) {
              if (existingActivitySnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const SizedBox();
              }

              final allCommunities = existingActivitySnapshot.data!.docs;

              final hasMatchingActivityType = allCommunities.any((doc) {
                final activityType = doc['activityType'] as String?;
                return activityType != null &&
                    activityType.toLowerCase() == _query.toLowerCase();
              });

              if (hasMatchingActivityType) {
                return const SizedBox();
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox();
                  }
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const SizedBox();
                  }
                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  final interests = (userData['interests'] ?? []) as List;

                  final lowerCaseInterests = interests
                      .map((i) => i.toString().toLowerCase())
                      .toList();

                  if (lowerCaseInterests.contains(_query.toLowerCase())) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seems like there are no communities for "$_query"!',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to create a community for this activity on Issho!',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.justify,
                          ),
                          const SizedBox(height: 12),
                          AppButton(
                            icon: Icons.add_circle_outline_rounded,
                            label: "Create Community",
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CreateCommunityPage(userId: userId),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox();
                },
              );
            },
          );
        }

        if (docs.isEmpty) {
          return const SizedBox();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...docs.map((doc) {
              String title;
              String subtitle;
              if (label == 'Users') {
                title = doc['displayName'] ?? 'Unnamed User';
                subtitle = doc['email'] ?? '';
              } else {
                title = doc['name'] ?? 'Unnamed Community';
                subtitle = doc['activityType'] ?? '';
              }

              return ListTile(
                title: Text(title),
                subtitle: Text(subtitle),
                onTap: () async {
                  if (label == 'Users') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(userId: doc.id),
                      ),
                    );
                  } else if (label == 'Communities') {
                    final List<dynamic> members = doc['members'] ?? [];
                    final joined = members.contains(userId);

                    if (!joined) {
                      final confirm =
                          await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('Join ${doc['name']}?'),
                              content: const Text(
                                'No sneak peeks! You need to join the community to view it.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Join'),
                                ),
                              ],
                            ),
                          ) ??
                          false;
                      if (!confirm) return;

                      await FirebaseFirestore.instance
                          .collection('communities')
                          .doc(doc.id)
                          .update({
                            'members': FieldValue.arrayUnion([userId]),
                          });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Joined ${doc['name']}!')),
                        );
                      }
                    }
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            communityId: doc.id,
                            communityName: doc['name'] ?? 'Community',
                            currentUserId: userId,
                          ),
                        ),
                      );
                    }
                  }
                },
              );
            }),
          ],
        );
      },
    );
  }

  Stream<QuerySnapshot> _searchUsers() {
    if (_query.isEmpty) return Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: _query)
        .where('displayName', isLessThanOrEqualTo: '${_query}\uf8ff')
        .snapshots();
  }

  Stream<QuerySnapshot> _searchCommunities() {
    if (_query.isEmpty) return Stream.empty();
    return FirebaseFirestore.instance
        .collection('communities')
        .where('name', isGreaterThanOrEqualTo: _query)
        .where('name', isLessThanOrEqualTo: '${_query}\uf8ff')
        .snapshots();
  }
}
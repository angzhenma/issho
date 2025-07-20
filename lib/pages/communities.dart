// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:issho/pages/community/search.dart';
import 'package:issho/widgets/community_card.dart';

// Programmer Name: Mr. Ibrahim Azaan Mauroof
// Program Name: issho_v2/lib/pages/communities.dart
// Program Description: Communities page of the Issho mobile application.
// First Written on: Monday, 16-June-2025
// Last Modified on: Saturday, 20-July-2025

class CommunitiesPage extends StatelessWidget {
  const CommunitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data;
        if (user == null) {
          return const Center(
            child: Text('Please log in to view communities.'),
          );
        }

        return _CommunitiesPageBody(user: user);
      },
    );
  }
}

class _CommunitiesPageBody extends StatefulWidget {
  final User user;
  const _CommunitiesPageBody({required this.user});

  @override
  State<_CommunitiesPageBody> createState() => _CommunitiesPageBodyState();
}

class _CommunitiesPageBodyState extends State<_CommunitiesPageBody> {
  String? _userState;
  String? _userCountry;
  bool _isLoadingUserLocation = true;

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userState = userDoc['state'] as String?;
          _userCountry = userDoc['country'] as String?;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching user location: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoadingUserLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUserLocation) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildSearchBar(context),
        Expanded(child: _buildCommunityList()),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SearchPage()),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: const [
            Icon(Icons.search_rounded),
            SizedBox(width: 8),
            Text("What are you looking for?"),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityList() {
    final uid = widget.user.uid;

    final joinedStream = FirebaseFirestore.instance
        .collection('communities')
        .where('members', arrayContains: uid)
        .snapshots();

    Stream<QuerySnapshot> recommendedStream;

    if (_userState != null && _userCountry != null) {
      recommendedStream = FirebaseFirestore.instance
          .collection('communities')
          .where('location.state', isEqualTo: _userState)
          .where('location.country', isEqualTo: _userCountry)
          .limit(10)
          .snapshots();
    } else {
      recommendedStream = Stream.empty();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: joinedStream,
      builder: (context, joinedSnap) {
        if (joinedSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final joinedCommunities = joinedSnap.data?.docs ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream: recommendedStream,
          builder: (context, recSnap) {
            if (recSnap.connectionState == ConnectionState.waiting) {
              if (joinedSnap.connectionState == ConnectionState.active && joinedSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return const Center(child: CircularProgressIndicator());
            }

            final recommendedCommunities = recSnap.data?.docs
                    .where((doc) => !joinedCommunities.any((joinedDoc) => joinedDoc.id == doc.id))
                    .toList() ??
                [];

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                _buildSection(
                  "Your Communities",
                  joinedCommunities,
                  true,
                  emptyMessage: "Join some communities and get active, buddy!",
                  showSectionHeadingIfEmpty: true,
                ),
                const SizedBox(height: 24),
                _buildSection(
                  "Communities Near You",
                  recommendedCommunities,
                  false,
                  emptyMessage: (_userState != null && _userCountry != null)
                      ? "It seems there are no communities on Issho in your area. You should create one!"
                      : "We couldn't find your location to recommend communities. Please check your profile.",
                  showEmptyMessageIfNoData: true,
                  showSectionHeadingIfEmpty: true,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSection(
    String title,
    List<QueryDocumentSnapshot> docs,
    bool isJoined, {
    String? emptyMessage,
    bool showEmptyMessageIfNoData = false,
    bool showSectionHeadingIfEmpty = false,
  }) {
    if (docs.isEmpty && !showSectionHeadingIfEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        if (docs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              emptyMessage ?? "No communities found.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        ...docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;

          final List<dynamic> admins = data['admins'] as List<dynamic>? ?? [];
          final bool isCommunityAdmin = admins.contains(widget.user.uid);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: CommunityCard(
              community: data,
              isJoined: isJoined,
              currentUserId: widget.user.uid,
              onJoin: () => _joinCommunity(doc.id, widget.user.uid),
              isCommunityAdmin: isCommunityAdmin,
            ),
          );
        }),
      ],
    );
  }

  Future<void> _joinCommunity(String id, String uid) async {
    try {
      await FirebaseFirestore.instance.collection('communities').doc(id).update({
        'members': FieldValue.arrayUnion([uid]),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined community!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join: ${e.toString()}')),
        );
      }
    }
  }
}
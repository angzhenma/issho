// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:issho/pages/community/events.dart';
import 'package:issho/pages/settings/edit_account.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> communities = [];
  List<Map<String, dynamic>> participatedEvents = [];
  bool isLoading = true;
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    if (!userDoc.exists) return;

    final user = userDoc.data()!;
    final allCommunities = await FirebaseFirestore.instance
        .collection('communities')
        .get();

    final userCommunities = allCommunities.docs
        .where((doc) {
          final members = List<String>.from(doc['members'] ?? []);
          return members.contains(widget.userId);
        })
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        })
        .toList();

    List<Map<String, dynamic>> userEvents = [];
    for (final community in allCommunities.docs) {
      final eventsSnapshot = await community.reference
          .collection('events')
          .get();
      for (final event in eventsSnapshot.docs) {
        final attendees = List<String>.from(event['attendees'] ?? []);
        if (attendees.contains(widget.userId)) {
          final data = event.data();
          data['id'] = event.id;
          data['communityId'] = community.id;
          data['communityName'] = community['name'];
          userEvents.add(data);
        }
      }
    }

    setState(() {
      userData = user;
      communities = userCommunities;
      participatedEvents = userEvents;
      isLoading = false;
    });
  }

  int? _calculateAge(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("User Profile"),
        leading: IconButton(
          icon: const Icon(Icons.navigate_before_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.userId == currentUserId)
            IconButton(
              icon: const Icon(Icons.edit_note_rounded),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditAccountPage()),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
          ? const Center(child: Text("User not found."))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [
                      Text(
                        '@${userData?['displayName'] ?? 'Unnamed'}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (userData!['dob'] != null)
                        Text(
                          '(${_calculateAge((userData!['dob'] as Timestamp).toDate())} years old)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if ((userData!['bio'] ?? '').toString().trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        userData!['bio'],
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  Row(
                    children: [
                      if (userData!['state'] != null &&
                          userData!['country'] != null)
                        Text('${userData!['state']}, ${userData!['country']}'),
                      const Spacer(),
                      if (userData!['createdAt'] != null)
                        Text(
                          'Joined ${DateFormat.yMMMd().format((userData!['createdAt'] as Timestamp).toDate())}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Interests
                  if ((userData!['interests'] as List).isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List<String>.from(
                        userData!['interests'],
                      ).map((interest) => Chip(label: Text(interest))).toList(),
                    ),
                  const SizedBox(height: 24),

                  // Communities section
                  Text("Communities", style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (communities.isEmpty)
                    Text(
                      "No communities joined yet.",
                      style: theme.textTheme.bodyMedium,
                    ),
                  ...communities.map((community) {
                    final isAdmin =
                        (community['admins'] as List?)?.contains(
                          widget.userId,
                        ) ??
                        false;
                    final isPro =
                        (community['pros'] as List?)?.contains(widget.userId) ??
                        false;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.groups_rounded),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(community['name'] ?? 'Unnamed'),
                            ),
                            if (isAdmin)
                              const Icon(
                                Icons.shield_rounded,
                                size: 18,
                                color: Colors.pinkAccent,
                              ),
                            if (isPro)
                              const Icon(
                                Icons.star_rounded,
                                size: 18,
                                color: Colors.deepPurpleAccent,
                              ),
                          ],
                        ),
                        subtitle: Text(community['activityType'] ?? ''),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),
                  Text("Events Joined", style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (participatedEvents.isEmpty)
                    Text(
                      "No events attended yet.",
                      style: theme.textTheme.bodyMedium,
                    ),
                  ...participatedEvents.map(
                    (event) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.event_rounded),
                        title: Text(event['title'] ?? 'Untitled'),
                        subtitle: Text(event['communityName'] ?? ''),
                        onTap: () => _handleEventTap(event),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _handleEventTap(Map<String, dynamic> event) async {
    final communityId = event['communityId'];
    final communityDoc = await FirebaseFirestore.instance
        .collection('communities')
        .doc(communityId)
        .get();

    final members = List<String>.from(communityDoc['members'] ?? []);
    final communityName = communityDoc['name'];

    if (!members.contains(currentUserId)) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Join $communityName?'),
          content: const Text(
            'No sneak peeks! You need to join this community to view event details.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await FirebaseFirestore.instance
                    .collection('communities')
                    .doc(communityId)
                    .update({
                      'members': FieldValue.arrayUnion([currentUserId]),
                    });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Joined $communityName!')),
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventPage(
                      communityId: communityId,
                      communityName: communityName,
                      currentUserId: currentUserId!,
                    ),
                  ),
                );
              },
              child: const Text('Join'),
            ),
          ],
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventPage(
            communityId: communityId,
            communityName: communityName,
            currentUserId: currentUserId!,
          ),
        ),
      );
    }
  }
}

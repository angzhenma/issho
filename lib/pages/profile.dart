import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> communities = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    if (!userDoc.exists) return;

    final user = userDoc.data()!;
    final allCommunities = await FirebaseFirestore.instance.collection('communities').get();

    final userCommunities = allCommunities.docs.where((doc) {
      final members = List<String>.from(doc['members'] ?? []);
      return members.contains(widget.userId);
    }).map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    setState(() {
      userData = user;
      communities = userCommunities;
      isLoading = false;
    });
  }

  int? _calculateAge(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
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
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
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
                      // Display name + age
                      Row(
                        children: [
                          Text(
                            userData!['displayName'] ?? 'Unnamed',
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                          if (userData!['dob'] != null)
                            Text(
                              '(${_calculateAge((userData!['dob'] as Timestamp).toDate())} yrs old)',
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Bio (if any)
                      if ((userData!['bio'] ?? '').toString().trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            userData!['bio'],
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),

                      // Interests
                      if ((userData!["interests"] as List).isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List<String>.from(userData!["interests"])
                              .map((interest) => Chip(label: Text(interest)))
                              .toList(),
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
                        final isAdmin = (community['admins'] as List?)?.contains(widget.userId) ?? false;
                        final isPro = (community['pros'] as List?)?.contains(widget.userId) ?? false;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const Icon(Icons.groups_rounded),
                            title: Row(
                              children: [
                                Expanded(child: Text(community['name'] ?? 'Unnamed')),
                                if (isAdmin)
                                  const Icon(Icons.shield_rounded, size: 18, color: Colors.amber),
                                if (isPro)
                                  const Icon(Icons.stars_rounded, size: 18, color: Colors.lightBlue),
                              ],
                            ),
                            subtitle: Text(community['activityType'] ?? ''),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }
}

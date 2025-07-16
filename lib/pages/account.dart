import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AccountPage extends StatefulWidget {
  final String userId;

  const AccountPage({super.key, required this.userId});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  late Future<DocumentSnapshot> userFuture;

  @override
  void initState() {
    super.initState();
    userFuture = FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
  }

  int _calculateAge(Timestamp dobTimestamp) {
    final dob = dobTimestamp.toDate();
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: userFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final userData = snapshot.data!.data() as Map<String, dynamic>;

        return Scaffold(
          appBar: AppBar(title: Text(userData['displayName'] ?? 'User')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(userData),
                const SizedBox(height: 20),
                _buildSectionTitle('Interests'),
                Wrap(
                  spacing: 8,
                  children: List<Chip>.from((userData['interests'] ?? []).map((i) => Chip(label: Text(i))))
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Communities'),
                _buildJoinedCommunities(userData),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    final dob = data['dob'] as Timestamp?;
    final age = dob != null ? _calculateAge(dob) : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(radius: 32, child: Icon(Icons.person, size: 32)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data['displayName'] ?? 'Unknown', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              if (data['bio'] != null) Text(data['bio'], style: Theme.of(context).textTheme.bodyMedium),
              if (age != null) Text('Age: $age', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }

  Widget _buildJoinedCommunities(Map<String, dynamic> data) {
    final joined = data['joinedCommunities'] ?? [];
    if (joined.isEmpty) return const Text('No communities joined yet.');
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('communities')
          .where(FieldPath.documentId, whereIn: joined)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final docs = snapshot.data!.docs;
        return Column(
          children: docs.map((doc) {
            final c = doc.data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.group),
              title: Text(c['name']),
              subtitle: Text(c['activityType']),
            );
          }).toList(),
        );
      },
    );
  }
}
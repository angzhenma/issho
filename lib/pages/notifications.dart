import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to see notifications.'));
    }

    final uid = user.uid;
    final notiRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: notiRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text('No notifications yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final type = data['type'] ?? 'general';
            final message = data['message'] ?? 'You have a new notification!';
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

            return _NotificationCard(
              type: type,
              message: message,
              time: timestamp != null
                  ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp)
                  : 'Just now',
            );
          },
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String type;
  final String message;
  final String time;

  const _NotificationCard({
    required this.type,
    required this.message,
    required this.time,
  });

  IconData _getIconForType() {
    switch (type) {
      case 'admin_assigned':
        return Icons.shield_rounded;
      case 'kicked':
        return Icons.logout_rounded;
      case 'event_joined':
        return Icons.event_available_rounded;
      case 'followed':
        return Icons.person_add_alt_1_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (type) {
      case 'admin_assigned':
        return scheme.primaryContainer;
      case 'kicked':
        return scheme.errorContainer;
      case 'event_joined':
        return scheme.secondaryContainer;
      case 'followed':
        return scheme.tertiaryContainer;
      default:
        return scheme.surfaceContainerHighest;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _getColorForType(context),
      child: ListTile(
        leading: Icon(_getIconForType(), size: 32),
        title: Text(message),
        subtitle: Text(time),
      ),
    );
  }
}
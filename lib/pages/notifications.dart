// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  Future<void> _markAllAsRead(String uid) async {
    final notificationsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications');

    final unreadNotifications = await notificationsRef
        .where('isRead', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in unreadNotifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

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

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final type = data['type'] ?? 'general';
              final message = data['message'] ?? 'You have a new notification!';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final isRead = (data['isRead'] as bool?) ?? false;

              return _NotificationCard(
                notificationId: doc.id,
                uid: uid,
                type: type,
                message: message,
                time: timestamp != null
                    ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp)
                    : 'Just now',
                isRead: isRead,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _markAllAsRead(uid),
        label: const Text('Mark All as Read'),
        icon: const Icon(Icons.check_box_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String notificationId;
  final String uid;
  final String type;
  final String message;
  final String time;
  final bool isRead;

  const _NotificationCard({
    required this.notificationId,
    required this.uid,
    required this.type,
    required this.message,
    required this.time,
    required this.isRead,
  });

  Future<void> _toggleReadStatus() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': !isRead});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textOpacity = isRead ? 0.5 : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: isRead ? theme.colorScheme.surfaceContainer.withOpacity(0.6) : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(textOpacity),
                      fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(textOpacity),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                isRead ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                color: isRead
                    ? theme.colorScheme.primary.withOpacity(textOpacity)
                    : theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
              onPressed: _toggleReadStatus,
              tooltip: isRead ? 'Mark as unread' : 'Mark as read',
            ),
          ],
        ),
      ),
    );
  }
}
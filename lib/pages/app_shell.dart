import 'package:flutter/material.dart';
import 'package:issho/pages/account.dart';
import 'package:issho/pages/communities.dart';
import 'package:issho/pages/community/event_calendar.dart';
import 'package:issho/pages/notifications.dart';
import 'package:issho/pages/profile.dart';
import 'package:issho/pages/settings.dart';
import 'package:issho/pages/community/create.dart';
import 'package:issho/widgets/bottom_nav_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  final List<String> _titles = const [
    'Communities',
    'Event Calendar',
    'Notifications',
    'Settings',
  ];

  List<Widget> get _pages {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return [
      const CommunitiesPage(),
      EventCalendarPage(userId: userId),
      // NotificationsPage will handle its own FAB for 'mark all as read'
      const NotificationsPage(),
      const SettingsPage(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _onFabPressed() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateCommunityPage(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: theme.textTheme.titleMedium,
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: _selectedIndex != 3
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfilePage(
                            userId: FirebaseAuth.instance.currentUser!.uid,
                          ),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: _pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0 // Only show FAB for Communities page currently
          ? FloatingActionButton(
              onPressed: _onFabPressed,
              tooltip: 'Create Community',
              child: const Icon(Icons.add_rounded),
            )
          : null, // FAB for notifications page will be handled internally
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: StreamBuilder<QuerySnapshot>(
        // Listen to notification changes to update icon
        stream: (userId != null)
            ? FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('notifications')
                .where('isRead', isEqualTo: false) // Only get unread
                .snapshots()
            : null, // If no user, no stream
        builder: (context, snapshot) {
          final hasUnreadNotifications = snapshot.hasData && (snapshot.data?.docs.isNotEmpty ?? false);
          return BottomNavBar(
            currentIndex: _selectedIndex,
            onTap: _onTabTapped,
            showFAB: _selectedIndex == 0,
            hasUnreadNotifications: hasUnreadNotifications,
          );
        },
      ),
    );
  }
}
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: theme.textTheme.titleMedium,
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(userId: FirebaseAuth.instance.currentUser!.uid),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.person_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _onFabPressed,
              tooltip: 'Create Community',
              child: const Icon(Icons.add_rounded),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        showFAB: _selectedIndex == 0,
      ),
    );
  }
}

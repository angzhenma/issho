import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditNotificationsPage extends StatefulWidget {
  const EditNotificationsPage({super.key});

  @override
  State<EditNotificationsPage> createState() => _EditNotificationsPageState();
}

class _EditNotificationsPageState extends State<EditNotificationsPage> {
  final _user = FirebaseAuth.instance.currentUser!;
  final Map<String, bool> _prefs = {
    'admin_role': true,
    'kicked_from_community': true,
    'event_joined': true,
    'new_follower': true,
  };

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('preferences')
        .doc('notifications')
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        for (var key in _prefs.keys) {
          _prefs[key] = data[key] ?? true;
        }
      });
    }

    setState(() => _loading = false);
  }

  Future<void> _updatePrefs() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('preferences')
        .doc('notifications')
        .set(_prefs);
  }

  Widget _buildSwitch(String key, String title, String subtitle) {
    return SwitchListTile(
      value: _prefs[key]!,
      title: Text(title),
      subtitle: Text(subtitle),
      onChanged: (val) {
        setState(() => _prefs[key] = val);
        _updatePrefs();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSwitch(
                  'admin_role',
                  'Admin Role Assignment',
                  'Get notified when you’re made admin of a community.',
                ),
                _buildSwitch(
                  'kicked_from_community',
                  'Kicked From Community',
                  'See when you’ve been removed from a community.',
                ),
                _buildSwitch(
                  'event_joined',
                  'Event Join Alert',
                  'Be notified when someone joins your event.',
                ),
                _buildSwitch(
                  'new_follower',
                  'New Follower',
                  'Know when someone follows your profile.',
                ),
              ],
            ),
    );
  }
}

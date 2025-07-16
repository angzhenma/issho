// ignore_for_file: unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditAccountPage extends StatefulWidget {
  const EditAccountPage({super.key});

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  DateTime? _dob;

  final _user = FirebaseAuth.instance.currentUser!;
  bool _isLoading = true;
  List<DocumentSnapshot> _joinedCommunities = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(_user.uid).get();
    final userData = userDoc.data()!;
    _displayNameController.text = userData['displayName'] ?? '';
    _bioController.text = userData['bio'] ?? '';
    _dob = userData['dob'] != null ? (userData['dob'] as Timestamp).toDate() : null;

    final communities = await FirebaseFirestore.instance
        .collection('communities')
        .where('members', arrayContains: _user.uid)
        .get();

    setState(() {
      _joinedCommunities = communities.docs;
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth.')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(_user.uid).update({
      'displayName': _displayNameController.text.trim(),
      'bio': _bioController.text.trim(),
      'dob': _dob,
    });

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated.')));
    }
  }

  Future<void> _attemptLeaveCommunity(DocumentSnapshot community) async {
    final data = community.data() as Map<String, dynamic>;
    final admins = List<String>.from(data['admins']);
    final members = List<String>.from(data['members']);
    final pros = List<String>.from(data['pros'] ?? []);
    final communityId = community.id;

    if (admins.length == 1 && admins.first == _user.uid) {
      _showDialog(
        title: 'Cannot Leave',
        content:
            'You are the only admin in this community. Please assign another admin before leaving.',
      );
      return;
    }

    if (members.length == 1 && members.first == _user.uid) {
      final confirm = await _showConfirmDialog(
        title: 'Delete Community?',
        content:
            'You are the only member in this community. Leaving will delete the community. Continue?',
      );
      if (confirm) {
        await FirebaseFirestore.instance
            .collection('communities')
            .doc(communityId)
            .delete();
        _loadUserInfo();
      }
      return;
    }

    await FirebaseFirestore.instance
        .collection('communities')
        .doc(communityId)
        .update({
      'members': FieldValue.arrayRemove([_user.uid]),
      'admins': FieldValue.arrayRemove([_user.uid]),
      'pros': FieldValue.arrayRemove([_user.uid]),
    });

    _loadUserInfo();
  }

  Future<void> _showDialog({required String title, required String content}) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDialog({required String title, required String content}) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
            ],
          ),
        ) ??
        false;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Account')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _displayNameController,
                          decoration: const InputDecoration(labelText: 'Display Name'),
                          validator: (val) =>
                              val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _bioController,
                          decoration: const InputDecoration(labelText: 'Bio'),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Date of Birth'),
                          subtitle: Text(
                            _dob == null
                                ? 'Tap to select'
                                : DateFormat.yMMMMd().format(_dob!),
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dob ?? DateTime(2000),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setState(() => _dob = picked);
                          },
                          trailing: const Icon(Icons.calendar_today_rounded),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_rounded),
                          label: const Text('Save Changes'),
                          onPressed: _saveProfile,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Joined Communities',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ..._joinedCommunities.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        title: Text(data['name']),
                        subtitle: Text(data['activityType']),
                        trailing: IconButton(
                          icon: const Icon(Icons.logout_rounded),
                          onPressed: () => _attemptLeaveCommunity(doc),
                        ),
                      ),
                    );
                  })
                ],
              ),
            ),
    );
  }
}

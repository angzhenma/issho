// ignore_for_file: unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:issho/models/button.dart';
import 'package:issho/models/text_field.dart';

class EditAccountPage extends StatefulWidget {
  const EditAccountPage({super.key});

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _interestsController = TextEditingController();
  DateTime? _selectedDob;

  List<String> _interests = [];
  final _user = FirebaseAuth.instance.currentUser!;
  bool _isLoading = true;
  List<DocumentSnapshot> _joinedCommunities = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  String capitalizeEachWord(String input) {
    return input
        .trim()
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : '')
        .join(' ');
  }

  void _addInterest() {
    final raw = _interestsController.text.trim();
    if (raw.isEmpty) return;
    final capitalized = capitalizeEachWord(raw);

    if (!_interests.contains(capitalized)) {
      setState(() {
        _interests.add(capitalized);
        _interestsController.clear();
      });
    }
  }

  void _removeInterest(String interest) {
    setState(() => _interests.remove(interest));
  }

  Future<void> _loadUserInfo() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(_user.uid).get();
    final userData = userDoc.data()!;

    _fullNameController.text = userData['fullName'] ?? '';
    _displayNameController.text = userData['displayName'] ?? '';
    _bioController.text = userData['bio'] ?? '';
    _cityController.text = userData['city'] ?? '';
    _stateController.text = userData['state'] ?? '';
    _countryController.text = userData['country'] ?? '';
    _selectedDob = userData['dob'] != null ? (userData['dob'] as Timestamp).toDate() : null;
    _interests = List<String>.from(userData['interests'] ?? []);

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
    if (_selectedDob == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your date of birth.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(_user.uid).update({
        'fullName': _fullNameController.text.trim(),
        'displayName': _displayNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'city': capitalizeEachWord(_cityController.text),
        'state': capitalizeEachWord(_stateController.text),
        'country': capitalizeEachWord(_countryController.text),
        'interests': _interests,
        'dob': _selectedDob,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = _selectedDob ?? DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _selectedDob = picked);
  }

  Future<void> _attemptLeaveCommunity(DocumentSnapshot community) async {
    final data = community.data() as Map<String, dynamic>;
    final admins = List<String>.from(data['admins'] ?? []);
    final members = List<String>.from(data['members'] ?? []);
    final pros = List<String>.from(data['pros'] ?? []);
    final communityId = community.id;

    if (admins.length == 1 && admins.first == _user.uid) {
      if (mounted) {
        _showDialog(
          title: 'Cannot Leave',
          content:
              'You are the only admin in this community. Please assign another admin before leaving.',
        );
      }
      return;
    }

    if (members.length == 1 && members.first == _user.uid) {
      final confirm = await _showConfirmDialog(
        title: 'Delete Community?',
        content:
            'You are the only member in this community. Leaving will delete the community. Continue?',
      );
      if (confirm) {
        await FirebaseFirestore.instance.collection('communities').doc(communityId).delete();
        _loadUserInfo();
      }
      return;
    }

    await FirebaseFirestore.instance.collection('communities').doc(communityId).update({
      'members': FieldValue.arrayRemove([_user.uid]),
      'admins': FieldValue.arrayRemove([_user.uid]),
      'pros': FieldValue.arrayRemove([_user.uid]),
    });

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Left community: ${data['name']}')));
    }
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                        AppTextField(
                          label: 'Full Name',
                          controller: _fullNameController,
                          validator: (val) =>
                              val == null || val.trim().isEmpty ? 'Full Name is required' : null,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Display Name',
                          controller: _displayNameController,
                          validator: (val) =>
                              val == null || val.trim().isEmpty ? 'Display Name is required' : null,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Bio',
                          controller: _bioController,
                          keyboardType: TextInputType.multiline,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            _selectedDob == null
                                ? 'Select Date of Birth'
                                : 'DOB: ${DateFormat.yMMMd().format(_selectedDob!)}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.calendar_today_rounded),
                            onPressed: _pickDob,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _interestsController,
                              decoration: InputDecoration(
                                labelText: 'Add Interests',
                                prefixIcon: const Icon(Icons.interests_rounded),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.add_rounded),
                                  onPressed: _addInterest,
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              onFieldSubmitted: (_) => _addInterest(),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: _interests
                                  .map(
                                    (interest) => Chip(
                                      label: Text(interest),
                                      onDeleted: () => _removeInterest(interest),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'City',
                          controller: _cityController,
                          validator: (val) =>
                              val == null || val.trim().isEmpty ? 'City is required' : null,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'State/Province',
                          controller: _stateController,
                          validator: (val) =>
                              val == null || val.trim().isEmpty ? 'State/Province is required' : null,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Country',
                          controller: _countryController,
                          validator: (val) =>
                              val == null || val.trim().isEmpty ? 'Country is required' : null,
                        ),
                        const SizedBox(height: 32),
                        AppButton(
                          label: 'Save Changes',
                          isLoading: _isLoading,
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
                  if (_joinedCommunities.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'You have not joined any communities yet.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._joinedCommunities.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(data['name'] ?? 'Untitled Community'),
                          subtitle: Text(data['activityType'] ?? 'No activity type'),
                          trailing: IconButton(
                            icon: const Icon(Icons.logout_rounded, color: Colors.red),
                            onPressed: () => _attemptLeaveCommunity(doc),
                            tooltip: 'Leave Community',
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
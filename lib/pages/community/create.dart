// ignore_for_file: use_build_context_synchronously, unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:issho/models/button.dart';

class CreateCommunityPage extends StatefulWidget {
  final String userId;

  const CreateCommunityPage({super.key, required this.userId});

  @override
  State<CreateCommunityPage> createState() => _CreateCommunityPageState();
}

class _CreateCommunityPageState extends State<CreateCommunityPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _activityTypeController = TextEditingController();
  final _countryController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _activityTypeController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  String _capitalizeEachWord(String input) {
    return input
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Future<void> _createCommunity() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final activity = _capitalizeEachWord(_activityTypeController.text.trim());
      final country = _capitalizeEachWord(_countryController.text.trim());
      final state = _capitalizeEachWord(_stateController.text.trim());
      final city = _capitalizeEachWord(_cityController.text.trim());

      final location = {
        'country': country,
        if (state.isNotEmpty) 'state': state,
        if (city.isNotEmpty) 'city': city,
      };

      await FirebaseFirestore.instance.collection('communities').add({
        'name': name,
        'activityType': activity,
        'location': location,
        'creatorId': widget.userId,
        'admins': [widget.userId],
        'members': [widget.userId],
        'pros': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Community created successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create community: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Community')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_nameController, 'Community Name', required: true),
              _buildTextField(_activityTypeController, 'Activity Type', required: true),
              _buildTextField(_countryController, 'Country', required: true),
              _buildTextField(_stateController, 'State'),
              _buildTextField(_cityController, 'City (Optional)'),
              const SizedBox(height: 24),
              AppButton(
                onPressed: _createCommunity,
                icon: Icons.group_add_rounded,
                label: 'Create Community',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
            : null,
      ),
    );
  }
}
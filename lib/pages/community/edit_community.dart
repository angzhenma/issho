import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:issho/models/button.dart';

class EditCommunityPage extends StatefulWidget {
  final String communityId;
  final Map<String, dynamic> communityData;

  const EditCommunityPage({
    super.key,
    required this.communityId,
    required this.communityData,
  });

  @override
  State<EditCommunityPage> createState() => _EditCommunityPageState();
}

class _EditCommunityPageState extends State<EditCommunityPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _activityController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _cityController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.communityData['name'] ?? '',
    );
    _activityController = TextEditingController(
      text: widget.communityData['activityType'] ?? '',
    );
    final location = widget.communityData['location'] as Map<String, dynamic>?;
    _stateController = TextEditingController(text: location?['state'] ?? '');
    _countryController = TextEditingController(
      text: location?['country'] ?? '',
    );
    _cityController = TextEditingController(text: location?['city'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _activityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _updateCommunity() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseFirestore.instance
            .collection('communities')
            .doc(widget.communityId)
            .update({
              'name': _nameController.text.trim(),
              'activityType': _activityController.text.trim(),
              'location.state': _stateController.text.trim(),
              'location.country': _countryController.text.trim(),
              'location.city': _cityController.text.trim(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Community updated successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update community: ${e.toString()}'),
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Community'),
        leading: IconButton(
          icon: const Icon(Icons.navigate_before_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Community Name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a community name.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _activityController,
                      decoration: const InputDecoration(labelText: 'Activity'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a community activity type.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(labelText: 'State'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a state.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(labelText: 'Country'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a country.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City (Optional)',
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Save Updates',
                      onPressed: _updateCommunity,
                      isExpanded: true,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

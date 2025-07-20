// ignore_for_file: unused_local_variable, unnecessary_brace_in_string_interps

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:issho/models/button.dart';
import 'package:issho/models/text_field.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

// Programmer Name: Mr. Ibrahim Azaan Mauroof
// Program Name: pages/auth/register_page.dart
// Program Description: Register page of the Issho mobile application.
// First Written on: Friday, 16-May-2025
// Last Modified on: Monday, 20-July-2025

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final TextEditingController _interestsTypeAheadController = TextEditingController();
  DateTime? _selectedDob;

  final List<String> interests = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _displayNameController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _interestsTypeAheadController.dispose();
    super.dispose();
  }

  String capitalizeEachWord(String input) {
    return input
        .trim()
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ');
  }

  void _addInterest(String rawInterest) {
    final capitalized = capitalizeEachWord(rawInterest);

    if (capitalized.isEmpty) return;

    if (!interests.contains(capitalized)) {
      setState(() {
        interests.add(capitalized);
        _interestsTypeAheadController.clear();
      });
    } else {
      _interestsTypeAheadController.clear();
    }
  }

  void _removeInterest(String interest) {
    setState(() => interests.remove(interest));
  }

  Future<List<String>> _getInterestSuggestions(String pattern) async {
    if (pattern.isEmpty) {
      return const [];
    }

    final lowerCasePattern = pattern.toLowerCase();

    final querySnapshot = await FirebaseFirestore.instance
        .collection('interests')
        .where('activity', isGreaterThanOrEqualTo: lowerCasePattern)
        .where('activity', isLessThanOrEqualTo: '${lowerCasePattern}\uf8ff')
        .orderBy('activity')
        .limit(10)
        .get();

    final suggestions = querySnapshot.docs
        .map((doc) => capitalizeEachWord(doc['activity'] as String))
        .where((interest) => !interests.contains(interest))
        .toList();

    return suggestions;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || _selectedDob == null) return;
    if (_interestsTypeAheadController.text.trim().isNotEmpty) {
      _addInterest(_interestsTypeAheadController.text.trim());
    }

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = credential.user!.uid;
      final timestamp = FieldValue.serverTimestamp();
      final WriteBatch batch = FirebaseFirestore.instance.batch();

      for (final interest in interests) {
        final lowerCaseInterest = interest.toLowerCase();
        final existingDocs = await FirebaseFirestore.instance
            .collection('interests')
            .where('activity', isEqualTo: lowerCaseInterest)
            .limit(1)
            .get();

        if (existingDocs.docs.isNotEmpty) {
          final docRef = existingDocs.docs.first.reference;
          batch.update(docRef, {
            'users': FieldValue.arrayUnion([uid]),
          });
        } else {
          final newInterestRef = FirebaseFirestore.instance.collection('interests').doc();
          batch.set(newInterestRef, {
            'activity': lowerCaseInterest,
            'users': [uid],
          });
        }
      }
      await batch.commit();

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': _emailController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'displayName': _displayNameController.text.trim(),
        'interests': interests,
        'city': capitalizeEachWord(_cityController.text),
        'state': capitalizeEachWord(_stateController.text),
        'country': capitalizeEachWord(_countryController.text),
        'dob': _selectedDob,
        'communities': [],
        'createdAt': timestamp,
        'updatedAt': timestamp,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'That email is already in use.';
          break;
        case 'weak-password':
          message = 'Password is too weak.';
          break;
        case 'invalid-email':
          message = 'That email format is invalid.';
          break;
        default:
          message = 'Something went wrong. Please try again.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $message')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _selectedDob = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(label: 'Email', controller: _emailController),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Confirm Password',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(label: 'Full Name', controller: _fullNameController),
                const SizedBox(height: 16),
                AppTextField(label: 'Display Name', controller: _displayNameController),
                const SizedBox(height: 16),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_selectedDob == null
                      ? 'Select Date of Birth'
                      : 'DOB: ${DateFormat.yMMMd().format(_selectedDob!)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today_rounded),
                    onPressed: _pickDob,
                  ),
                ),

                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TypeAheadField<String>(
                      controller: _interestsTypeAheadController,
                      builder: (context, controller, focusNode) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Add Interests',
                            prefixIcon: const Icon(Icons.interests_rounded),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add_rounded),
                              onPressed: () => _addInterest(controller.text.trim()),
                            ),
                          ),
                          onFieldSubmitted: (value) => _addInterest(value),
                        );
                      },
                      suggestionsCallback: _getInterestSuggestions,
                      itemBuilder: (context, suggestion) {
                        return ListTile(
                          title: Text(suggestion),
                        );
                      },
                      onSelected: (suggestion) {
                        _addInterest(suggestion);
                      },
                      emptyBuilder: (context) {
                        if (_interestsTypeAheadController.text.isNotEmpty &&
                            !interests.contains(capitalizeEachWord(_interestsTypeAheadController.text.trim()))) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'No suggestions found. Press + to add "${_interestsTypeAheadController.text.trim()}" as a new interest.',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      debounceDuration: const Duration(milliseconds: 300),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: interests
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
                AppTextField(label: 'City', controller: _cityController),
                const SizedBox(height: 16),
                AppTextField(label: 'State/Province', controller: _stateController),
                const SizedBox(height: 16),
                AppTextField(label: 'Country', controller: _countryController),
                const SizedBox(height: 32),

                AppButton(
                  label: 'Create Account',
                  isLoading: _isLoading,
                  onPressed: _register,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
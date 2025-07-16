// ignore_for_file: use_build_context_synchronously, unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateEventPage extends StatefulWidget {
  final String communityId;

  const CreateEventPage({super.key, required this.communityId});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _entryFeeController = TextEditingController();
  final _maxAttendeesController = TextEditingController();

  DateTime? _selectedDateTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _entryFeeController.dispose();
    _maxAttendeesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedDateTime == null) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final communityRef = FirebaseFirestore.instance
          .collection('communities')
          .doc(widget.communityId);
      final communitySnapshot = await communityRef.get();
      final communityData = communitySnapshot.data()!;

      final eventRef = communityRef.collection('events').doc();
      final title = _titleController.text.trim();
      final location = _locationController.text.trim();

      await eventRef.set({
        'title': title,
        'description': _descController.text.trim(),
        'location': location,
        'datetime': Timestamp.fromDate(_selectedDateTime!),
        'entryFee': double.tryParse(_entryFeeController.text.trim()) ?? 0.0,
        'maxAttendees':
            int.tryParse(_maxAttendeesController.text.trim()) ?? 999,
        'creatorId': user.uid,
        'attendees': [user.uid],
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('messages').add({
        'communityId': widget.communityId,
        'senderId': user.uid,
        'senderName':
            (await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get())
                .data()!['displayName'],
        'timestamp': Timestamp.now(),
        'eventId': eventRef.id,
        'eventTitle': title,
        'eventTime': Timestamp.fromDate(_selectedDateTime!),
        'eventLocation': location,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully!')),
        );
        Navigator.pop(context);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating event: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _entryFeeController,
                decoration: const InputDecoration(labelText: 'Entry Fee'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxAttendeesController,
                decoration: const InputDecoration(labelText: 'Max Attendees'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _selectedDateTime == null
                      ? 'Select Date & Time'
                      : DateFormat('yMMMd').add_jm().format(_selectedDateTime!),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.today_rounded),
                  onPressed: _pickDateTime,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: const Text('Create Event'),
                onPressed: _isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

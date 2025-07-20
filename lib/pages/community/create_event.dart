// ignore_for_file: use_build_context_synchronously, unused_local_variable

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:issho/models/button.dart';

class CreateEventPage extends StatefulWidget {
  final String communityId;
  final String communityName;
  final String communityCity;
  final String communityState;
  final String communityCountry;

  const CreateEventPage({
    super.key,
    required this.communityId,
    required this.communityName,
    required this.communityCity,
    required this.communityState,
    required this.communityCountry,
  });

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();

  String _title = '';
  String _description = '';
  DateTime _startDateTime = DateTime.now();
  DateTime _endDateTime = DateTime.now().add(const Duration(hours: 2));
  int _maxAttendees = 0;
  String _entryFeeCurrency = 'MYR';
  double _entryFeeAmount = 0.0;
  String _venue = '';

  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _venueController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.communityCity);
    _stateController = TextEditingController(text: widget.communityState);
    _countryController = TextEditingController(text: widget.communityCountry);
    _venueController = TextEditingController();
  }

  @override
  void dispose() {
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      final eventData = {
        'title': _title.trim(),
        'description': _description.trim(),
        'startTime': _startDateTime,
        'endTime': _endDateTime,
        'location': {
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'country': _countryController.text.trim(),
        },
        'entryFee': {
          'currency': _entryFeeCurrency.trim(),
          'amount': _entryFeeAmount,
        },
        'attendees': [],
        'creatorId': currentUser?.uid,
        'maxAttendees': _maxAttendees,
        'venue': _venue.trim(),
      };

      final eventRef = await FirebaseFirestore.instance
          .collection('communities')
          .doc(widget.communityId)
          .collection('events')
          .add(eventData);

      final communityDoc = await FirebaseFirestore.instance
          .collection('communities')
          .doc(widget.communityId)
          .get();
      final memberIds = List<String>.from(communityDoc['members'] ?? []);
      final batch = FirebaseFirestore.instance.batch();

      for (final memberId in memberIds) {
        final notifRef = FirebaseFirestore.instance
            .collection('users')
            .doc(memberId)
            .collection('notifications')
            .doc();

        batch.set(notifRef, {
          'message':
              'A new event "${_title.trim()}" has been created in ${widget.communityName}!',
          'type': 'new_event',
          'communityId': widget.communityId,
          'eventId': eventRef.id,
          'timestamp': Timestamp.now(),
        });
      }
      await batch.commit();

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error creating event: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to create event')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDateTime : _endDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        isStart ? _startDateTime : _endDateTime,
      ),
    );

    if (pickedTime == null) return;

    final fullDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStart) {
        _startDateTime = fullDateTime;
      } else {
        _endDateTime = fullDateTime;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
        leading: IconButton(
          icon: const Icon(Icons.navigate_before_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Event Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Event Title'),
                onSaved: (val) => _title = val ?? '',
                validator: (val) => val!.isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                onSaved: (val) => _description = val ?? '',
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              const Text(
                'Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Venue'),
                onSaved: (val) => _venue = val ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(labelText: 'State'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(labelText: 'Country'),
              ),
              const SizedBox(height: 24),

              const Text(
                'Entry Fee',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Currency'),
                      initialValue: _entryFeeCurrency,
                      onSaved: (val) => _entryFeeCurrency = val ?? 'MYR',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Amount'),
                      keyboardType: TextInputType.number,
                      onSaved: (val) =>
                          _entryFeeAmount = double.tryParse(val ?? '0') ?? 0.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Timing & Capacity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Max Attendees (0 = unlimited)',
                ),
                keyboardType: TextInputType.number,
                onSaved: (val) => _maxAttendees = int.tryParse(val ?? '0') ?? 0,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.event),
                  label: Text(
                    'Start: ${_startDateTime.toString().substring(0, 16)}',
                  ),
                  onPressed: () => _pickDateTime(isStart: true),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(
                    'End: ${_endDateTime.toString().substring(0, 16)}',
                  ),
                  onPressed: () => _pickDateTime(isStart: false),
                ),
              ),
              const SizedBox(height: 24),

              AppButton(
                label: 'Create Event',
                icon: Icons.check_circle_outline_rounded,
                isExpanded: true,
                isLoading: _isLoading,
                onPressed: _createEvent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

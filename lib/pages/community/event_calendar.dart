// ignore_for_file: unused_local_variable, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class EventCalendarPage extends StatefulWidget {
  final String userId;

  const EventCalendarPage({super.key, required this.userId});

  @override
  State<EventCalendarPage> createState() => _EventCalendarPageState();
}

class _EventCalendarPageState extends State<EventCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    final snapshot = await FirebaseFirestore.instance
        .collectionGroup('events')
        .get();
    final events = <DateTime, List<Map<String, dynamic>>>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final start = (data['startTime'] as Timestamp).toDate();
      final day = DateTime(start.year, start.month, start.day);
      data['eventId'] = doc.id;
      data['communityId'] = doc.reference.parent.parent?.id;
      events.putIfAbsent(day, () => []).add(data);
    }

    setState(() {
      _events = events;
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text("Select a date"))
                : ListView(
                    children: _getEventsForDay(_selectedDay!).map((event) {
                      final start = (event['startTime'] as Timestamp).toDate();
                      final end = (event['endTime'] as Timestamp).toDate();
                      final fee = event['entryFee'] ?? '';
                      final location =
                          [
                                event['venue'],
                                event['city'],
                                event['state'],
                                event['country'],
                              ]
                              .where(
                                (s) => s != null && s.toString().isNotEmpty,
                              )
                              .join(', ');

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(event['title'] ?? 'Untitled'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (event['communityName'] != null)
                                Text('Community: ${event['communityName']}'),
                              if (event['description'] != null)
                                Text(event['description']),
                              Text(
                                'Time: ${DateFormat.jm().format(start)} - ${DateFormat.jm().format(end)}',
                              ),
                              Text('Entry Fee: ${formatEntryFee(fee)}'),
                              Text('Location: $location'),
                              InkWell(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/event_list',
                                    arguments: {
                                      'communityId': event['communityId'],
                                      'eventId': event['eventId'],
                                    },
                                  );
                                },
                                child: Text(
                                  'Attendees: ${(event['attendees'] as List?)?.length ?? 0}',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  String formatEntryFee(String fee) {
    final parts = fee.trim().split(' ');
    if (parts.length != 2) return 'Free!';
    final currency = parts[0];
    final amount = double.tryParse(parts[1].replaceAll(',', ''));
    if (amount == null || amount == 0) return 'Free!';
    return '$currency ${amount.toStringAsFixed(2)}';
  }
}

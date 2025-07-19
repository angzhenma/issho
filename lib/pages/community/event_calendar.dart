// ignore_for_file: unused_local_variable, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:issho/pages/community/event_list.dart';

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
    _selectedDay = _focusedDay;
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    final snapshot = await FirebaseFirestore.instance
        .collectionGroup('events')
        .get();
    final events = <DateTime, List<Map<String, dynamic>>>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      Timestamp? startTimeStamp = data['startTime'] as Timestamp?;
      startTimeStamp ??= data['endTime'] as Timestamp?;
      if (startTimeStamp == null) {
        continue;
      }

      final start = startTimeStamp.toDate().toLocal();
      final day = DateTime(start.year, start.month, start.day);

      final communityId = doc.reference.parent.parent?.id;
      String communityName = '';
      if (communityId != null) {
        try {
          final communityDoc = await FirebaseFirestore.instance.collection('communities').doc(communityId).get();
          communityName = communityDoc.data()?['name'] ?? 'Unknown Community';
        } catch (e) {
          communityName = 'Unknown Community';
        }
      }

      final eventData = {
        'eventId': doc.id,
        'communityId': communityId,
        'communityName': communityName,
        ...data,
      };

      events.putIfAbsent(day, () => []).add(eventData);
    }

    setState(() {
      _events = events;
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  String _formatEntryFee(Map<String, dynamic>? entryFeeMap) {
    if (entryFeeMap == null || (entryFeeMap['amount'] as num? ?? 0) == 0) {
      return 'Free!';
    } else {
      final amount = (entryFeeMap['amount'] as num).toStringAsFixed(2);
      final currency = entryFeeMap['currency'] as String? ?? '';
      return '$currency $amount';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                color: theme.colorScheme.primary.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isNotEmpty) {
                  final joinedEventsOnDay = events.where((event) {
                    final attendees = (event as Map<String, dynamic>)['attendees'] as List? ?? [];
                    return attendees.contains(widget.userId);
                  }).toList();

                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (events.isNotEmpty)
                          Container(
                            width: 7.0,
                            height: 7.0,
                            margin: const EdgeInsets.symmetric(horizontal: 0.5),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (joinedEventsOnDay.isNotEmpty)
                          Container(
                            width: 7.0,
                            height: 7.0,
                            margin: const EdgeInsets.symmetric(horizontal: 0.5),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text("Select a date to view events."))
                : _getEventsForDay(_selectedDay!).isEmpty
                    ? Center(child: Text("No events on ${DateFormat('dd MMM yyyy').format(_selectedDay!)}."))
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: _getEventsForDay(_selectedDay!).map((event) {
                          final startTimeStamp = event['startTime'] as Timestamp?;
                          final endTimeStamp = event['endTime'] as Timestamp?;

                          final start = startTimeStamp?.toDate().toLocal() ?? DateTime.now();
                          final end = endTimeStamp?.toDate().toLocal() ?? DateTime.now();

                          final entryFeeMap = event['entryFee'] as Map<String, dynamic>?;
                          final attendees = event['attendees'] as List? ?? [];

                          final locationParts = <String>[];
                          if (event['venue'] != null && event['venue'].isNotEmpty) {
                            locationParts.add(event['venue']);
                          }
                          final locationData = event['location'] as Map<String, dynamic>?;
                          if (locationData != null) {
                            if (locationData['city'] != null && locationData['city'].isNotEmpty) {
                              locationParts.add(locationData['city']);
                            }
                            if (locationData['state'] != null && locationData['state'].isNotEmpty) {
                              locationParts.add(locationData['state']);
                            }
                            if (locationData['country'] != null && locationData['country'].isNotEmpty) {
                              locationParts.add(locationData['country']);
                            }
                          }
                          final locationString = locationParts.join(', ');

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event['title'] ?? 'Untitled Event',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (event['communityName'] != null && event['communityName'].isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Community: ${event['communityName']}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                  if (event['description'] != null && event['description'].isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      event['description'],
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  _buildDetailRow(
                                    context,
                                    Icons.access_time_rounded,
                                    'Time:',
                                    '${DateFormat.jm().format(start)} - ${DateFormat.jm().format(end)}',
                                  ),
                                  _buildDetailRow(
                                    context,
                                    Icons.payments_rounded,
                                    'Entry Fee:',
                                    _formatEntryFee(entryFeeMap),
                                  ),
                                  _buildDetailRow(
                                    context,
                                    Icons.location_on_rounded,
                                    'Location:',
                                    locationString.isNotEmpty ? locationString : 'TBD',
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EventListPage(
                                            communityId: event['communityId'],
                                            eventId: event['eventId'],
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Text(
                                        'Attendees: ${attendees.length} '
                                        '${(event['maxAttendees'] != null && event['maxAttendees'] > 0) ? '/ ${event['maxAttendees']}' : ''}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.primary,
                                          decoration: TextDecoration.underline,
                                        ),
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

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
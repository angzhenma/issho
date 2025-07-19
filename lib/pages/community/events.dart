// ignore_for_file: use_build_context_synchronously, prefer_final_fields

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:issho/pages/community/create_event.dart';
import 'package:issho/pages/community/event_list.dart';
import 'package:issho/widgets/event_card.dart';

class EventPage extends StatefulWidget {
  final String communityId;
  final String currentUserId;
  final String communityName;

  const EventPage({
    super.key,
    required this.communityId,
    required this.currentUserId,
    required this.communityName,
  });

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  String _filter = "All";
  String _communityName = "";
  bool _isCurrentUserAdmin = false;

  @override
  void initState() {
    super.initState();
    _communityName = widget.communityName;
    _checkIfAdmin();
  }

  void _checkIfAdmin() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('communities')
        .doc(widget.communityId)
        .get();

    final data = snapshot.data();
    if (data != null) {
      final admins = List<String>.from(data['admins'] ?? []);
      setState(() {
        _isCurrentUserAdmin = admins.contains(widget.currentUserId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsQuery = FirebaseFirestore.instance
        .collection('communities')
        .doc(widget.communityId)
        .collection('events')
        .orderBy('startTime');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _communityName.isNotEmpty ? _communityName : 'Community Events',
        ),
        actions: [
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('communities')
                .doc(widget.communityId)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              if (snapshot.hasData && snapshot.data != null) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                final isAdmin = (data['admins'] as List).contains(
                  widget.currentUserId,
                );
                if (isAdmin) {
                  final name = data['name'] ?? '';
                  final location = data['location'] ?? {};

                  final city = location['city'] ?? '';
                  final state = location['state'] ?? '';
                  final country = location['country'] ?? '';

                  return IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateEventPage(
                            communityId: widget.communityId,
                            communityName: name,
                            communityCity: city,
                            communityState: state,
                            communityCountry: country,
                          ),
                        ),
                      );
                    },
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: eventsQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No events yet."));
                }

                final filteredEvents = snapshot.data!.docs
                    .where(_applyFilter)
                    .toList();

                if (filteredEvents.isEmpty) {
                  return const Center(
                    child: Text("No events match this filter."),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final doc = filteredEvents[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final startTime = (data['startTime'] as Timestamp)
                        .toDate()
                        .toLocal();
                    final entryFeeMap =
                        data['entryFee'] as Map<String, dynamic>?;
                    final attendees = data['attendees'] as List? ?? [];

                    String entryFeeString;
                    if ((entryFeeMap?['amount'] as num? ?? 0) == 0) {
                      entryFeeString = 'Free!';
                    } else if (entryFeeMap != null && entryFeeMap['amount'] != null) {
                      final amount = (entryFeeMap['amount'] as num).toStringAsFixed(2);
                      final currency = entryFeeMap['currency'] as String? ?? '';
                      entryFeeString = '$currency $amount';
                    } else {
                      // Fallback, though the above logic should cover most cases
                      entryFeeString = 'Free!';
                    }

                    return EventCard(
                      title: data['title'] as String? ?? 'Untitled',
                      description: data['description'] as String? ?? '',
                      datetime: startTime,
                      venue: data['venue'] as String? ?? 'TBD',
                      entryFee: entryFeeString,
                      attendeeCount: attendees.length,
                      maxAttendees: data['maxAttendees'] as int? ?? 999,
                      isUserGoing: attendees.contains(widget.currentUserId),
                      onJoin: () => _toggleRSVP(doc.id, true),
                      onUnjoin: () => _toggleRSVP(doc.id, false),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventListPage(
                              communityId: widget.communityId,
                              eventId: doc.id,
                            ),
                          ),
                        );
                      },
                      onDelete: (attendees.isEmpty && _isCurrentUserAdmin)
                          ? () => _confirmDeleteEvent(doc.id)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    const filters = ['All', 'Past', 'Upcoming'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 10,
        children: filters.map((filter) {
          final selected = _filter == filter;
          return ChoiceChip(
            label: Text(filter),
            selected: selected,
            onSelected: (_) => setState(() => _filter = filter),
            selectedColor: Theme.of(context).colorScheme.secondaryContainer,
            labelStyle: TextStyle(
              color: selected
                  ? Theme.of(context).colorScheme.onSecondaryContainer
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _applyFilter(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final date = (data['startTime'] as Timestamp).toDate();
    final now = DateTime.now();

    switch (_filter) {
      case 'Past':
        return date.isBefore(now);
      case 'Upcoming':
        return date.isAfter(now);
      default:
        return true;
    }
  }

  Future<void> _toggleRSVP(String eventId, bool going) async {
    final eventRef = FirebaseFirestore.instance
        .collection('communities')
        .doc(widget.communityId)
        .collection('events')
        .doc(eventId);

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId);
    final userSnapshot = await userRef.get();
    final displayName = userSnapshot.data()?['displayName'] ?? 'Someone';

    final eventSnapshot = await eventRef.get();
    final eventData = eventSnapshot.data();
    final title = eventData?['title'] ?? 'Untitled';
    final communityId = widget.communityId;

    final communityRef = FirebaseFirestore.instance
        .collection('communities')
        .doc(communityId);
    final communitySnapshot = await communityRef.get();
    final List adminIds = communitySnapshot.data()?['admins'] ?? [];

    await eventRef.update({
      'attendees': going
          ? FieldValue.arrayUnion([widget.currentUserId])
          : FieldValue.arrayRemove([widget.currentUserId]),
    });

    if (going) {
      for (final adminId in adminIds) {
        if (adminId != widget.currentUserId) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(adminId)
              .collection('notifications')
              .add({
                'type': 'event_joined',
                'message': '$displayName has joined the event "$title".',
                'timestamp': FieldValue.serverTimestamp(),
                'eventId': eventId,
                'communityId': communityId,
                'fromUserId': widget.currentUserId,
              });
        }
      }
    }
  }

  void _confirmDeleteEvent(String eventId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await FirebaseFirestore.instance
          .collection('communities')
          .doc(widget.communityId)
          .collection('events')
          .doc(eventId)
          .delete();
    }
  }
}
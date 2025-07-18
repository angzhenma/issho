// ignore_for_file: use_build_context_synchronously

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

  @override
  void initState() {
    super.initState();
    _communityName = widget.communityName;
  }

  // void _loadCommunityName() async {
  //   final snapshot = await FirebaseFirestore.instance
  //       .collection('communities')
  //       .doc(widget.communityId)
  //       .get();
  //   if (snapshot.exists) {
  //     setState(() {
  //       _communityName = snapshot.data()?['name'] ?? widget.communityId;
  //     });
  //   }
  // }

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
                    final startTime = (data['startTime'] as Timestamp).toDate();
                    final locationMap =
                        data['location'] as Map<String, dynamic>?;
                    final entryFeeMap =
                        data['entryFee'] as Map<String, dynamic>?;

                    return EventCard(
                      title: data['title'] ?? 'Untitled',
                      description: data['description'] ?? '',
                      datetime: startTime,
                      venue: data['venue'] ?? 'TBD',
                      attendeeCount: (data['attendees'] as List).length,
                      maxAttendees: data['maxAttendees'] ?? 999,
                      isUserGoing: (data['attendees'] as List).contains(
                        widget.currentUserId,
                      ),
                      entryFee: entryFeeMap != null && entryFeeMap['amount'] > 0
                          ? "${entryFeeMap['currency']} ${entryFeeMap['amount']}"
                          : "Free",
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
    const filters = ['All', 'This Week', 'My Events'];
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

    switch (_filter) {
      case 'This Week':
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return date.isAfter(startOfWeek) && date.isBefore(endOfWeek);
      case 'My Events':
        return (data['attendees'] as List).contains(widget.currentUserId);
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
}

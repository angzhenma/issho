import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:issho/pages/community/create_event.dart';
import 'package:issho/widgets/event_card.dart';

class EventPage extends StatefulWidget {
  final String communityId;
  final String currentUserId;

  const EventPage({
    super.key,
    required this.communityId,
    required this.currentUserId, required communityName,
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
    _loadCommunityName();
  }

  void _loadCommunityName() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('communities')
        .doc(widget.communityId)
        .get();
    if (snapshot.exists) {
      setState(() {
        _communityName = snapshot.data()?['name'] ?? widget.communityId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsQuery = FirebaseFirestore.instance
        .collection('events')
        .where('communityId', isEqualTo: widget.communityId)
        .orderBy('datetime');

    return Scaffold(
      appBar: AppBar(
        title: Text(_communityName.isNotEmpty ? _communityName : 'Community Events'),
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
                final isAdmin = (data['admins'] as List).contains(widget.currentUserId);
                if (isAdmin) {
                  return IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateEventPage(communityId: widget.communityId),
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

                final filteredEvents = snapshot.data!.docs.where(_applyFilter).toList();

                if (filteredEvents.isEmpty) {
                  return const Center(child: Text("No events match this filter."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final doc = filteredEvents[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final date = (data['datetime'] as Timestamp).toDate();

                    return EventCard(
                      title: data['title'] ?? 'Untitled',
                      description: data['description'] ?? '',
                      datetime: date,
                      location: data['location'] ?? 'TBD',
                      attendeeCount: (data['attendees'] as List).length,
                      maxAttendees: data['maxAttendees'] ?? 999,
                      isUserGoing: (data['attendees'] as List).contains(widget.currentUserId),
                      onJoin: () => _toggleRSVP(doc.id, true),
                      onUnjoin: () => _toggleRSVP(doc.id, false),
                      onTap: () {},
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
    final date = (data['datetime'] as Timestamp).toDate();

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
    final eventRef = FirebaseFirestore.instance.collection('events').doc(eventId);

    await eventRef.update({
      'attendees': going
          ? FieldValue.arrayUnion([widget.currentUserId])
          : FieldValue.arrayRemove([widget.currentUserId]),
    });
  }
}

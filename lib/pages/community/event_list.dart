// ignore_for_file: unnecessary_import

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class EventListPage extends StatefulWidget {
  final String communityId;
  final String eventId;

  const EventListPage({
    super.key,
    required this.communityId,
    required this.eventId,
  });

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  late Future<List<Map<String, dynamic>>> _attendeeData;

  @override
  void initState() {
    super.initState();
    _attendeeData = _fetchAttendeeDetails();
  }

  Future<List<Map<String, dynamic>>> _fetchAttendeeDetails() async {
    final eventSnap = await FirebaseFirestore.instance
        .collection('communities')
        .doc(widget.communityId)
        .collection('events')
        .doc(widget.eventId)
        .get();

    final List<dynamic> attendeeIds = eventSnap.data()?['attendees'] ?? [];

    if (attendeeIds.isEmpty) return [];

    // Fetch community doc for admin and pro info
    final communitySnap = await FirebaseFirestore.instance
        .collection('communities')
        .doc(widget.communityId)
        .get();

    final List<dynamic> admins = communitySnap.data()?['admins'] ?? [];
    final List<dynamic> pros = communitySnap.data()?['pros'] ?? [];

    final List<Map<String, dynamic>> attendees = [];

    for (final uid in attendeeIds) {
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userSnap.exists) {
        final userData = userSnap.data()!;
        attendees.add({
          'uid': uid,
          'displayName': userData['displayName'] ?? 'Unnamed',
          'photoUrl': userData['photoUrl'],
          'isAdmin': admins.contains(uid),
          'isPro': pros.contains(uid),
        });
      }
    }

    return attendees;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Attendees"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _attendeeData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No attendees yet."));
          }

          final attendees = snapshot.data!;

          return ListView.builder(
            itemCount: attendees.length,
            itemBuilder: (context, index) {
              final attendee = attendees[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: attendee['photoUrl'] != null
                      ? NetworkImage(attendee['photoUrl'])
                      : null,
                  child: attendee['photoUrl'] == null
                      ? const Icon(Icons.person_rounded)
                      : null,
                ),
                title: Text(attendee['displayName']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (attendee['isAdmin'])
                      const Icon(Icons.shield_rounded, color: Colors.pinkAccent),
                    if (attendee['isPro'])
                      const Padding(
                        padding: EdgeInsets.only(left: 4.0),
                        child: Icon(Icons.star_rounded, color: Colors.deepPurpleAccent),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
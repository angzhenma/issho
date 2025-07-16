// ignore_for_file: unused_local_variable, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Calendar'), centerTitle: true),
      body: FutureBuilder<List<Appointment>>(
        future: _loadAppointments(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(8),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: SfCalendar(
                view: CalendarView.month,
                firstDayOfWeek: 1,
                dataSource: MeetingDataSource(snapshot.data!),
                todayHighlightColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.surface,
                monthViewSettings: MonthViewSettings(
                  appointmentDisplayMode:
                      MonthAppointmentDisplayMode.appointment,
                  agendaViewHeight: 200,
                  agendaItemHeight: 48,
                  appointmentDisplayCount: 3,
                ),
                headerStyle: CalendarHeaderStyle(
                  textAlign: TextAlign.center,
                  textStyle: Theme.of(context).textTheme.titleMedium,
                ),
                viewHeaderStyle: ViewHeaderStyle(
                  dayTextStyle: Theme.of(context).textTheme.bodyMedium!,
                ),
                todayTextStyle: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<List<Appointment>> _loadAppointments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final events = <Appointment>[];
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userCountry = userDoc['location']['country'];
    final userState = userDoc['location']['state'];

    final userCommunityDocs = await FirebaseFirestore.instance
        .collection('communities')
        .where('members', arrayContains: user.uid)
        .get();
    final userCommunityIds = userCommunityDocs.docs
        .map((doc) => doc.id)
        .toSet();

    final allCommunities = await FirebaseFirestore.instance
        .collection('communities')
        .get();
    final Map<String, dynamic> communityLocationMap = {
      for (var c in allCommunities.docs) c.id: c.data(),
    };

    final allEventsSnap = await FirebaseFirestore.instance
        .collection('events')
        .get();

    for (var doc in allEventsSnap.docs) {
      final data = doc.data();
      final date = (data['datetime'] as Timestamp).toDate();
      final communityId = data['communityId'];

      if (communityId == null) continue; // skip broken events

      final isUserMember = userCommunityIds.contains(communityId);
      final communityData = communityLocationMap[communityId];
      final isRecommended =
          !isUserMember &&
          communityData?['location']['country'] == userCountry &&
          communityData?['location']['state'] == userState;

      events.add(
        Appointment(
          startTime: date,
          endTime: date.add(const Duration(hours: 2)),
          subject: data['title'] ?? 'Untitled',
          color: isUserMember
              ? Colors.blue.withOpacity(0.7)
              : isRecommended
              ? Colors.orangeAccent.withOpacity(0.6)
              : Colors.grey.shade400,
        ),
      );
    }

    return events;
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}

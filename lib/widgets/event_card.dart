// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventCard extends StatelessWidget {
  final String title;
  final String description;
  final DateTime datetime;
  final String location;
  final int attendeeCount;
  final int maxAttendees;
  final VoidCallback onTap;
  final bool isUserGoing;
  final VoidCallback onJoin;
  final VoidCallback onUnjoin;

  const EventCard({
    super.key,
    required this.title,
    required this.description,
    required this.datetime,
    required this.location,
    required this.attendeeCount,
    required this.maxAttendees,
    required this.onTap,
    required this.isUserGoing,
    required this.onJoin,
    required this.onUnjoin,
  });

  @override
  Widget build(BuildContext context) {
    final month = DateFormat.MMM().format(datetime).toUpperCase();
    final day = DateFormat.d().format(datetime);
    final time = DateFormat.jm().format(datetime);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            // Date Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    month,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                  ),
                  Text(
                    day,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                  ),
                ],
              ),
            ),

            // Main Card Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),

                    // Description
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),

                    // Time and Location
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 16),
                        const SizedBox(width: 4),
                        Text(time, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(width: 12),
                        const Icon(Icons.place_rounded, size: 16),
                        const SizedBox(width: 4),
                        Expanded(child: Text(location, style: Theme.of(context).textTheme.bodySmall)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Attendees + RSVP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people_rounded, size: 16),
                            const SizedBox(width: 4),
                            Text('$attendeeCount going'),
                          ],
                        ),
                        _buildRSVPButton(context),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRSVPButton(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          final confirmed = await _confirmDialog(
            context,
            isUserGoing ? 'Leave Event' : 'Join Event',
            isUserGoing
              ? 'Are you sure you want to un-RSVP from this event?'
              : 'Do you want to RSVP to this event?',
          );
          if (confirmed) isUserGoing ? onUnjoin() : onJoin();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isUserGoing
              ? Colors.green.withOpacity(0.1)
              : theme.colorScheme.primary.withOpacity(0.1),
            border: Border.all(
              color: isUserGoing ? Colors.green : theme.colorScheme.primary,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isUserGoing ? 'Going' : "I'm in!",
            style: TextStyle(
              color: isUserGoing ? Colors.green : theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDialog(BuildContext context, String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventCard extends StatelessWidget {
  final String title;
  final String description;
  final DateTime datetime;
  final String venue;
  final String entryFee;
  final int attendeeCount;
  final int maxAttendees;
  final bool isUserGoing;
  final VoidCallback onJoin;
  final VoidCallback onUnjoin;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const EventCard({
    super.key,
    required this.title,
    required this.description,
    required this.datetime,
    required this.venue,
    required this.entryFee,
    required this.attendeeCount,
    required this.maxAttendees,
    required this.isUserGoing,
    required this.onJoin,
    required this.onUnjoin,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String formattedDateTime = DateFormat(
      'MMM dd, yyyy - hh:mm a',
    ).format(datetime);
    final bool isEventInFuture =
        datetime.isAfter(DateTime.now()) ||
        datetime.isAtSameMomentAs(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(
                        Icons.delete_rounded,
                        color: theme.colorScheme.error,
                      ),
                      onPressed: onDelete,
                      tooltip: 'Delete Event',
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formattedDateTime,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      venue,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entryFee,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isEventInFuture)
                    Row(
                      children: [
                        Icon(
                          Icons.people_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$attendeeCount${maxAttendees > 0 ? ' / $maxAttendees' : ''} going',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isUserGoing ? onUnjoin : onJoin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isUserGoing
                                ? theme.colorScheme.tertiaryContainer
                                : theme.colorScheme.primary,
                            foregroundColor: isUserGoing
                                ? theme.colorScheme.onTertiaryContainer
                                : theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            minimumSize: const Size(80, 36),
                          ),
                          child: Text(isUserGoing ? "I'm out" : "I'm in"),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

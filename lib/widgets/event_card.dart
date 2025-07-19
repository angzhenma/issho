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
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

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
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFull = maxAttendees > 0 && attendeeCount >= maxAttendees;
    final time = DateFormat('h:mm a').format(datetime.toLocal());
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isFull)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Full',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  if (onDelete != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                        ),
                        color: Colors.red.withOpacity(0.7),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onDelete,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 4),

              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(time, style: theme.textTheme.bodySmall),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.place_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      venue,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entryFee,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.people_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$attendeeCount going',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 12),
                      _RSVPButton(
                        isUserGoing: isUserGoing,
                        onJoin: onJoin,
                        onUnjoin: onUnjoin,
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

class _RSVPButton extends StatelessWidget {
  final bool isUserGoing;
  final VoidCallback onJoin;
  final VoidCallback onUnjoin;

  const _RSVPButton({
    required this.isUserGoing,
    required this.onJoin,
    required this.onUnjoin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: isUserGoing ? onUnjoin : onJoin,
      style: TextButton.styleFrom(
        backgroundColor: isUserGoing
            ? theme.colorScheme.primary.withOpacity(0.2)
            : theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isUserGoing
              ? BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.5),
                  width: 1,
                )
              : BorderSide.none,
        ),
      ),
      child: Text(
        isUserGoing ? "I'm out" : "I'm in",
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: isUserGoing
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}

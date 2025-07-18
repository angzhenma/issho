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
  final bool isFull;
  final VoidCallback onJoin;
  final VoidCallback onUnjoin;
  final VoidCallback onTap;

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
    this.isFull = false,
  });

  String formatEntryFee(String fee) {
    final parts = fee.trim().split(' ');
    if (parts.length != 2) return 'Free!';

    final currency = parts[0];
    final amountStr = parts[1].replaceAll(',', '');
    final amount = double.tryParse(amountStr);

    if (amount == null || amount == 0) {
      return 'Free!';
    } else {
      return '$currency ${amount.toStringAsFixed(2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.d().format(datetime);
    final month = DateFormat.MMM().format(datetime).toUpperCase();
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    date,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.secondary,
                        ),
                  ),
                  Text(
                    month,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.secondary,
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _EventInfo(
                title: title,
                description: description,
                datetime: datetime,
                venue: venue,
                entryFee: formatEntryFee(entryFee),
                attendeeCount: attendeeCount,
                isFull: isFull || attendeeCount >= maxAttendees,
                isUserGoing: isUserGoing,
                onJoin: onJoin,
                onUnjoin: onUnjoin,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventInfo extends StatelessWidget {
  final String title;
  final String description;
  final DateTime datetime;
  final String venue;
  final String entryFee;
  final int attendeeCount;
  final bool isFull;
  final bool isUserGoing;
  final VoidCallback onJoin;
  final VoidCallback onUnjoin;

  const _EventInfo({
    required this.title,
    required this.description,
    required this.datetime,
    required this.venue,
    required this.entryFee,
    required this.attendeeCount,
    required this.isFull,
    required this.isUserGoing,
    required this.onJoin,
    required this.onUnjoin,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.jm().format(datetime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isFull)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Full',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.red),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 14),
            const SizedBox(width: 4),
            Text(time, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 10),
            const Icon(Icons.place_rounded, size: 14),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                venue,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              entryFee,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
            Row(
              children: [
                const Icon(Icons.people_rounded, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$attendeeCount going',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 10),
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
    return TextButton(
      onPressed: isUserGoing ? onUnjoin : onJoin,
      style: TextButton.styleFrom(
        foregroundColor: isUserGoing ? Colors.red : Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(isUserGoing ? 'Leave' : 'Join'),
    );
  }
}

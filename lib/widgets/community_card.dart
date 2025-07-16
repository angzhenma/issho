import 'package:flutter/material.dart';
import 'package:issho/models/button.dart';
import 'package:issho/pages/community/chat.dart';
import 'package:issho/pages/community/events.dart';

class CommunityCard extends StatelessWidget {
  final Map<String, dynamic> community;
  final bool isJoined;
  final String currentUserId;
  final VoidCallback onJoin;

  const CommunityCard({
    super.key,
    required this.community,
    required this.isJoined,
    required this.currentUserId,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final communityId = community['id'];
    final name = community['name'] ?? 'Unnamed Community';
    final desc = community['description'] ?? '';
    final members = (community['members'] as List?)?.length ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Community Name
            Text(
              name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),

            // Description (optional)
            if (desc.isNotEmpty)
              Text(
                desc,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 8),

            // Member Count
            Row(
              children: [
                const Icon(Icons.people_rounded, size: 16),
                const SizedBox(width: 4),
                Text('$members member${members == 1 ? '' : 's'}'),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons
            if (isJoined)
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Events',
                      icon: Icons.event_note_rounded,
                      isOutlined: true,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventPage(
                            communityId: communityId,
                            communityName: name,
                            currentUserId: currentUserId,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      label: 'Chat',
                      icon: Icons.messenger_rounded,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            communityId: communityId,
                            communityName: name,
                            currentUserId: currentUserId,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              AppButton(
                label: 'Join Community',
                isExpanded: true,
                onPressed: onJoin,
              ),
          ],
        ),
      ),
    );
  }
}

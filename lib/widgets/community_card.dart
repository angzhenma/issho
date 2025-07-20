import 'package:flutter/material.dart';
import 'package:issho/models/button.dart';
import 'package:issho/pages/community/chat.dart';
import 'package:issho/pages/community/events.dart';
import 'package:issho/pages/community/edit_community.dart';

class CommunityCard extends StatelessWidget {
  final Map<String, dynamic> community;
  final bool isJoined;
  final String currentUserId;
  final VoidCallback onJoin;
  final bool isCommunityAdmin;

  const CommunityCard({
    super.key,
    required this.community,
    required this.isJoined,
    required this.currentUserId,
    required this.onJoin,
    required this.isCommunityAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final communityId = community['id'];
    final name = community['name'] ?? 'Unnamed Community';
    final activity = community['activityType'] ?? '';
    final members = (community['members'] as List?)?.length ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow
                        .ellipsis,
                  ),
                ),
                if (isCommunityAdmin)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditCommunityPage(
                              communityId: communityId,
                              communityData: community,
                            ),
                          ),
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Text('Edit Community'),
                          ),
                        ],
                    icon: const Icon(Icons.more_vert_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            if (activity.isNotEmpty)
              Text(activity, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.people_rounded, size: 16),
                const SizedBox(width: 4),
                Text('$members member${members == 1 ? '' : 's'}'),
              ],
            ),
            const SizedBox(height: 16),

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
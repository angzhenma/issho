// ignore_for_file: unnecessary_underscores, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:issho/pages/community/events.dart';
import 'package:issho/pages/profile.dart';
import 'package:issho/widgets/member_list.dart';

class ChatPage extends StatefulWidget {
  final String communityId;
  final String communityName;
  final String currentUserId;

  const ChatPage({
    super.key,
    required this.communityId,
    required this.communityName,
    required this.currentUserId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _user = FirebaseAuth.instance.currentUser!;
  String _communityId = '';
  String _communityName = '';
  List<String> _admins = [];
  List<String> _pros = [];
  int? _lastDocCount;

  @override
  void initState() {
    _communityId = widget.communityId;
    _communityName = widget.communityName;
    super.initState();
    _loadCommunityInfo();
  }

  Future<void> _loadCommunityInfo() async {
    final doc = await FirebaseFirestore.instance
        .collection('communities')
        .doc(_communityId)
        .get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        _communityName = data['name'];
        _admins = List<String>.from(data['admins']);
        _pros = List<String>.from(data['pros'] ?? []);
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .get();

    final messageData = {
      'communityId': _communityId,
      'senderId': _user.uid,
      'senderName': userData['displayName'],
      'messageText': text.trim(),
      'messageTime': Timestamp.now(),
    };

    await FirebaseFirestore.instance
        .collection('communities')
        .doc(_communityId)
        .collection('messages')
        .add(messageData);

    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessage(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final bool isCurrentUser = data['senderId'] == _user.uid;
    final bool isAdmin = _admins.contains(data['senderId']);
    final bool isPro = _pros.contains(data['senderId']);

    final Color bubbleColor = isCurrentUser
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;

    final Color textColor = isCurrentUser
        ? Theme.of(context).colorScheme.onPrimary
        : Colors.black;

    final Color senderColor = isAdmin
        ? Colors.pinkAccent
        : isPro
        ? Colors.deepPurpleAccent
        : Colors.black;

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isCurrentUser
                ? const Radius.circular(16)
                : const Radius.circular(4),
            bottomRight: isCurrentUser
                ? const Radius.circular(4)
                : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isCurrentUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCurrentUser)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(userId: data['senderId']),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data['senderName'],
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: senderColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isAdmin)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.shield_rounded,
                          size: 16,
                          color: Colors.pinkAccent,
                        ),
                      ),
                    if (isPro)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Colors.deepPurpleAccent,
                        ),
                      ),
                  ],
                ),
              ),
            if (!isCurrentUser) const SizedBox(height: 4),
            Text(
              data['messageText'],
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToMembers() async {
    final communityDoc = await FirebaseFirestore.instance
        .collection('communities')
        .doc(widget.communityId)
        .get();

    final data = communityDoc.data();
    final List<String> memberIds = List<String>.from(data?['members'] ?? []);
    final List<String> adminIds = List<String>.from(data?['admins'] ?? []);
    final List<String> proIds = List<String>.from(data?['pros'] ?? []);
    final String communityName = data?['name'] ?? 'Community';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MemberListPage(
          communityId: widget.communityId,
          communityName: communityName,
          memberIds: memberIds,
          adminIds: adminIds,
          proIds: proIds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppBar(
            title: Text(
              _communityName.isNotEmpty ? _communityName : 'Community Chat',
            ),
            leading: IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded),
                onPressed: _navigateToMembers,
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('communities')
                  .doc(_communityId)
                  .collection('messages')
                  .orderBy('messageTime')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: LinearProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "It's quiet in here...\nAnyone got a good conversation starter?",
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (_lastDocCount == null || docs.length > _lastDocCount!) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _scrollToBottom(),
                  );
                }
                _lastDocCount = docs.length;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: docs.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemBuilder: (context, index) => _buildMessage(docs[index]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Message',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
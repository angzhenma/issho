import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:issho/pages/community/events.dart';
import 'package:issho/pages/profile.dart';

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
  List<Map<String, dynamic>> _members = [];
  int? _lastDocCount;
  bool _showSidebar = false;

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

      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final allUsers = usersSnapshot.docs.map((e) => e.data()).toList();

      setState(() {
        _members = allUsers
            .where((user) => data['members'].contains(user['uid']))
            .toList();
      });
    }
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .get();

    FirebaseFirestore.instance.collection('messages').add({
      'communityId': _communityId,
      'senderId': _user.uid,
      'senderName': userData['displayName'],
      'text': text.trim(),
      'timestamp': Timestamp.now(),
    });

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
    final isAdmin = _admins.contains(data['senderId']);
    final isPro = _pros.contains(data['senderId']);
    final isEvent = data.containsKey('eventId');

    if (isEvent) return _buildEventMessage(data);

    return Align(
      alignment: data['senderId'] == _user.uid
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: data['senderId'] == _user.uid
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(userId: data['senderId']),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    data['senderName'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isAdmin
                          ? Colors.amber
                          : isPro
                              ? Colors.lightBlue
                              : null,
                    ),
                  ),
                  if (isAdmin)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.shield_rounded, size: 16, color: Colors.amber),
                    ),
                  if (isPro)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.stars_rounded, size: 16, color: Colors.lightBlue),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(data['text']),
          ],
        ),
      ),
    );
  }

  Widget _buildEventMessage(Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventPage(
            communityId: widget.communityId,
            communityName: widget.communityName, // ✅ FIXED: required param
            currentUserId: widget.currentUserId,
          ),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data['eventTitle'] ?? 'Untitled Event'),
              Text(
                data['eventTime'] != null
                    ? '🕒 ${DateFormat.jm().format(data['eventTime'].toDate())}'
                    : '🕒 Time not set',
              ),
              Text('📍 ${data['eventLocation'] ?? 'Unknown'}'),
              ElevatedButton(onPressed: () {}, child: const Text("I'm in!")),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _showSidebar ? MediaQuery.of(context).size.width * 0.75 : 0,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _showSidebar
          ? Column(
              children: [
                AppBar(
                  title: const Text('Community Members'),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded),
                    onPressed: () => setState(() => _showSidebar = false),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      final isAdmin = _admins.contains(member['uid']);
                      final isPro = _pros.contains(member['uid']);

                      return ListTile(
                        leading: Icon(
                          isAdmin
                              ? Icons.shield_rounded
                              : isPro
                                  ? Icons.stars_rounded
                                  : Icons.person,
                        ),
                        title: Text(
                          member['displayName'] ?? '',
                          style: TextStyle(
                            color: isAdmin
                                ? Colors.amber
                                : isPro
                                    ? Colors.lightBlue
                                    : null,
                          ),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfilePage(userId: member['uid']),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              AppBar(
                title: Text(_communityName.isNotEmpty ? _communityName : 'Community Chat'),
                leading: IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded),
                    onPressed: () => setState(() => _showSidebar = true),
                  ),
                ],
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('messages')
                      .where('communityId', isEqualTo: _communityId)
                      .orderBy('timestamp')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: LinearProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;

                    if (_lastDocCount == null || docs.length > _lastDocCount!) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _scrollToBottom(),
                      );
                    }
                    _lastDocCount = docs.length;

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: docs.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          hintText: 'Type a message...',
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
          _buildSidebar(),
        ],
      ),
    );
  }
}

// ignore_for_file: use_build_context_synchronously, unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:issho/pages/community/chat.dart';
import 'package:issho/pages/community/create.dart';
import 'package:issho/pages/profile.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  final List<String> _history = [];
  final userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _query = _controller.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Search users or communities...',
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
        ),
      ),
      body: _query.isEmpty
          ? _buildHistory()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Users', _searchUsers()),
                  _buildSection('Communities', _searchCommunities()),
                ],
              ),
            ),
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return const Center(
        child: Text('Start typing to search or view past searches here.'),
      );
    }
    return ListView(
      children: _history.map((item) {
        return ListTile(
          title: Text(item),
          leading: const Icon(Icons.history),
          trailing: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _history.remove(item);
              });
            },
          ),
          onTap: () {
            setState(() {
              _controller.text = item;
              _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: _controller.text.length),
              );
              _query = item;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSection(String label, Stream<QuerySnapshot> stream) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(label, style: Theme.of(context).textTheme.titleMedium),
              ),
              const LinearProgressIndicator(),
            ],
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final docs = snapshot.data!.docs;
        if (label == 'Communities' && docs.isEmpty) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox();
              }
              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                return const SizedBox();
              }
              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
              final interests = (userData['interests'] ?? []) as List;
              if (interests.any((i) => i.toString().toLowerCase() == _query.toLowerCase())) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Seems like there are no communities for "$_query"!',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Why not be the one to create a space for this community on Issho?',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create Community'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateCommunityPage(userId: userId),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox();
            },
          );
        }

        if (docs.isEmpty) {
          return const SizedBox();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(label, style: Theme.of(context).textTheme.titleMedium),
            ),
            ...docs.map((doc) => ListTile(
                  //
                  title: Text(doc['displayName'] ?? doc['name'] ?? 'Unnamed'),
                  subtitle: Text(
                    label == 'Users'
                        ? doc['email'] ?? ''
                        : label == 'Communities'
                            ? doc['activityType'] ?? ''
                            : '',
                  ),
                  onTap: () async {
                    if (!_history.contains(_query) && _query.isNotEmpty) {
                      setState(() {
                        _history.insert(0, _query);
                        if (_history.length > 5) {
                          _history.removeLast();
                        }
                      });
                    }

                    if (label == 'Users') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfilePage(userId: doc.id),
                        ),
                      );
                    } else if (label == 'Communities') {
                      final List<dynamic> members = doc['members'] ?? [];
                      final joined = members.contains(userId);

                      if (!joined) {
                        final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text('Join ${doc['name']}?'),
                                content: const Text('You need to join this community to chat with members.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                  ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Join')),
                                ],
                              ),
                            ) ??
                            false;
                        if (!confirm) return;

                        await FirebaseFirestore.instance.collection('communities').doc(doc.id).update({
                          'members': FieldValue.arrayUnion([userId])
                        });
                        if (mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Joined ${doc['name']}!')),
                          );
                        }
                      }
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              communityId: doc.id,
                              communityName: doc['name'] ?? 'Community',
                              currentUserId: userId,
                            ),
                          ),
                        );
                      }
                    }
                  },
                )),
          ],
        );
      },
    );
  }

  Stream<QuerySnapshot> _searchUsers() {
    if (_query.isEmpty) return Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: _query)
        .where('displayName', isLessThanOrEqualTo: '$_query\uf8ff')
        .snapshots();
  }

  Stream<QuerySnapshot> _searchCommunities() {
    if (_query.isEmpty) return Stream.empty();
    return FirebaseFirestore.instance
        .collection('communities')
        .where('name', isGreaterThanOrEqualTo: _query)
        .where('name', isLessThanOrEqualTo: '$_query\uf8ff')
        .snapshots();
  }
}
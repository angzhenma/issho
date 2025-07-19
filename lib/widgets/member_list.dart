// ignore_for_file: use_build_context_synchronously, unnecessary_brace_in_string_interps, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:issho/pages/profile.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MemberListPage extends StatefulWidget {
  final List<String> memberIds;
  final List<String> adminIds;
  final List<String> proIds;
  final String communityId;
  final String communityName;

  const MemberListPage({
    super.key,
    required this.memberIds,
    required this.adminIds,
    required this.proIds,
    required this.communityId,
    required this.communityName,
  });

  @override
  State<MemberListPage> createState() => _MemberListPageState();
}

class _MemberListPageState extends State<MemberListPage> {
  final _auth = FirebaseAuth.instance;
  late bool _isCurrentUserAdmin;
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    _isCurrentUserAdmin = widget.adminIds.contains(_auth.currentUser?.uid);
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .get();

      final allUsers = userSnap.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();

      final members = allUsers.where((user) {
        final uid = user['uid']?.toString();
        return uid != null && widget.memberIds.contains(uid);
      }).toList();

      setState(() {
        _members = members;
      });

      if (members.isEmpty) {
        print("No matching users found for memberIds: ${widget.memberIds}");
      }
    } catch (e) {
      print('Error loading members: $e');
    }
  }

  void _toggleRole(String uid) async {
    final isAdmin = widget.adminIds.contains(uid);
    final isPro = widget.proIds.contains(uid);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change Member Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                isAdmin ? Icons.remove_circle : Icons.shield,
                color: isAdmin ? Colors.redAccent : Colors.pinkAccent,
              ),
              title: Text(isAdmin ? 'Remove admin role' : 'Make admin'),
              onTap: () async {
                final updatedAdmins = List<String>.from(widget.adminIds);
                if (isAdmin) {
                  updatedAdmins.remove(uid);
                } else {
                  updatedAdmins.add(uid);
                }
                await FirebaseFirestore.instance
                    .collection('communities')
                    .doc(widget.communityId)
                    .update({'admins': updatedAdmins});
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Admin role updated');
                setState(() {
                  widget.adminIds.clear();
                  widget.adminIds.addAll(updatedAdmins);
                });
              },
            ),
            ListTile(
              leading: Icon(
                isPro ? Icons.remove_circle : Icons.star_rounded,
                color: isPro ? Colors.redAccent : Colors.deepPurpleAccent,
              ),
              title: Text(isPro ? 'Remove pro role' : 'Make pro'),
              onTap: () async {
                final updatedPros = List<String>.from(widget.proIds);
                if (isPro) {
                  updatedPros.remove(uid);
                } else {
                  updatedPros.add(uid);
                }
                await FirebaseFirestore.instance
                    .collection('communities')
                    .doc(widget.communityId)
                    .update({'pros': updatedPros});
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Pro role updated');
                setState(() {
                  widget.proIds.clear();
                  widget.proIds.addAll(updatedPros);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.communityName} Members'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _members.isEmpty
          ? const Center(child: Text('No members yet.'))
          : ListView.builder(
              itemCount: _members.length,
              itemBuilder: (_, index) {
                final member = _members[index];
                final uid = member['uid'];
                final displayName = member['displayName'] ?? 'Unnamed';
                final isAdmin = widget.adminIds.contains(uid);
                final isPro = widget.proIds.contains(uid);

                return ListTile(
                  title: Text(displayName),
                  leading: const Icon(Icons.person_rounded),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPro)
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.deepPurpleAccent,
                          size: 20,
                        ),
                      if (isAdmin)
                        const Icon(
                          Icons.shield_rounded,
                          color: Colors.pinkAccent,
                          size: 20,
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(userId: uid),
                      ),
                    );
                  },
                  onLongPress:
                      _isCurrentUserAdmin && uid != _auth.currentUser!.uid
                      ? () => _toggleRole(uid)
                      : null,
                );
              },
            ),
    );
  }
}

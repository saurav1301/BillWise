import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import 'join_group_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isSelectionMode = false;
  Set<String> selectedGroupIds = {};

  Stream<QuerySnapshot> getUserGroupsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: uid)
        .snapshots();
  }

  void toggleSelection(String groupId) {
    setState(() {
      if (selectedGroupIds.contains(groupId)) {
        selectedGroupIds.remove(groupId);
      } else {
        selectedGroupIds.add(groupId);
      }

      if (selectedGroupIds.isEmpty) isSelectionMode = false;
    });
  }

  void deleteSelectedGroups() async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Selected Groups"),
        content: Text("Are you sure you want to delete ${selectedGroupIds.length} group(s)?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirm == true) {
      for (var groupId in selectedGroupIds) {
        await FirebaseFirestore.instance.collection('groups').doc(groupId).delete();
      }
      setState(() {
        isSelectionMode = false;
        selectedGroupIds.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: isSelectionMode
            ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              isSelectionMode = false;
              selectedGroupIds.clear();
            });
          },
        )
            : IconButton(
          icon: const Icon(Icons.account_circle),
          onPressed: () {
            Navigator.pushNamed(context, '/profile');
          },
        ),
        title: Text(isSelectionMode ? "${selectedGroupIds.length} Selected" : "Your Groups"),
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: deleteSelectedGroups,
            )
          else
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await AuthService().signOut();
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getUserGroupsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No groups yet."));
          }

          final groups = snapshot.data!.docs;

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              final groupId = group.id;
              final name = group['name'];
              final total = group['total'] ?? 0;

              if (isSelectionMode) {
                return GestureDetector(
                  onLongPress: () => toggleSelection(groupId),
                  child: CheckboxListTile(
                    value: selectedGroupIds.contains(groupId),
                    title: Text(name),
                    subtitle: Text("Total: ₹$total"),
                    onChanged: (_) => toggleSelection(groupId),
                  ),
                );
              }

              return Dismissible(
                key: Key(groupId),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Delete Group"),
                      content: const Text("Are you sure you want to delete this group?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
                      ],
                    ),
                  );
                },
                onDismissed: (_) async {
                  await FirebaseFirestore.instance.collection('groups').doc(groupId).delete();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Group '$name' deleted")));
                },
                child: ListTile(
                  title: Text(name),
                  subtitle: Text("Total: ₹$total"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
                    );
                  },
                  onLongPress: () {
                    setState(() {
                      isSelectionMode = true;
                      selectedGroupIds.add(groupId);
                    });
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isSelectionMode
          ? null
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'joinGroupBtn',
            backgroundColor: Colors.blue,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JoinGroupScreen()),
              );
            },
            icon: const Icon(Icons.group_add),
            label: const Text("Join Group"),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'createGroupBtn',
            child: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

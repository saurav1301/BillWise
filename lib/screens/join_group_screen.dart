import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final TextEditingController _groupIdController = TextEditingController();
  bool _loading = false;
  String? _message;

  Future<void> _joinGroup() async {
    final groupId = _groupIdController.text.trim();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (groupId.isEmpty || uid == null) return;

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final doc = await FirebaseFirestore.instance.collection('groups').doc(groupId).get();
      if (!doc.exists) {
        setState(() {
          _message = "❌ Group not found.";
        });
      } else {
        final members = List<String>.from(doc['members'] ?? []);
        if (!members.contains(uid)) {
          members.add(uid);
          await doc.reference.update({'members': members});
          setState(() {
            _message = "✅ Joined group successfully!";
          });
        } else {
          setState(() {
            _message = "⚠️ You are already a member of this group.";
          });
        }
      }
    } catch (e) {
      setState(() {
        _message = "❌ Error: $e";
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Join a Group")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _groupIdController,
              decoration: const InputDecoration(
                labelText: "Enter Group ID",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
              onPressed: _joinGroup,
              icon: const Icon(Icons.group_add),
              label: const Text("Join Group"),
            ),
            const SizedBox(height: 20),
            if (_message != null)
              Text(
                _message!,
                style: TextStyle(
                  color: _message!.startsWith("✅")
                      ? Colors.green
                      : _message!.startsWith("⚠️")
                      ? Colors.orange
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

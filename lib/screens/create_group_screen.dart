import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _membersController = TextEditingController();

  bool _loading = false;

  void _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) throw Exception("User not logged in");

      final groupName = _groupNameController.text.trim();
      final rawMembers = _membersController.text.split(',');

      // ✅ Filter valid UIDs (Firebase UID is usually 28 chars)
      final members = rawMembers
          .map((e) => e.trim())
          .where((e) => e.length >= 20) // Avoid dummy inputs like '1'
          .toSet()
          .toList();

      if (!members.contains(uid)) members.add(uid);

      await FirebaseFirestore.instance.collection('groups').add({
        'name': groupName,
        'members': members,
        'total': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Group created successfully!")),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint("🔥 Error creating group: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to create group: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Group")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(labelText: "Group Name"),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter group name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _membersController,
                decoration: const InputDecoration(
                  labelText: "Member UIDs (comma separated)",
                  hintText: "e.g. abc123xyz456",
                ),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _createGroup,
                child: const Text("Create Group"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

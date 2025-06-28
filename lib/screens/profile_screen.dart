import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool isEditing = false;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _nameController.text = user?.displayName ?? '';
    _emailController.text = user?.email ?? '';
  }

  Future<void> _updateProfile() async {
    try {
      await user?.updateDisplayName(_nameController.text.trim());

      setState(() {
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoURL = user?.photoURL != null ? NetworkImage(user!.photoURL!) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Profile"),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (isEditing) {
                _updateProfile();
              } else {
                setState(() => isEditing = true);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: photoURL,
                  child: photoURL == null ? const Icon(Icons.person, size: 50) : null,
                ),
              ),
              const SizedBox(height: 24),
              if (!isEditing) ...[
                Text("Name: ${_nameController.text}", style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 12),
                Text("Email: ${_emailController.text}", style: const TextStyle(fontSize: 16)),
              ] else ...[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  await AuthService().signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text("Sign Out"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

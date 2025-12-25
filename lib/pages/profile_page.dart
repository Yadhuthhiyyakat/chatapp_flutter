import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _photoUrlController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (currentUser != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _bioController.text = data['bio'] ?? '';
          _photoUrlController.text = data['photoUrl'] ?? '';
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .set({
              'uid': currentUser!.uid,
              'email': currentUser!.email,
              'bio': _bioController.text.trim(),
              'photoUrl': _photoUrlController.text.trim(),
            }, SetOptions(merge: true));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error updating profile: $e")));
        }
      }
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.deepPurple.shade100,
              backgroundImage: _photoUrlController.text.isNotEmpty
                  ? (_photoUrlController.text.startsWith('http')
                        ? NetworkImage(_photoUrlController.text)
                        : FileImage(File(_photoUrlController.text))
                              as ImageProvider)
                  : null,
              onBackgroundImageError: _photoUrlController.text.isNotEmpty
                  ? (_, __) {}
                  : null,
              child: _photoUrlController.text.isEmpty
                  ? const Icon(Icons.person, size: 50, color: Colors.deepPurple)
                  : null,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: "Bio",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info_outline),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _photoUrlController,
              decoration: InputDecoration(
                labelText: "Photo URL",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.link),
                helperText: "Enter a direct link to an image",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: () async {
                    final ClipboardData? data = await Clipboard.getData(
                      Clipboard.kTextPlain,
                    );
                    if (data != null && data.text != null) {
                      if (mounted) {
                        setState(() {
                          _photoUrlController.text = data.text!;
                          _photoUrlController.selection =
                              TextSelection.fromPosition(
                                TextPosition(
                                  offset: _photoUrlController.text.length,
                                ),
                              );
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Link pasted!")),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Clipboard is empty")),
                        );
                      }
                    }
                  },
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Save Changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

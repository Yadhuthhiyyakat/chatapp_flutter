import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignOutButton extends StatelessWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        FirebaseAuth.instance.signOut();
      },
      icon: const Icon(Icons.logout),
      label: const Text('Sign Out'),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../pages/sign_out_button.dart';
import '../pages/chat_page.dart';
import '../pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ChatService _chatService = ChatService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.initNotifications();
    _chatService.saveUserToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Messages",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            icon: const Icon(Icons.person),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: SignOutButton(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Text("Error");
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          return ListView(
            children: snapshot.data!.docs
                .map<Widget>((doc) => _buildUserListItem(context, doc))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildUserListItem(BuildContext context, DocumentSnapshot document) {
    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

    if (data['email'] == null || data['uid'] == null) {
      return const SizedBox.shrink();
    }

    if (FirebaseAuth.instance.currentUser!.email != data['email']) {
      final String? photoUrl = data['photoUrl'];
      final String? bio = data['bio'];
      final String email = data['email'];
      final String displayName =
          data['displayName'] ?? data['username'] ?? email.split('@')[0];
      final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final String otherUserId = data['uid'];

      // Construct chat room ID
      List<String> ids = [currentUserId, otherUserId];
      ids.sort();
      String chatRoomId = ids.join('_');

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chat_rooms')
                .doc(chatRoomId)
                .collection('messages')
                .where('senderId', isEqualTo: otherUserId)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                unreadCount = snapshot.data!.docs.length;
              }

              return ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.deepPurple.shade100,
                  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                      ? NetworkImage(photoUrl)
                      : null,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? Text(
                          email[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: Text(
                  bio ?? "Hey there! I'm using Chat App.",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: unreadCount > 0
                    ? CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.red,
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.deepPurple,
                      ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        receiverUserEmail: data['email'],
                        receiverUserID: data['uid'],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

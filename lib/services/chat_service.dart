import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class ChatService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SEND MESSAGE
  Future<void> sendMessage(String receiverId, String message) async {
    // get current user info
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email.toString();
    final Timestamp timestamp = Timestamp.now();

    // create a new message
    Map<String, dynamic> newMessage = {
      'senderId': currentUserId,
      'senderEmail': currentUserEmail,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'isRead': false,
    };

    // construct chat room id from current user id and receiver id (sorted to ensure uniqueness)
    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    // add new message to database
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage);
  }

  // GET MESSAGES
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // DELETE MESSAGE
  Future<void> deleteMessage(String receiverId, String messageId) async {
    try {
      final String currentUserId = _auth.currentUser!.uid;
      List<String> ids = [currentUserId, receiverId];
      ids.sort();
      String chatRoomId = ids.join("_");

      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      debugPrint("Error deleting message: $e");
    }
  }

  // DELETE SELECTED MESSAGES
  Future<void> deleteSelectedMessages(
    String receiverId,
    List<String> messageIds,
  ) async {
    try {
      final String currentUserId = _auth.currentUser!.uid;
      List<String> ids = [currentUserId, receiverId];
      ids.sort();
      String chatRoomId = ids.join("_");

      WriteBatch batch = _firestore.batch();
      for (String messageId in messageIds) {
        batch.delete(
          _firestore
              .collection('chat_rooms')
              .doc(chatRoomId)
              .collection('messages')
              .doc(messageId),
        );
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Error deleting selected messages: $e");
    }
  }

  // SAVE USER TOKEN
  Future<void> saveUserToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'fcmToken': token,
      });
    }
  }

  // REQUEST NOTIFICATION PERMISSION
  Future<void> requestNotificationPermission() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }
}

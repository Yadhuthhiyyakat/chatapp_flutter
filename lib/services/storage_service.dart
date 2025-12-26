import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Safely deletes the old profile image, ignoring "object-not-found" errors.
  Future<void> deleteOldProfileImage(String? oldImageUrl) async {
    if (oldImageUrl == null || oldImageUrl.isEmpty) return;

    // Prevent crashing if the URL is not a Firebase Storage URL (e.g. Google Auth photo)
    if (!oldImageUrl.contains('firebasestorage.googleapis.com')) return;

    try {
      // Create a reference from the old URL
      final ref = _storage.refFromURL(oldImageUrl);

      // Attempt to delete
      await ref.delete();
    } catch (e) {
      // Catch ALL errors (Object not found, Invalid URL, Permissions).
      // We don't want to crash the app just because we couldn't delete an old file.
      print('Warning: Failed to delete old profile image: $e');
    }
  }

  // Uploads a new profile image and returns the download URL.
  Future<String> uploadNewProfileImage(String userId, File imageFile) async {
    // 1. Create the reference
    final ref = _storage.ref().child('user_images').child('$userId.jpg');

    // 2. Perform the upload and AWAIT it
    await ref.putFile(imageFile);

    // 3. Now it is safe to get the URL
    final url = await ref.getDownloadURL();
    return url;
  }
}

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_wonder_model.dart';

class WonderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Upload image to Firebase Storage
  Future<String?> _uploadImage(File imageFile, String wonderId) async {
    if (_userId == null) return null;

    try {
      // Configure reference to specific bucket wonders-832b0.appspot.com
      final storageRef = _storage.ref();
      print('Storage bucket: ${_storage.bucket}');

      // Create nested path for better organization
      // Format: wonder_images/userId/wonderId.jpg
      final imgRef = storageRef
          .child('wonder_images')
          .child(_userId!)
          .child('$wonderId.jpg');

      print('Uploading to path: ${imgRef.fullPath}');

      // Set metadata with content type for proper browser handling
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': _userId!,
          'wonderId': wonderId,
          'uploadTime': DateTime.now().toIso8601String(),
        },
      );

      // Create upload task
      final uploadTask = imgRef.putFile(imageFile, metadata);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });

      // Wait for upload completion
      final snapshot = await uploadTask.whenComplete(() {});

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('Upload successful! URL: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}');
        print('Firebase error message: ${e.message}');
      }
      return null;
    }
  }

  // Create a new wonder with image
  Future<String> createWonder({
    required String name,
    required String description,
    File? imageFile,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? plannedVisitDate,
  }) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    // Create document with auto-generated ID
    final docRef = _firestore.collection('user_wonders').doc();
    final wonderId = docRef.id;

    // Upload image if provided
    String? imageUrl;
    if (imageFile != null) {
      try {
        imageUrl = await _uploadImage(imageFile, wonderId);
        print(
          'Image upload result: ${imageUrl != null ? 'Success' : 'Failed'}',
        );
      } catch (e) {
        print('Error uploading image: $e');
        // Continue without image if upload fails
      }
    }

    // Create wonder model
    final wonder = UserWonderModel(
      id: wonderId,
      userId: _userId!,
      name: name,
      description: description,
      imageUrl: imageUrl,
      location: location,
      latitude: latitude,
      longitude: longitude,
      plannedVisitDate: plannedVisitDate,
      createdAt: DateTime.now(),
      isCompleted: false,
    );

    // Save to Firestore
    await docRef.set(wonder.toJson());
    return wonderId;
  }

  // Update an existing wonder
  Future<void> updateWonder({
    required String wonderId,
    required String name,
    required String description,
    File? imageFile,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? plannedVisitDate,
    bool? isCompleted,
  }) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    // Get existing wonder
    final existing = await getUserWonder(wonderId);
    if (existing == null || existing.userId != _userId) {
      throw Exception('Wonder not found or not authorized');
    }

    // Prepare updates
    Map<String, dynamic> updates = {
      'name': name,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'plannedVisitDate': plannedVisitDate?.millisecondsSinceEpoch,
    };

    // Handle completion status
    if (isCompleted != null && isCompleted != existing.isCompleted) {
      updates['isCompleted'] = isCompleted;
      if (isCompleted) {
        updates['completedDate'] = DateTime.now().millisecondsSinceEpoch;
      } else {
        updates['completedDate'] = null;
      }
    }

    // Handle new image upload if provided
    if (imageFile != null) {
      String? imageUrl = await _uploadImage(imageFile, wonderId);
      if (imageUrl != null) {
        updates['imageUrl'] = imageUrl;
      }
    }

    // Update Firestore
    await _firestore.collection('user_wonders').doc(wonderId).update(updates);
  }

  // Delete wonder and its image
  Future<void> deleteWonder(String wonderId) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    // Get wonder to check ownership and get image URL
    final wonder = await getUserWonder(wonderId);
    if (wonder == null || wonder.userId != _userId) {
      throw Exception('Wonder not found or not authorized');
    }

    // Delete image if exists
    if (wonder.imageUrl != null) {
      try {
        // Two ways to handle image deletion:

        // Option 1: Using URL reference (might fail if URL is tokenized)
        // final ref = _storage.refFromURL(wonder.imageUrl!);

        // Option 2: Using path reference (more reliable)
        final ref = _storage
            .ref()
            .child('wonder_images')
            .child(_userId!)
            .child('$wonderId.jpg');

        await ref.delete();
        print('Image deleted successfully');
      } catch (e) {
        print('Error deleting image: $e');
        // Continue deletion even if image deletion fails
      }
    }

    // Delete document from Firestore
    await _firestore.collection('user_wonders').doc(wonderId).delete();
  }

  // Get all user wonders
  Stream<List<UserWonderModel>> getUserWonders() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('user_wonders')
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserWonderModel.fromJson(doc.id, doc.data()))
              .toList();
        });
  }

  // Get specific wonder by ID
  Future<UserWonderModel?> getUserWonder(String wonderId) async {
    if (_userId == null) return null;

    final doc = await _firestore.collection('user_wonders').doc(wonderId).get();

    if (!doc.exists || doc.data()?['userId'] != _userId) {
      return null;
    }

    return UserWonderModel.fromJson(doc.id, doc.data()!);
  }
}

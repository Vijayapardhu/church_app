import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer' as developer;
import 'dart:io';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Daily Inspiration
  Stream<DocumentSnapshot> getDailyInspiration() {
    return _firestore.collection('daily_inspiration').doc('today').snapshots();
  }

  // Create user profile
  Future<void> createUserProfile({
    required String name,
    required List<String> familyMembers,
    required String phone,
    required String village,
    File? profileImage,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    String? profileImageUrl;
    if (profileImage != null) {
      final ref = _storage.ref().child('profile_images/${user.uid}');
      await ref.putFile(profileImage);
      profileImageUrl = await ref.getDownloadURL();
    }

    // Check if user already exists and get their current role
    final existingUser = await _firestore.collection('users').doc(user.uid).get();
    final currentRole = (existingUser.exists && existingUser.data() != null && existingUser.data()!['role'] != null)
      ? existingUser.data()!['role']
      : null;

    await _firestore.collection('users').doc(user.uid).set({
      'name': name,
      'familyMembers': familyMembers,
      'phone': phone,
      'village': village,
      'role': currentRole ?? 'member',
      'profileImageUrl': profileImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get user profile
  Future<DocumentSnapshot> getUserProfile(String userId) async {
    return await _firestore.collection('users').doc(userId).get();
  }

  // Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  // Prayers
  Future<void> submitPrayer(String title, String message, String userId) async {
    try {
      await _firestore.collection('prayers').add({
        'title': title,
        'message': message,
        'userId': userId,
        'status': 'pending',
        'date': FieldValue.serverTimestamp(),
      });
      developer.log('Prayer submitted successfully');
    } catch (e) {
      developer.log('Error submitting prayer: $e', error: e);
      rethrow;
    }
  }

  Future<void> approvePrayer(String prayerId) async {
    try {
      await _firestore.collection('prayers').doc(prayerId).update({
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
      });
      developer.log('Prayer approved successfully');
    } catch (e) {
      developer.log('Error approving prayer: $e', error: e);
      rethrow;
    }
  }

  Stream<QuerySnapshot> getApprovedPrayers() {
    developer.log('Fetching approved prayers');
    try {
      return _firestore.collection('prayers')
        .where('status', isEqualTo: 'approved')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          developer.log('Received ${snapshot.docs.length} approved prayers');
          return snapshot;
        });
    } catch (e) {
      developer.log('Error in getApprovedPrayers: $e', error: e);
      // If there's an index error, fall back to a simpler query
      if (e.toString().contains('failed-precondition')) {
        developer.log('Falling back to simple query without ordering');
        return _firestore.collection('prayers')
          .where('status', isEqualTo: 'approved')
          .snapshots()
          .map((snapshot) {
            developer.log('Received ${snapshot.docs.length} approved prayers (fallback)');
            return snapshot;
          });
      }
      rethrow;
    }
  }

  Stream<QuerySnapshot> getPendingPrayers() {
    try {
      return _firestore.collection('prayers')
        .where('status', isEqualTo: 'pending')
        .orderBy('date', descending: true)
        .snapshots();
    } catch (e) {
      developer.log('Error in getPendingPrayers: $e', error: e);
      // If there's an index error, fall back to a simpler query
      if (e.toString().contains('failed-precondition')) {
        return _firestore.collection('prayers')
          .where('status', isEqualTo: 'pending')
          .snapshots();
      }
      rethrow;
    }
  }

  Future<void> updatePrayerStatus(String prayerId, String status) async {
    try {
      await _firestore.collection('prayers').doc(prayerId).update({
        'status': status,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
      developer.log('Prayer status updated to $status');
    } catch (e) {
      developer.log('Error updating prayer status: $e', error: e);
      rethrow;
    }
  }

  // Gallery
  Stream<QuerySnapshot> getGalleryItems() {
    return _firestore.collection('gallery').orderBy('date', descending: true).snapshots();
  }

  // Get Bible verse of the day
  Stream<DocumentSnapshot> getBibleVerse() {
    return _firestore
        .collection('bible_verses')
        .doc('daily')
        .snapshots();
  }

  // Get pastor's message
  Stream<DocumentSnapshot> getPastorMessage() {
    return _firestore
        .collection('pastor_messages')
        .doc('latest')
        .snapshots();
  }

  // Prayer Requests
  Stream<QuerySnapshot> getPrayerRequests() {
    return _firestore
        .collection('prayer_requests')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> addPrayerRequest(String title, String description, String? imageUrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['name'] ?? 'Anonymous';

    await _firestore.collection('prayer_requests').add({
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'userId': user.uid,
      'userName': userName,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePrayerRequest(
    String prayerId,
    String title,
    String description,
    String? imageUrl,
  ) async {
    await _firestore.collection('prayer_requests').doc(prayerId).update({
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePrayerRequest(String prayerId) async {
    await _firestore.collection('prayer_requests').doc(prayerId).delete();
  }

  Stream<QuerySnapshot> getSongs() {
    return _firestore
        .collection('songs')
        .orderBy('title')
        .snapshots();
  }
} 
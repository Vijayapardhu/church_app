import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
    clientId: '30594640113-3fpcdjjfb4qoil4m2bfi5mdueogcfgc7.apps.googleusercontent.com',
  );
  User? user;
  bool isLoading = true;
  String? error;

  AuthService() {
    _auth.authStateChanges().listen((u) {
      user = u;
      isLoading = false;
      notifyListeners();
      if (u != null) _saveUserToFirestore(u);
    });
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      // Sign out first to ensure a fresh sign-in attempt
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        print('Error during sign out: $e');
      }
      try {
        await _auth.signOut();
      } catch (e) {
        print('Error during auth sign out: $e');
      }

      if (kIsWeb) {
        // Web platform
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('https://www.googleapis.com/auth/userinfo.email');
        googleProvider.addScope('https://www.googleapis.com/auth/userinfo.profile');
        
        try {
          final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
          user = userCredential.user;
          if (user != null) {
            await _saveUserToFirestore(user!);
          }
          return userCredential;
        } catch (e) {
          print('Error during web Google sign in: $e');
          await _auth.signInWithRedirect(googleProvider);
          return null;
        }
      } else {
        // Mobile platforms
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          error = 'Sign in aborted by user';
          isLoading = false;
          notifyListeners();
          return null;
        }

        try {
          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          final UserCredential userCredential = await _auth.signInWithCredential(credential);
          user = userCredential.user;
          if (user != null) {
            await _saveUserToFirestore(user!);
          }
          return userCredential;
        } catch (e) {
          print('Error during Google authentication: $e');
          error = 'Authentication failed. Please try again.';
          try {
            await _googleSignIn.signOut();
          } catch (e) {
            print('Error during cleanup: $e');
          }
          throw Exception('Authentication failed');
        }
      }
    } catch (e) {
      error = 'Sign in failed. Please try again.';
      print('Error during Google sign in: $e');
      throw Exception('Sign in failed');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      isLoading = true;
      notifyListeners();
      
      if (!kIsWeb) {
        try {
          await _googleSignIn.signOut();
        } catch (e) {
          print('Error during Google sign out: $e');
        }
      }
      await _auth.signOut();
      user = null;
    } catch (e) {
      error = 'Sign out failed';
      print('Error during sign out: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveUserToFirestore(User user) async {
    try {
      final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await doc.set({
        'name': user.displayName,
        'email': user.email,
        'photoURL': user.photoURL,
        'uid': user.uid,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving user to Firestore: $e');
    }
  }
}

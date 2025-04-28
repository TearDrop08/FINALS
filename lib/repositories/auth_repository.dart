import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Replace with your actual Web OAuth client ID
  static const _webClientId = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';

  Future<User?> signInWithGoogle() async {
    // 1) Kick off Google sign‐in
    final googleSignIn = kIsWeb
        ? GoogleSignIn(
            clientId: _webClientId,
            scopes: ['email'],
          )
        : GoogleSignIn(scopes: ['email']);

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign‐in was cancelled');
    }

    // 2) Domain check
    final email = googleUser.email;
    if (!email.endsWith('@addu.edu.ph')) {
      await googleSignIn.signOut();
      throw Exception('Please sign in with your addu.edu.ph account');
    }

    // 3) Firebase credential
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken:     googleAuth.idToken,
    );
    final userCred = await _auth.signInWithCredential(credential);
    final user     = userCred.user;
    if (user == null) {
      throw Exception('Firebase authentication failed');
    }

    // 4) Admin‐list check in Firestore
    final adminDoc = await FirebaseFirestore.instance
        .collection('admins')
        .doc(email)
        .get();

    if (!adminDoc.exists) {
      // not an admin → sign out everywhere
      await googleSignIn.signOut();
      await _auth.signOut();
      throw Exception('You are not an admin');
    }

    // OK!
    return user;
  }

  Future<void> signOut() async {
    if (kIsWeb) {
      await GoogleSignIn(clientId: _webClientId).signOut();
    } else {
      await GoogleSignIn().signOut();
    }
    await _auth.signOut();
  }
}
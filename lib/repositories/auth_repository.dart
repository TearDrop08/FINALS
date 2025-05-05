import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User> signInWithGoogle() async {
    UserCredential userCred;

    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      userCred = await _auth.signInWithPopup(provider);
    } else {
      final googleUser = await GoogleSignIn(scopes: ['email']).signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      }
      final googleAuth = await googleUser.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      userCred = await _auth.signInWithCredential(cred);
    }

    final user = userCred.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'ERROR_USER_NULL',
        message: 'Firebase authentication failed',
      );
    }

    if (!user.email!.endsWith('@addu.edu.ph')) {
      await signOut();
      throw FirebaseAuthException(
        code: 'ERROR_INVALID_DOMAIN',
        message: 'Please sign in with your @addu.edu.ph account',
      );
    }

    final adminDoc = await FirebaseFirestore.instance
        .collection('admins')
        .doc(user.email)
        .get();
    if (!adminDoc.exists) {
      await signOut();
      throw FirebaseAuthException(
        code: 'ERROR_NOT_ADMIN',
        message: 'You are not an admin',
      );
    }

    return user;
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ✅ Google Sign-In
  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user;

      // ✅ Save user info to Firestore
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'name': user.displayName ?? '',
          'phone': user.phoneNumber ?? '',
        }, SetOptions(merge: true));
      }

      return user;
    } catch (e) {
      print("❌ Google Sign-In failed: $e");
      return null;
    }
  }

  // ✅ Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut(); // optional, removes Google session
      await _auth.signOut();
    } catch (e) {
      print("❌ Sign out failed: $e");
    }
  }

  // ✅ Optional helper: Get current user
  User? get currentUser => _auth.currentUser;
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Sign Up with Email and Password
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      User? user = result.user;
      
      // Save user details to Firestore
      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name.trim(),
          'email': email.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return {'success': true, 'user': user};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': e.message ?? 'An error occurred during registration'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Login with Email and Password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return {'success': true, 'user': result.user};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': e.message ?? 'Login failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get User Profile from Firestore
  Future<DocumentSnapshot?> getUserProfile(String uid) async {
    try {
      return await _db.collection('users').doc(uid).get();
    } catch (e) {
      print(e);
      return null;
    }
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db   = FirebaseFirestore.instance;


  static Future<String?> signUp(String name, String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      await cred.user!.updateDisplayName(name);

      await cred.user!.sendEmailVerification();

      await _db.collection('users').doc(cred.user!.uid).set({
        'name'      : name,
        'email'     : email,
        'created_at': DateTime.now().toIso8601String(),
        'currentProject': {
          'title'    : 'Build a Portfolio Website',
          'desc'     : 'Create a responsive portfolio with HTML, CSS and JavaScript.',
          'dueInDays': 7,
          'progress' : 0.0,
        },
      });
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'Email already registered.';
      return e.message ?? 'Sign up failed.';
    } catch (e) {
      return 'Sign up failed: $e';
    }
  }

  static Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found')  return 'No account found. Please sign up.';
      if (e.code == 'wrong-password')  return 'Incorrect password.';
      return e.message ?? 'Login failed.';
    } catch (e) {
      return 'Login failed: $e';
    }
  }

  static Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'No account found with this email.';
      return e.message ?? 'Failed to send reset email.';
    } catch (e) {
      return 'Error: $e';
    }
  }


  static Future<void> logout() async {
    await _auth.signOut(); // clears Firebase token + local session
  }

  static Future<bool> updateUser(int id, Map<String, dynamic> data) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      if (data.containsKey('name')) {
        await user.updateDisplayName(data['name']);
      }
      if (data.containsKey('email')) {
        await user.verifyBeforeUpdateEmail(data['email']);
      }
      await _db.collection('users').doc(user.uid).update(data);
      return true;
    } catch (e) {
      return false;
    }
  }


  static Future<bool> deleteUser(int id) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      await _db.collection('users').doc(user.uid).delete();
      await user.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final snap = await _db.collection('users').where('email', isEqualTo: email).get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data();
  }

  static Future<bool>   isLoggedIn()   async => _auth.currentUser != null;
  static Future<String> getUserName()  async => _auth.currentUser?.displayName ?? 'Guest';
  static Future<String> getUserEmail() async => _auth.currentUser?.email ?? '';
  static Future<int?>   getUserId()    async => null;
  static String?        getUid()              => _auth.currentUser?.uid;

  static String getInitial(String name) => name.isNotEmpty ? name[0].toUpperCase() : 'G';


  static Future<void> printAllUsers() async {
    final snap = await _db.collection('users').get();
    for (final doc in snap.docs) print('👤 ${doc.id}: ${doc.data()}');
  }
}
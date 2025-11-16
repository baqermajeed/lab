import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:farah_new_lab/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<AppUser?> getCurrentUserProfile() async {
    final current = _auth.currentUser;
    if (current == null) return null;
    final doc = await _db.collection('users').doc(current.uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.id, doc.data()!);
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> ensureUserDoc(User user, {required String role}) async {
    final ref = _db.collection('users').doc(user.uid);
    await ref.set({
      'displayName': user.displayName ?? '',
      'email': (user.email ?? '').toLowerCase(),
      'role': role,
      'entryMode': 'app', // الافتراضي: الإدخال من التطبيق
    }, SetOptions(merge: true));
  }

  Future<void> ensureUserDocIfAbsent(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    final email = (user.email ?? '').toLowerCase();
    final role = email == 'manager@farahlab.com' ? 'manager' : 'employee';
    await ref.set({
      'displayName': user.displayName ?? '',
      'email': email,
      'role': role,
      'entryMode': 'app',
    });
  }
}

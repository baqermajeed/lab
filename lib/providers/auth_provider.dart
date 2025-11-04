import 'dart:async';

import 'package:farah_new_lab/models/user_model.dart';
import 'package:farah_new_lab/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider(this._authService) {
    _sub = _authService.authStateChanges().listen(_onAuthChanged);
  }

  AppUser? currentUser;
  bool loading = true;
  StreamSubscription<fb.User?>? _sub;

  Future<void> _onAuthChanged(fb.User? user) async {
    if (user == null) {
      currentUser = null;
      loading = false;
      notifyListeners();
      return;
    }
    currentUser = await _authService.getCurrentUserProfile();
    loading = false;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    loading = true;
    notifyListeners();
    try {
      final cred = await _authService.signInWithEmail(email, password);
      if (cred.user != null) {
        await _authService.ensureUserDocIfAbsent(cred.user!);
        // حمل البروفايل مباشرة لتحديث الواجهة بسرعة
        currentUser = await _authService.getCurrentUserProfile();
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:farah_new_lab/firebase_options.dart';

class SeedUser {
  final String displayName;
  final String email;
  final String password;
  final String role; // 'manager' or 'employee'

  const SeedUser({
    required this.displayName,
    required this.email,
    required this.password,
    required this.role,
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final users = <SeedUser>[
    const SeedUser(
      displayName: 'المدير',
      email: 'manager@farahlab.com',
      password: 'Farah123!',
      role: 'manager',
    ),
    const SeedUser(
      displayName: 'موظف 1',
      email: 'employee1@farahlab.com',
      password: 'Farah123!',
      role: 'employee',
    ),
    const SeedUser(
      displayName: 'موظف 2',
      email: 'employee2@farahlab.com',
      password: 'Farah123!',
      role: 'employee',
    ),
    const SeedUser(
      displayName: 'موظف 3',
      email: 'employee3@farahlab.com',
      password: 'Farah123!',
      role: 'employee',
    ),
    const SeedUser(
      displayName: 'موظف 4',
      email: 'employee4@farahlab.com',
      password: 'Farah123!',
      role: 'employee',
    ),
    const SeedUser(
      displayName: 'موظف 5',
      email: 'employee5@farahlab.com',
      password: 'Farah123!',
      role: 'employee',
    ),
    const SeedUser(
      displayName: 'موظف 6',
      email: 'employee6@farahlab.com',
      password: 'Farah123!',
      role: 'employee',
    ),
  ];

  final auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;

  for (final u in users) {
    try {
      // Sign out just in case a session is active
      if (auth.currentUser != null) {
        await auth.signOut();
      }

      final cred = await auth.createUserWithEmailAndPassword(
        email: u.email,
        password: u.password,
      );

      if (cred.user != null) {
        await cred.user!.updateDisplayName(u.displayName);
        await db.collection('users').doc(cred.user!.uid).set({
          'displayName': u.displayName,
          'email': u.email,
          'role': u.role,
        }, SetOptions(merge: true));
        // Print to console for confirmation
        // ignore: avoid_print
        print('Created: ${u.email} (${u.role})');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // ignore: avoid_print
        print('Exists: ${u.email}');
      } else {
        // ignore: avoid_print
        print('Error creating ${u.email}: ${e.code} ${e.message}');
      }
    }
  }

  // Done
  // ignore: avoid_print
  print('Seeding finished.');
  exit(0);
}

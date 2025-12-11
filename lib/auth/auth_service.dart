import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Use correct regional DB URL
  final DatabaseReference _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://unibazaar-73dd2-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  Future<User?> signUpWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) return null;

    // 🔥 IMPORTANT — update FirebaseAuth display name
    await user.updateDisplayName(name);
    await user.reload();

    // 🔥 Now save the profile in Realtime Database
    await _db.child('users').child(user.uid).set({
      'name': name,
      'email': email,
      'phone': phone,
      'createdAt': DateTime.now().toIso8601String(),
    });

    return user;
  }

  Future<User?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}

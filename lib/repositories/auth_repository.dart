import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aicu/models/app_user.dart';

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  AuthRepository({required this.auth, required this.firestore});

  Future<AppUser> signIn(String email, String password) async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    final doc = await firestore.collection('users').doc(uid).get();
    return AppUser.fromMap(uid, doc.data()!);
  }

  Stream<String?> currentUserRole() {
    final uid = auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data()?['role'] as String?);
  }
}

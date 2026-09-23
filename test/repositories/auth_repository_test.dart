import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aicu/repositories/auth_repository.dart';

void main() {
  test('signIn returns AppUser with role from Firestore', () async {
    final firestore = FakeFirebaseFirestore();
    final mockUser = MockUser(uid: 'u1', email: 'nurse@aicu.test');
    final auth = MockFirebaseAuth(mockUser: mockUser, signedIn: false);
    await firestore.collection('users').doc('u1').set({
      'email': 'nurse@aicu.test',
      'role': 'nurse',
    });

    final repo = AuthRepository(auth: auth, firestore: firestore);
    final user = await repo.signIn('nurse@aicu.test', 'password123');

    expect(user.uid, 'u1');
    expect(user.role, 'nurse');
  });
}

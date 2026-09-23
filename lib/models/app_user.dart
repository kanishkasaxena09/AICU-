class AppUser {
  final String uid;
  final String email;
  final String role; // "nurse" | "doctor"
  const AppUser({required this.uid, required this.email, required this.role});

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
        uid: uid,
        email: map['email'] as String,
        role: map['role'] as String,
      );
}

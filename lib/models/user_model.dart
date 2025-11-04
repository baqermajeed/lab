class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final String role; // 'manager' or 'employee'

  AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'displayName': displayName,
    'email': email,
    'role': role,
  };

  static AppUser fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'employee',
    );
  }
}

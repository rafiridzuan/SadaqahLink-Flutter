class UserModel {
  final String uid;
  final String email;
  final String name; // Username
  final String fullname;
  final String role; // 'admin' | 'ajk'

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.fullname,
    required this.role,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      fullname: map['fullname'] ?? '',
      role: map['role'] ?? 'ajk', // Default to ajk if not specified
    );
  }

  Map<String, dynamic> toMap() {
    return {'email': email, 'name': name, 'fullname': fullname, 'role': role};
  }
}

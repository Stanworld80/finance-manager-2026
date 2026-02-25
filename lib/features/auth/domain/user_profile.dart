class UserProfile {
  final String uid;
  final String email;
  final String? displayName;

  UserProfile({required this.uid, required this.email, this.displayName});

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'email': email, 'displayName': displayName};
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
    );
  }
}

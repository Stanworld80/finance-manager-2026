import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers.dart';
import '../domain/user_profile.dart';

part 'user_repository.g.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore);

  Future<void> saveUserProfile(UserProfile profile) async {
    await _firestore
        .collection('users_public_profiles')
        .doc(profile.uid)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  Future<UserProfile?> findUserByEmail(String email) async {
    final query = await _firestore
        .collection('users_public_profiles')
        .where('email', isEqualTo: email.toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return UserProfile.fromMap(query.docs.first.data());
  }
}

@riverpod
UserRepository userRepository(Ref ref) {
  return UserRepository(ref.watch(firestoreProvider));
}

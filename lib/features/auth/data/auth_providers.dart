import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers.dart';
import '../domain/user_profile.dart';
import 'user_repository.dart';

part 'auth_providers.g.dart';

@riverpod
Stream<User?> authState(Ref ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
}

@riverpod
void userProfileSync(Ref ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user != null && user.email != null) {
    Future.microtask(() async {
      final repo = ref.read(userRepositoryProvider);
      final profile = UserProfile(
        uid: user.uid,
        email: user.email!,
        displayName: user.displayName,
      );
      await repo.saveUserProfile(profile);
    });
  }
}

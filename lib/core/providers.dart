import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'data/seed_service.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
FirebaseFirestore firestore(FirestoreRef ref) {
  return FirebaseFirestore.instance;
}

@Riverpod(keepAlive: true)
FirebaseAuth firebaseAuth(FirebaseAuthRef ref) {
  return FirebaseAuth.instance;
}

@Riverpod(keepAlive: true)
SeedService seedService(SeedServiceRef ref) {
  return SeedService(ref.watch(firestoreProvider));
}

@Riverpod(keepAlive: true)
Future<PackageInfo> packageInfo(PackageInfoRef ref) {
  return PackageInfo.fromPlatform();
}

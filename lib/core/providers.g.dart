// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firestoreHash() => r'e271f8f7be694ee819f397232f4d140c15a5f921';

/// See also [firestore].
@ProviderFor(firestore)
final firestoreProvider = Provider<FirebaseFirestore>.internal(
  firestore,
  name: r'firestoreProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$firestoreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirestoreRef = ProviderRef<FirebaseFirestore>;
String _$firebaseAuthHash() => r'46c40b7c5cf8ab936c0daa96a6af106bd2ae5d51';

/// See also [firebaseAuth].
@ProviderFor(firebaseAuth)
final firebaseAuthProvider = Provider<FirebaseAuth>.internal(
  firebaseAuth,
  name: r'firebaseAuthProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$firebaseAuthHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirebaseAuthRef = ProviderRef<FirebaseAuth>;
String _$seedServiceHash() => r'443b2f1ad1ee2e0fc77338b2a5095e65df7ea788';

/// See also [seedService].
@ProviderFor(seedService)
final seedServiceProvider = Provider<SeedService>.internal(
  seedService,
  name: r'seedServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$seedServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SeedServiceRef = ProviderRef<SeedService>;
String _$packageInfoHash() => r'f7bd90882137aac7a9f28e9d10eae6efeee8c9d0';

/// See also [packageInfo].
@ProviderFor(packageInfo)
final packageInfoProvider = FutureProvider<PackageInfo>.internal(
  packageInfo,
  name: r'packageInfoProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$packageInfoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PackageInfoRef = FutureProviderRef<PackageInfo>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

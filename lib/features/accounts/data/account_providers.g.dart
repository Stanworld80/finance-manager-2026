// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$realAccountsHash() => r'152372577c32162f57079f6f624d9ed82af9dcd2';

/// See also [realAccounts].
@ProviderFor(realAccounts)
final realAccountsProvider =
    AutoDisposeStreamProvider<List<RealAccount>>.internal(
      realAccounts,
      name: r'realAccountsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$realAccountsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RealAccountsRef = AutoDisposeStreamProviderRef<List<RealAccount>>;
String _$virtualAccountsHash() => r'ae8014cb362aeaf0c64a4526a1cf8b00626f655a';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [virtualAccounts].
@ProviderFor(virtualAccounts)
const virtualAccountsProvider = VirtualAccountsFamily();

/// See also [virtualAccounts].
class VirtualAccountsFamily extends Family<AsyncValue<List<VirtualAccount>>> {
  /// See also [virtualAccounts].
  const VirtualAccountsFamily();

  /// See also [virtualAccounts].
  VirtualAccountsProvider call(String realAccountId) {
    return VirtualAccountsProvider(realAccountId);
  }

  @override
  VirtualAccountsProvider getProviderOverride(
    covariant VirtualAccountsProvider provider,
  ) {
    return call(provider.realAccountId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'virtualAccountsProvider';
}

/// See also [virtualAccounts].
class VirtualAccountsProvider
    extends AutoDisposeStreamProvider<List<VirtualAccount>> {
  /// See also [virtualAccounts].
  VirtualAccountsProvider(String realAccountId)
    : this._internal(
        (ref) => virtualAccounts(ref as VirtualAccountsRef, realAccountId),
        from: virtualAccountsProvider,
        name: r'virtualAccountsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$virtualAccountsHash,
        dependencies: VirtualAccountsFamily._dependencies,
        allTransitiveDependencies:
            VirtualAccountsFamily._allTransitiveDependencies,
        realAccountId: realAccountId,
      );

  VirtualAccountsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.realAccountId,
  }) : super.internal();

  final String realAccountId;

  @override
  Override overrideWith(
    Stream<List<VirtualAccount>> Function(VirtualAccountsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: VirtualAccountsProvider._internal(
        (ref) => create(ref as VirtualAccountsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        realAccountId: realAccountId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<VirtualAccount>> createElement() {
    return _VirtualAccountsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VirtualAccountsProvider &&
        other.realAccountId == realAccountId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, realAccountId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin VirtualAccountsRef on AutoDisposeStreamProviderRef<List<VirtualAccount>> {
  /// The parameter `realAccountId` of this provider.
  String get realAccountId;
}

class _VirtualAccountsProviderElement
    extends AutoDisposeStreamProviderElement<List<VirtualAccount>>
    with VirtualAccountsRef {
  _VirtualAccountsProviderElement(super.provider);

  @override
  String get realAccountId => (origin as VirtualAccountsProvider).realAccountId;
}

String _$allVirtualAccountsHash() =>
    r'daad970b8877d4b13c6af741eb0fa0d90924eca3';

/// See also [allVirtualAccounts].
@ProviderFor(allVirtualAccounts)
final allVirtualAccountsProvider =
    AutoDisposeStreamProvider<List<VirtualAccount>>.internal(
      allVirtualAccounts,
      name: r'allVirtualAccountsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$allVirtualAccountsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllVirtualAccountsRef =
    AutoDisposeStreamProviderRef<List<VirtualAccount>>;
String _$autoRepairLibreHash() => r'1528fe782f692ffbbb338c51682df30fdbcae52c';

/// Automatically repairs Libre balance discrepancies whenever accounts load.
///
/// This provider watches `realAccountsProvider` (which already streams from
/// Firestore) and triggers a background repair pass the first time a non-empty
/// list arrives.  Each account's Libre envelope is patched silently if:
///   sum(all other envelopes) + Libre ≠ RealAccount.balance
///
/// The result (number of accounts repaired) is logged in debug builds but is
/// otherwise invisible to the user.
///
/// Copied from [autoRepairLibre].
@ProviderFor(autoRepairLibre)
final autoRepairLibreProvider = AutoDisposeFutureProvider<int>.internal(
  autoRepairLibre,
  name: r'autoRepairLibreProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$autoRepairLibreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AutoRepairLibreRef = AutoDisposeFutureProviderRef<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

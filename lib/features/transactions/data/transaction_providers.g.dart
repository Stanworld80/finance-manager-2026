// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recentTransactionsHash() =>
    r'74b32cb3fffbdc757a9bb7ec95f6d84fa9d13c85';

/// See also [recentTransactions].
@ProviderFor(recentTransactions)
final recentTransactionsProvider =
    AutoDisposeStreamProvider<List<TransactionModel>>.internal(
      recentTransactions,
      name: r'recentTransactionsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$recentTransactionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecentTransactionsRef =
    AutoDisposeStreamProviderRef<List<TransactionModel>>;
String _$transactionByIdHash() => r'74439927d8deca58375a49ba45799fda9c44e9c4';

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

/// See also [transactionById].
@ProviderFor(transactionById)
const transactionByIdProvider = TransactionByIdFamily();

/// See also [transactionById].
class TransactionByIdFamily extends Family<AsyncValue<TransactionModel?>> {
  /// See also [transactionById].
  const TransactionByIdFamily();

  /// See also [transactionById].
  TransactionByIdProvider call(String id) {
    return TransactionByIdProvider(id);
  }

  @override
  TransactionByIdProvider getProviderOverride(
    covariant TransactionByIdProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'transactionByIdProvider';
}

/// See also [transactionById].
class TransactionByIdProvider
    extends AutoDisposeStreamProvider<TransactionModel?> {
  /// See also [transactionById].
  TransactionByIdProvider(String id)
    : this._internal(
        (ref) => transactionById(ref as TransactionByIdRef, id),
        from: transactionByIdProvider,
        name: r'transactionByIdProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$transactionByIdHash,
        dependencies: TransactionByIdFamily._dependencies,
        allTransitiveDependencies:
            TransactionByIdFamily._allTransitiveDependencies,
        id: id,
      );

  TransactionByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    Stream<TransactionModel?> Function(TransactionByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TransactionByIdProvider._internal(
        (ref) => create(ref as TransactionByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<TransactionModel?> createElement() {
    return _TransactionByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionByIdProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TransactionByIdRef on AutoDisposeStreamProviderRef<TransactionModel?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _TransactionByIdProviderElement
    extends AutoDisposeStreamProviderElement<TransactionModel?>
    with TransactionByIdRef {
  _TransactionByIdProviderElement(super.provider);

  @override
  String get id => (origin as TransactionByIdProvider).id;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

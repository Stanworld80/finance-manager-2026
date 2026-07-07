// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$filteredAccountTransactionsHash() =>
    r'aa4c79c7d687adcb262d896659271e1f6cf60997';

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

/// See also [filteredAccountTransactions].
@ProviderFor(filteredAccountTransactions)
const filteredAccountTransactionsProvider = FilteredAccountTransactionsFamily();

/// See also [filteredAccountTransactions].
class FilteredAccountTransactionsFamily
    extends Family<AsyncValue<List<TransactionModel>>> {
  /// See also [filteredAccountTransactions].
  const FilteredAccountTransactionsFamily();

  /// See also [filteredAccountTransactions].
  FilteredAccountTransactionsProvider call(String realAccountId) {
    return FilteredAccountTransactionsProvider(realAccountId);
  }

  @override
  FilteredAccountTransactionsProvider getProviderOverride(
    covariant FilteredAccountTransactionsProvider provider,
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
  String? get name => r'filteredAccountTransactionsProvider';
}

/// See also [filteredAccountTransactions].
class FilteredAccountTransactionsProvider
    extends AutoDisposeStreamProvider<List<TransactionModel>> {
  /// See also [filteredAccountTransactions].
  FilteredAccountTransactionsProvider(String realAccountId)
    : this._internal(
        (ref) => filteredAccountTransactions(
          ref as FilteredAccountTransactionsRef,
          realAccountId,
        ),
        from: filteredAccountTransactionsProvider,
        name: r'filteredAccountTransactionsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$filteredAccountTransactionsHash,
        dependencies: FilteredAccountTransactionsFamily._dependencies,
        allTransitiveDependencies:
            FilteredAccountTransactionsFamily._allTransitiveDependencies,
        realAccountId: realAccountId,
      );

  FilteredAccountTransactionsProvider._internal(
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
    Stream<List<TransactionModel>> Function(
      FilteredAccountTransactionsRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FilteredAccountTransactionsProvider._internal(
        (ref) => create(ref as FilteredAccountTransactionsRef),
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
  AutoDisposeStreamProviderElement<List<TransactionModel>> createElement() {
    return _FilteredAccountTransactionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredAccountTransactionsProvider &&
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
mixin FilteredAccountTransactionsRef
    on AutoDisposeStreamProviderRef<List<TransactionModel>> {
  /// The parameter `realAccountId` of this provider.
  String get realAccountId;
}

class _FilteredAccountTransactionsProviderElement
    extends AutoDisposeStreamProviderElement<List<TransactionModel>>
    with FilteredAccountTransactionsRef {
  _FilteredAccountTransactionsProviderElement(super.provider);

  @override
  String get realAccountId =>
      (origin as FilteredAccountTransactionsProvider).realAccountId;
}

String _$recentTransactionsHash() =>
    r'da3d31cb7b71641f788e6a06fb23a5aac586ca63';

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
String _$transactionByIdHash() => r'3a12faa86f831c4a2e7cae38fd6f3d210c05ce2b';

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

String _$upcomingTransactionsHash() =>
    r'6ef7c560bd36d5753ddecf529bd3367a3a6758f2';

/// See also [upcomingTransactions].
@ProviderFor(upcomingTransactions)
final upcomingTransactionsProvider =
    AutoDisposeStreamProvider<List<TransactionModel>>.internal(
      upcomingTransactions,
      name: r'upcomingTransactionsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$upcomingTransactionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UpcomingTransactionsRef =
    AutoDisposeStreamProviderRef<List<TransactionModel>>;
String _$externalTransactionsHash() =>
    r'607f5007bf006e0ee1f4f70033acd91bedb7c462';

/// See also [externalTransactions].
@ProviderFor(externalTransactions)
const externalTransactionsProvider = ExternalTransactionsFamily();

/// See also [externalTransactions].
class ExternalTransactionsFamily
    extends Family<AsyncValue<List<TransactionModel>>> {
  /// See also [externalTransactions].
  const ExternalTransactionsFamily();

  /// See also [externalTransactions].
  ExternalTransactionsProvider call(String externalEntityId) {
    return ExternalTransactionsProvider(externalEntityId);
  }

  @override
  ExternalTransactionsProvider getProviderOverride(
    covariant ExternalTransactionsProvider provider,
  ) {
    return call(provider.externalEntityId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'externalTransactionsProvider';
}

/// See also [externalTransactions].
class ExternalTransactionsProvider
    extends AutoDisposeStreamProvider<List<TransactionModel>> {
  /// See also [externalTransactions].
  ExternalTransactionsProvider(String externalEntityId)
    : this._internal(
        (ref) => externalTransactions(
          ref as ExternalTransactionsRef,
          externalEntityId,
        ),
        from: externalTransactionsProvider,
        name: r'externalTransactionsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$externalTransactionsHash,
        dependencies: ExternalTransactionsFamily._dependencies,
        allTransitiveDependencies:
            ExternalTransactionsFamily._allTransitiveDependencies,
        externalEntityId: externalEntityId,
      );

  ExternalTransactionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.externalEntityId,
  }) : super.internal();

  final String externalEntityId;

  @override
  Override overrideWith(
    Stream<List<TransactionModel>> Function(ExternalTransactionsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ExternalTransactionsProvider._internal(
        (ref) => create(ref as ExternalTransactionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        externalEntityId: externalEntityId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<TransactionModel>> createElement() {
    return _ExternalTransactionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ExternalTransactionsProvider &&
        other.externalEntityId == externalEntityId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, externalEntityId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ExternalTransactionsRef
    on AutoDisposeStreamProviderRef<List<TransactionModel>> {
  /// The parameter `externalEntityId` of this provider.
  String get externalEntityId;
}

class _ExternalTransactionsProviderElement
    extends AutoDisposeStreamProviderElement<List<TransactionModel>>
    with ExternalTransactionsRef {
  _ExternalTransactionsProviderElement(super.provider);

  @override
  String get externalEntityId =>
      (origin as ExternalTransactionsProvider).externalEntityId;
}

String _$transactionSearchQueryHash() =>
    r'7d8839975c8af423b230c1baaffb2a132ff8f053';

/// See also [TransactionSearchQuery].
@ProviderFor(TransactionSearchQuery)
final transactionSearchQueryProvider =
    AutoDisposeNotifierProvider<TransactionSearchQuery, String>.internal(
      TransactionSearchQuery.new,
      name: r'transactionSearchQueryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$transactionSearchQueryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TransactionSearchQuery = AutoDisposeNotifier<String>;
String _$transactionDateFilterHash() =>
    r'86932d97d824d0c9121315535e747eff0df22897';

/// See also [TransactionDateFilter].
@ProviderFor(TransactionDateFilter)
final transactionDateFilterProvider =
    AutoDisposeNotifierProvider<TransactionDateFilter, DateTimeRange?>.internal(
      TransactionDateFilter.new,
      name: r'transactionDateFilterProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$transactionDateFilterHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TransactionDateFilter = AutoDisposeNotifier<DateTimeRange?>;
String _$transactionSortOrderHash() =>
    r'f73fd498a47ae0949681b3ab24443679e4799e7a';

/// See also [TransactionSortOrder].
@ProviderFor(TransactionSortOrder)
final transactionSortOrderProvider =
    AutoDisposeNotifierProvider<TransactionSortOrder, TransactionSort>.internal(
      TransactionSortOrder.new,
      name: r'transactionSortOrderProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$transactionSortOrderHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TransactionSortOrder = AutoDisposeNotifier<TransactionSort>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

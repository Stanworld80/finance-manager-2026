// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$envelopeFundSourcesHash() =>
    r'774c897478db20c6f7bae6ffbde21648448dc138';

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

/// See also [envelopeFundSources].
@ProviderFor(envelopeFundSources)
const envelopeFundSourcesProvider = EnvelopeFundSourcesFamily();

/// See also [envelopeFundSources].
class EnvelopeFundSourcesFamily extends Family<AsyncValue<List<FundSource>>> {
  /// See also [envelopeFundSources].
  const EnvelopeFundSourcesFamily();

  /// See also [envelopeFundSources].
  EnvelopeFundSourcesProvider call(String virtualAccountId) {
    return EnvelopeFundSourcesProvider(virtualAccountId);
  }

  @override
  EnvelopeFundSourcesProvider getProviderOverride(
    covariant EnvelopeFundSourcesProvider provider,
  ) {
    return call(provider.virtualAccountId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'envelopeFundSourcesProvider';
}

/// See also [envelopeFundSources].
class EnvelopeFundSourcesProvider
    extends AutoDisposeFutureProvider<List<FundSource>> {
  /// See also [envelopeFundSources].
  EnvelopeFundSourcesProvider(String virtualAccountId)
    : this._internal(
        (ref) => envelopeFundSources(
          ref as EnvelopeFundSourcesRef,
          virtualAccountId,
        ),
        from: envelopeFundSourcesProvider,
        name: r'envelopeFundSourcesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$envelopeFundSourcesHash,
        dependencies: EnvelopeFundSourcesFamily._dependencies,
        allTransitiveDependencies:
            EnvelopeFundSourcesFamily._allTransitiveDependencies,
        virtualAccountId: virtualAccountId,
      );

  EnvelopeFundSourcesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.virtualAccountId,
  }) : super.internal();

  final String virtualAccountId;

  @override
  Override overrideWith(
    FutureOr<List<FundSource>> Function(EnvelopeFundSourcesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EnvelopeFundSourcesProvider._internal(
        (ref) => create(ref as EnvelopeFundSourcesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        virtualAccountId: virtualAccountId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<FundSource>> createElement() {
    return _EnvelopeFundSourcesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EnvelopeFundSourcesProvider &&
        other.virtualAccountId == virtualAccountId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, virtualAccountId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EnvelopeFundSourcesRef on AutoDisposeFutureProviderRef<List<FundSource>> {
  /// The parameter `virtualAccountId` of this provider.
  String get virtualAccountId;
}

class _EnvelopeFundSourcesProviderElement
    extends AutoDisposeFutureProviderElement<List<FundSource>>
    with EnvelopeFundSourcesRef {
  _EnvelopeFundSourcesProviderElement(super.provider);

  @override
  String get virtualAccountId =>
      (origin as EnvelopeFundSourcesProvider).virtualAccountId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resume_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$resumeDataHash() => r'8a7235a746ea1c5e2241a34835e5ef625eeb02f1';

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

/// See also [resumeData].
@ProviderFor(resumeData)
const resumeDataProvider = ResumeDataFamily();

/// See also [resumeData].
class ResumeDataFamily extends Family<AsyncValue<List<EnvelopeStat>>> {
  /// See also [resumeData].
  const ResumeDataFamily();

  /// See also [resumeData].
  ResumeDataProvider call(DateTimeRange<DateTime> period) {
    return ResumeDataProvider(period);
  }

  @override
  ResumeDataProvider getProviderOverride(
    covariant ResumeDataProvider provider,
  ) {
    return call(provider.period);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'resumeDataProvider';
}

/// See also [resumeData].
class ResumeDataProvider extends AutoDisposeFutureProvider<List<EnvelopeStat>> {
  /// See also [resumeData].
  ResumeDataProvider(DateTimeRange<DateTime> period)
    : this._internal(
        (ref) => resumeData(ref as ResumeDataRef, period),
        from: resumeDataProvider,
        name: r'resumeDataProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$resumeDataHash,
        dependencies: ResumeDataFamily._dependencies,
        allTransitiveDependencies: ResumeDataFamily._allTransitiveDependencies,
        period: period,
      );

  ResumeDataProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.period,
  }) : super.internal();

  final DateTimeRange<DateTime> period;

  @override
  Override overrideWith(
    FutureOr<List<EnvelopeStat>> Function(ResumeDataRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ResumeDataProvider._internal(
        (ref) => create(ref as ResumeDataRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        period: period,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<EnvelopeStat>> createElement() {
    return _ResumeDataProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ResumeDataProvider && other.period == period;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, period.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ResumeDataRef on AutoDisposeFutureProviderRef<List<EnvelopeStat>> {
  /// The parameter `period` of this provider.
  DateTimeRange<DateTime> get period;
}

class _ResumeDataProviderElement
    extends AutoDisposeFutureProviderElement<List<EnvelopeStat>>
    with ResumeDataRef {
  _ResumeDataProviderElement(super.provider);

  @override
  DateTimeRange<DateTime> get period => (origin as ResumeDataProvider).period;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

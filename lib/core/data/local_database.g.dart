// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $RealAccountsTable extends RealAccounts
    with TableInfo<$RealAccountsTable, RealAccountData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RealAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankNameMeta = const VerificationMeta(
    'bankName',
  );
  @override
  late final GeneratedColumn<String> bankName = GeneratedColumn<String>(
    'bank_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _initialBalanceMeta = const VerificationMeta(
    'initialBalance',
  );
  @override
  late final GeneratedColumn<double> initialBalance = GeneratedColumn<double>(
    'initial_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _balanceMeta = const VerificationMeta(
    'balance',
  );
  @override
  late final GeneratedColumn<double> balance = GeneratedColumn<double>(
    'balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPrincipalMeta = const VerificationMeta(
    'isPrincipal',
  );
  @override
  late final GeneratedColumn<bool> isPrincipal = GeneratedColumn<bool>(
    'is_principal',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_principal" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sharedWithUserIdsMeta = const VerificationMeta(
    'sharedWithUserIds',
  );
  @override
  late final GeneratedColumn<String> sharedWithUserIds =
      GeneratedColumn<String>(
        'shared_with_user_ids',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _openingDateMeta = const VerificationMeta(
    'openingDate',
  );
  @override
  late final GeneratedColumn<DateTime> openingDate = GeneratedColumn<DateTime>(
    'opening_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountNumberMeta = const VerificationMeta(
    'accountNumber',
  );
  @override
  late final GeneratedColumn<String> accountNumber = GeneratedColumn<String>(
    'account_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _officialNameMeta = const VerificationMeta(
    'officialName',
  );
  @override
  late final GeneratedColumn<String> officialName = GeneratedColumn<String>(
    'official_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ibanMeta = const VerificationMeta('iban');
  @override
  late final GeneratedColumn<String> iban = GeneratedColumn<String>(
    'iban',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bicMeta = const VerificationMeta('bic');
  @override
  late final GeneratedColumn<String> bic = GeneratedColumn<String>(
    'bic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _swiftMeta = const VerificationMeta('swift');
  @override
  late final GeneratedColumn<String> swift = GeneratedColumn<String>(
    'swift',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerId,
    name,
    bankName,
    initialBalance,
    balance,
    type,
    isPrincipal,
    sharedWithUserIds,
    openingDate,
    accountNumber,
    officialName,
    iban,
    bic,
    swift,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'real_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<RealAccountData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('bank_name')) {
      context.handle(
        _bankNameMeta,
        bankName.isAcceptableOrUnknown(data['bank_name']!, _bankNameMeta),
      );
    }
    if (data.containsKey('initial_balance')) {
      context.handle(
        _initialBalanceMeta,
        initialBalance.isAcceptableOrUnknown(
          data['initial_balance']!,
          _initialBalanceMeta,
        ),
      );
    }
    if (data.containsKey('balance')) {
      context.handle(
        _balanceMeta,
        balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('is_principal')) {
      context.handle(
        _isPrincipalMeta,
        isPrincipal.isAcceptableOrUnknown(
          data['is_principal']!,
          _isPrincipalMeta,
        ),
      );
    }
    if (data.containsKey('shared_with_user_ids')) {
      context.handle(
        _sharedWithUserIdsMeta,
        sharedWithUserIds.isAcceptableOrUnknown(
          data['shared_with_user_ids']!,
          _sharedWithUserIdsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sharedWithUserIdsMeta);
    }
    if (data.containsKey('opening_date')) {
      context.handle(
        _openingDateMeta,
        openingDate.isAcceptableOrUnknown(
          data['opening_date']!,
          _openingDateMeta,
        ),
      );
    }
    if (data.containsKey('account_number')) {
      context.handle(
        _accountNumberMeta,
        accountNumber.isAcceptableOrUnknown(
          data['account_number']!,
          _accountNumberMeta,
        ),
      );
    }
    if (data.containsKey('official_name')) {
      context.handle(
        _officialNameMeta,
        officialName.isAcceptableOrUnknown(
          data['official_name']!,
          _officialNameMeta,
        ),
      );
    }
    if (data.containsKey('iban')) {
      context.handle(
        _ibanMeta,
        iban.isAcceptableOrUnknown(data['iban']!, _ibanMeta),
      );
    }
    if (data.containsKey('bic')) {
      context.handle(
        _bicMeta,
        bic.isAcceptableOrUnknown(data['bic']!, _bicMeta),
      );
    }
    if (data.containsKey('swift')) {
      context.handle(
        _swiftMeta,
        swift.isAcceptableOrUnknown(data['swift']!, _swiftMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RealAccountData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RealAccountData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      bankName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_name'],
      ),
      initialBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}initial_balance'],
      )!,
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}balance'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      isPrincipal: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_principal'],
      )!,
      sharedWithUserIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shared_with_user_ids'],
      )!,
      openingDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opening_date'],
      ),
      accountNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_number'],
      ),
      officialName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}official_name'],
      ),
      iban: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}iban'],
      ),
      bic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bic'],
      ),
      swift: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}swift'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RealAccountsTable createAlias(String alias) {
    return $RealAccountsTable(attachedDatabase, alias);
  }
}

class RealAccountData extends DataClass implements Insertable<RealAccountData> {
  final String id;
  final String ownerId;
  final String name;
  final String? bankName;
  final double initialBalance;
  final double balance;
  final String type;
  final bool isPrincipal;
  final String sharedWithUserIds;
  final DateTime? openingDate;
  final String? accountNumber;
  final String? officialName;
  final String? iban;
  final String? bic;
  final String? swift;
  final DateTime updatedAt;
  const RealAccountData({
    required this.id,
    required this.ownerId,
    required this.name,
    this.bankName,
    required this.initialBalance,
    required this.balance,
    required this.type,
    required this.isPrincipal,
    required this.sharedWithUserIds,
    this.openingDate,
    this.accountNumber,
    this.officialName,
    this.iban,
    this.bic,
    this.swift,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_id'] = Variable<String>(ownerId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || bankName != null) {
      map['bank_name'] = Variable<String>(bankName);
    }
    map['initial_balance'] = Variable<double>(initialBalance);
    map['balance'] = Variable<double>(balance);
    map['type'] = Variable<String>(type);
    map['is_principal'] = Variable<bool>(isPrincipal);
    map['shared_with_user_ids'] = Variable<String>(sharedWithUserIds);
    if (!nullToAbsent || openingDate != null) {
      map['opening_date'] = Variable<DateTime>(openingDate);
    }
    if (!nullToAbsent || accountNumber != null) {
      map['account_number'] = Variable<String>(accountNumber);
    }
    if (!nullToAbsent || officialName != null) {
      map['official_name'] = Variable<String>(officialName);
    }
    if (!nullToAbsent || iban != null) {
      map['iban'] = Variable<String>(iban);
    }
    if (!nullToAbsent || bic != null) {
      map['bic'] = Variable<String>(bic);
    }
    if (!nullToAbsent || swift != null) {
      map['swift'] = Variable<String>(swift);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RealAccountsCompanion toCompanion(bool nullToAbsent) {
    return RealAccountsCompanion(
      id: Value(id),
      ownerId: Value(ownerId),
      name: Value(name),
      bankName: bankName == null && nullToAbsent
          ? const Value.absent()
          : Value(bankName),
      initialBalance: Value(initialBalance),
      balance: Value(balance),
      type: Value(type),
      isPrincipal: Value(isPrincipal),
      sharedWithUserIds: Value(sharedWithUserIds),
      openingDate: openingDate == null && nullToAbsent
          ? const Value.absent()
          : Value(openingDate),
      accountNumber: accountNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(accountNumber),
      officialName: officialName == null && nullToAbsent
          ? const Value.absent()
          : Value(officialName),
      iban: iban == null && nullToAbsent ? const Value.absent() : Value(iban),
      bic: bic == null && nullToAbsent ? const Value.absent() : Value(bic),
      swift: swift == null && nullToAbsent
          ? const Value.absent()
          : Value(swift),
      updatedAt: Value(updatedAt),
    );
  }

  factory RealAccountData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RealAccountData(
      id: serializer.fromJson<String>(json['id']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      name: serializer.fromJson<String>(json['name']),
      bankName: serializer.fromJson<String?>(json['bankName']),
      initialBalance: serializer.fromJson<double>(json['initialBalance']),
      balance: serializer.fromJson<double>(json['balance']),
      type: serializer.fromJson<String>(json['type']),
      isPrincipal: serializer.fromJson<bool>(json['isPrincipal']),
      sharedWithUserIds: serializer.fromJson<String>(json['sharedWithUserIds']),
      openingDate: serializer.fromJson<DateTime?>(json['openingDate']),
      accountNumber: serializer.fromJson<String?>(json['accountNumber']),
      officialName: serializer.fromJson<String?>(json['officialName']),
      iban: serializer.fromJson<String?>(json['iban']),
      bic: serializer.fromJson<String?>(json['bic']),
      swift: serializer.fromJson<String?>(json['swift']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerId': serializer.toJson<String>(ownerId),
      'name': serializer.toJson<String>(name),
      'bankName': serializer.toJson<String?>(bankName),
      'initialBalance': serializer.toJson<double>(initialBalance),
      'balance': serializer.toJson<double>(balance),
      'type': serializer.toJson<String>(type),
      'isPrincipal': serializer.toJson<bool>(isPrincipal),
      'sharedWithUserIds': serializer.toJson<String>(sharedWithUserIds),
      'openingDate': serializer.toJson<DateTime?>(openingDate),
      'accountNumber': serializer.toJson<String?>(accountNumber),
      'officialName': serializer.toJson<String?>(officialName),
      'iban': serializer.toJson<String?>(iban),
      'bic': serializer.toJson<String?>(bic),
      'swift': serializer.toJson<String?>(swift),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RealAccountData copyWith({
    String? id,
    String? ownerId,
    String? name,
    Value<String?> bankName = const Value.absent(),
    double? initialBalance,
    double? balance,
    String? type,
    bool? isPrincipal,
    String? sharedWithUserIds,
    Value<DateTime?> openingDate = const Value.absent(),
    Value<String?> accountNumber = const Value.absent(),
    Value<String?> officialName = const Value.absent(),
    Value<String?> iban = const Value.absent(),
    Value<String?> bic = const Value.absent(),
    Value<String?> swift = const Value.absent(),
    DateTime? updatedAt,
  }) => RealAccountData(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    name: name ?? this.name,
    bankName: bankName.present ? bankName.value : this.bankName,
    initialBalance: initialBalance ?? this.initialBalance,
    balance: balance ?? this.balance,
    type: type ?? this.type,
    isPrincipal: isPrincipal ?? this.isPrincipal,
    sharedWithUserIds: sharedWithUserIds ?? this.sharedWithUserIds,
    openingDate: openingDate.present ? openingDate.value : this.openingDate,
    accountNumber: accountNumber.present
        ? accountNumber.value
        : this.accountNumber,
    officialName: officialName.present ? officialName.value : this.officialName,
    iban: iban.present ? iban.value : this.iban,
    bic: bic.present ? bic.value : this.bic,
    swift: swift.present ? swift.value : this.swift,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RealAccountData copyWithCompanion(RealAccountsCompanion data) {
    return RealAccountData(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      name: data.name.present ? data.name.value : this.name,
      bankName: data.bankName.present ? data.bankName.value : this.bankName,
      initialBalance: data.initialBalance.present
          ? data.initialBalance.value
          : this.initialBalance,
      balance: data.balance.present ? data.balance.value : this.balance,
      type: data.type.present ? data.type.value : this.type,
      isPrincipal: data.isPrincipal.present
          ? data.isPrincipal.value
          : this.isPrincipal,
      sharedWithUserIds: data.sharedWithUserIds.present
          ? data.sharedWithUserIds.value
          : this.sharedWithUserIds,
      openingDate: data.openingDate.present
          ? data.openingDate.value
          : this.openingDate,
      accountNumber: data.accountNumber.present
          ? data.accountNumber.value
          : this.accountNumber,
      officialName: data.officialName.present
          ? data.officialName.value
          : this.officialName,
      iban: data.iban.present ? data.iban.value : this.iban,
      bic: data.bic.present ? data.bic.value : this.bic,
      swift: data.swift.present ? data.swift.value : this.swift,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RealAccountData(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('name: $name, ')
          ..write('bankName: $bankName, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('balance: $balance, ')
          ..write('type: $type, ')
          ..write('isPrincipal: $isPrincipal, ')
          ..write('sharedWithUserIds: $sharedWithUserIds, ')
          ..write('openingDate: $openingDate, ')
          ..write('accountNumber: $accountNumber, ')
          ..write('officialName: $officialName, ')
          ..write('iban: $iban, ')
          ..write('bic: $bic, ')
          ..write('swift: $swift, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerId,
    name,
    bankName,
    initialBalance,
    balance,
    type,
    isPrincipal,
    sharedWithUserIds,
    openingDate,
    accountNumber,
    officialName,
    iban,
    bic,
    swift,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RealAccountData &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.name == this.name &&
          other.bankName == this.bankName &&
          other.initialBalance == this.initialBalance &&
          other.balance == this.balance &&
          other.type == this.type &&
          other.isPrincipal == this.isPrincipal &&
          other.sharedWithUserIds == this.sharedWithUserIds &&
          other.openingDate == this.openingDate &&
          other.accountNumber == this.accountNumber &&
          other.officialName == this.officialName &&
          other.iban == this.iban &&
          other.bic == this.bic &&
          other.swift == this.swift &&
          other.updatedAt == this.updatedAt);
}

class RealAccountsCompanion extends UpdateCompanion<RealAccountData> {
  final Value<String> id;
  final Value<String> ownerId;
  final Value<String> name;
  final Value<String?> bankName;
  final Value<double> initialBalance;
  final Value<double> balance;
  final Value<String> type;
  final Value<bool> isPrincipal;
  final Value<String> sharedWithUserIds;
  final Value<DateTime?> openingDate;
  final Value<String?> accountNumber;
  final Value<String?> officialName;
  final Value<String?> iban;
  final Value<String?> bic;
  final Value<String?> swift;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RealAccountsCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.name = const Value.absent(),
    this.bankName = const Value.absent(),
    this.initialBalance = const Value.absent(),
    this.balance = const Value.absent(),
    this.type = const Value.absent(),
    this.isPrincipal = const Value.absent(),
    this.sharedWithUserIds = const Value.absent(),
    this.openingDate = const Value.absent(),
    this.accountNumber = const Value.absent(),
    this.officialName = const Value.absent(),
    this.iban = const Value.absent(),
    this.bic = const Value.absent(),
    this.swift = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RealAccountsCompanion.insert({
    required String id,
    required String ownerId,
    required String name,
    this.bankName = const Value.absent(),
    this.initialBalance = const Value.absent(),
    this.balance = const Value.absent(),
    required String type,
    this.isPrincipal = const Value.absent(),
    required String sharedWithUserIds,
    this.openingDate = const Value.absent(),
    this.accountNumber = const Value.absent(),
    this.officialName = const Value.absent(),
    this.iban = const Value.absent(),
    this.bic = const Value.absent(),
    this.swift = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ownerId = Value(ownerId),
       name = Value(name),
       type = Value(type),
       sharedWithUserIds = Value(sharedWithUserIds),
       updatedAt = Value(updatedAt);
  static Insertable<RealAccountData> custom({
    Expression<String>? id,
    Expression<String>? ownerId,
    Expression<String>? name,
    Expression<String>? bankName,
    Expression<double>? initialBalance,
    Expression<double>? balance,
    Expression<String>? type,
    Expression<bool>? isPrincipal,
    Expression<String>? sharedWithUserIds,
    Expression<DateTime>? openingDate,
    Expression<String>? accountNumber,
    Expression<String>? officialName,
    Expression<String>? iban,
    Expression<String>? bic,
    Expression<String>? swift,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (name != null) 'name': name,
      if (bankName != null) 'bank_name': bankName,
      if (initialBalance != null) 'initial_balance': initialBalance,
      if (balance != null) 'balance': balance,
      if (type != null) 'type': type,
      if (isPrincipal != null) 'is_principal': isPrincipal,
      if (sharedWithUserIds != null) 'shared_with_user_ids': sharedWithUserIds,
      if (openingDate != null) 'opening_date': openingDate,
      if (accountNumber != null) 'account_number': accountNumber,
      if (officialName != null) 'official_name': officialName,
      if (iban != null) 'iban': iban,
      if (bic != null) 'bic': bic,
      if (swift != null) 'swift': swift,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RealAccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? ownerId,
    Value<String>? name,
    Value<String?>? bankName,
    Value<double>? initialBalance,
    Value<double>? balance,
    Value<String>? type,
    Value<bool>? isPrincipal,
    Value<String>? sharedWithUserIds,
    Value<DateTime?>? openingDate,
    Value<String?>? accountNumber,
    Value<String?>? officialName,
    Value<String?>? iban,
    Value<String?>? bic,
    Value<String?>? swift,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return RealAccountsCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      bankName: bankName ?? this.bankName,
      initialBalance: initialBalance ?? this.initialBalance,
      balance: balance ?? this.balance,
      type: type ?? this.type,
      isPrincipal: isPrincipal ?? this.isPrincipal,
      sharedWithUserIds: sharedWithUserIds ?? this.sharedWithUserIds,
      openingDate: openingDate ?? this.openingDate,
      accountNumber: accountNumber ?? this.accountNumber,
      officialName: officialName ?? this.officialName,
      iban: iban ?? this.iban,
      bic: bic ?? this.bic,
      swift: swift ?? this.swift,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (bankName.present) {
      map['bank_name'] = Variable<String>(bankName.value);
    }
    if (initialBalance.present) {
      map['initial_balance'] = Variable<double>(initialBalance.value);
    }
    if (balance.present) {
      map['balance'] = Variable<double>(balance.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (isPrincipal.present) {
      map['is_principal'] = Variable<bool>(isPrincipal.value);
    }
    if (sharedWithUserIds.present) {
      map['shared_with_user_ids'] = Variable<String>(sharedWithUserIds.value);
    }
    if (openingDate.present) {
      map['opening_date'] = Variable<DateTime>(openingDate.value);
    }
    if (accountNumber.present) {
      map['account_number'] = Variable<String>(accountNumber.value);
    }
    if (officialName.present) {
      map['official_name'] = Variable<String>(officialName.value);
    }
    if (iban.present) {
      map['iban'] = Variable<String>(iban.value);
    }
    if (bic.present) {
      map['bic'] = Variable<String>(bic.value);
    }
    if (swift.present) {
      map['swift'] = Variable<String>(swift.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RealAccountsCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('name: $name, ')
          ..write('bankName: $bankName, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('balance: $balance, ')
          ..write('type: $type, ')
          ..write('isPrincipal: $isPrincipal, ')
          ..write('sharedWithUserIds: $sharedWithUserIds, ')
          ..write('openingDate: $openingDate, ')
          ..write('accountNumber: $accountNumber, ')
          ..write('officialName: $officialName, ')
          ..write('iban: $iban, ')
          ..write('bic: $bic, ')
          ..write('swift: $swift, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VirtualAccountsTable extends VirtualAccounts
    with TableInfo<$VirtualAccountsTable, VirtualAccountData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VirtualAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _realAccountIdMeta = const VerificationMeta(
    'realAccountId',
  );
  @override
  late final GeneratedColumn<String> realAccountId = GeneratedColumn<String>(
    'real_account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES real_accounts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceMeta = const VerificationMeta(
    'balance',
  );
  @override
  late final GeneratedColumn<double> balance = GeneratedColumn<double>(
    'balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    realAccountId,
    name,
    balance,
    type,
    icon,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'virtual_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<VirtualAccountData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('real_account_id')) {
      context.handle(
        _realAccountIdMeta,
        realAccountId.isAcceptableOrUnknown(
          data['real_account_id']!,
          _realAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_realAccountIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(
        _balanceMeta,
        balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VirtualAccountData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VirtualAccountData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      realAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}real_account_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}balance'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VirtualAccountsTable createAlias(String alias) {
    return $VirtualAccountsTable(attachedDatabase, alias);
  }
}

class VirtualAccountData extends DataClass
    implements Insertable<VirtualAccountData> {
  final String id;
  final String userId;
  final String realAccountId;
  final String name;
  final double balance;
  final String type;
  final String? icon;
  final DateTime updatedAt;
  const VirtualAccountData({
    required this.id,
    required this.userId,
    required this.realAccountId,
    required this.name,
    required this.balance,
    required this.type,
    this.icon,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['real_account_id'] = Variable<String>(realAccountId);
    map['name'] = Variable<String>(name);
    map['balance'] = Variable<double>(balance);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VirtualAccountsCompanion toCompanion(bool nullToAbsent) {
    return VirtualAccountsCompanion(
      id: Value(id),
      userId: Value(userId),
      realAccountId: Value(realAccountId),
      name: Value(name),
      balance: Value(balance),
      type: Value(type),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      updatedAt: Value(updatedAt),
    );
  }

  factory VirtualAccountData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VirtualAccountData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      realAccountId: serializer.fromJson<String>(json['realAccountId']),
      name: serializer.fromJson<String>(json['name']),
      balance: serializer.fromJson<double>(json['balance']),
      type: serializer.fromJson<String>(json['type']),
      icon: serializer.fromJson<String?>(json['icon']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'realAccountId': serializer.toJson<String>(realAccountId),
      'name': serializer.toJson<String>(name),
      'balance': serializer.toJson<double>(balance),
      'type': serializer.toJson<String>(type),
      'icon': serializer.toJson<String?>(icon),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  VirtualAccountData copyWith({
    String? id,
    String? userId,
    String? realAccountId,
    String? name,
    double? balance,
    String? type,
    Value<String?> icon = const Value.absent(),
    DateTime? updatedAt,
  }) => VirtualAccountData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    realAccountId: realAccountId ?? this.realAccountId,
    name: name ?? this.name,
    balance: balance ?? this.balance,
    type: type ?? this.type,
    icon: icon.present ? icon.value : this.icon,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VirtualAccountData copyWithCompanion(VirtualAccountsCompanion data) {
    return VirtualAccountData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      realAccountId: data.realAccountId.present
          ? data.realAccountId.value
          : this.realAccountId,
      name: data.name.present ? data.name.value : this.name,
      balance: data.balance.present ? data.balance.value : this.balance,
      type: data.type.present ? data.type.value : this.type,
      icon: data.icon.present ? data.icon.value : this.icon,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VirtualAccountData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('realAccountId: $realAccountId, ')
          ..write('name: $name, ')
          ..write('balance: $balance, ')
          ..write('type: $type, ')
          ..write('icon: $icon, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    realAccountId,
    name,
    balance,
    type,
    icon,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VirtualAccountData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.realAccountId == this.realAccountId &&
          other.name == this.name &&
          other.balance == this.balance &&
          other.type == this.type &&
          other.icon == this.icon &&
          other.updatedAt == this.updatedAt);
}

class VirtualAccountsCompanion extends UpdateCompanion<VirtualAccountData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> realAccountId;
  final Value<String> name;
  final Value<double> balance;
  final Value<String> type;
  final Value<String?> icon;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const VirtualAccountsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.realAccountId = const Value.absent(),
    this.name = const Value.absent(),
    this.balance = const Value.absent(),
    this.type = const Value.absent(),
    this.icon = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VirtualAccountsCompanion.insert({
    required String id,
    required String userId,
    required String realAccountId,
    required String name,
    this.balance = const Value.absent(),
    required String type,
    this.icon = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       realAccountId = Value(realAccountId),
       name = Value(name),
       type = Value(type),
       updatedAt = Value(updatedAt);
  static Insertable<VirtualAccountData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? realAccountId,
    Expression<String>? name,
    Expression<double>? balance,
    Expression<String>? type,
    Expression<String>? icon,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (realAccountId != null) 'real_account_id': realAccountId,
      if (name != null) 'name': name,
      if (balance != null) 'balance': balance,
      if (type != null) 'type': type,
      if (icon != null) 'icon': icon,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VirtualAccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? realAccountId,
    Value<String>? name,
    Value<double>? balance,
    Value<String>? type,
    Value<String?>? icon,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return VirtualAccountsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      realAccountId: realAccountId ?? this.realAccountId,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (realAccountId.present) {
      map['real_account_id'] = Variable<String>(realAccountId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (balance.present) {
      map['balance'] = Variable<double>(balance.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VirtualAccountsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('realAccountId: $realAccountId, ')
          ..write('name: $name, ')
          ..write('balance: $balance, ')
          ..write('type: $type, ')
          ..write('icon: $icon, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _realAccountIdMeta = const VerificationMeta(
    'realAccountId',
  );
  @override
  late final GeneratedColumn<String> realAccountId = GeneratedColumn<String>(
    'real_account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES real_accounts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payeeMeta = const VerificationMeta('payee');
  @override
  late final GeneratedColumn<String> payee = GeneratedColumn<String>(
    'payee',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionDateMeta = const VerificationMeta(
    'transactionDate',
  );
  @override
  late final GeneratedColumn<DateTime> transactionDate =
      GeneratedColumn<DateTime>(
        'transaction_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _valueDateMeta = const VerificationMeta(
    'valueDate',
  );
  @override
  late final GeneratedColumn<DateTime> valueDate = GeneratedColumn<DateTime>(
    'value_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visibilityDateMeta = const VerificationMeta(
    'visibilityDate',
  );
  @override
  late final GeneratedColumn<DateTime> visibilityDate =
      GeneratedColumn<DateTime>(
        'visibility_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncDateMeta = const VerificationMeta(
    'syncDate',
  );
  @override
  late final GeneratedColumn<DateTime> syncDate = GeneratedColumn<DateTime>(
    'sync_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _provisionDateMeta = const VerificationMeta(
    'provisionDate',
  );
  @override
  late final GeneratedColumn<DateTime> provisionDate =
      GeneratedColumn<DateTime>(
        'provision_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _stepMeta = const VerificationMeta('step');
  @override
  late final GeneratedColumn<String> step = GeneratedColumn<String>(
    'step',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importHashMeta = const VerificationMeta(
    'importHash',
  );
  @override
  late final GeneratedColumn<String> importHash = GeneratedColumn<String>(
    'import_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurringTransactionIdMeta =
      const VerificationMeta('recurringTransactionId');
  @override
  late final GeneratedColumn<String> recurringTransactionId =
      GeneratedColumn<String>(
        'recurring_transaction_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _linkedTransactionIdMeta =
      const VerificationMeta('linkedTransactionId');
  @override
  late final GeneratedColumn<String> linkedTransactionId =
      GeneratedColumn<String>(
        'linked_transaction_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerId,
    realAccountId,
    label,
    note,
    payee,
    category,
    amount,
    type,
    transactionDate,
    valueDate,
    visibilityDate,
    syncDate,
    provisionDate,
    step,
    status,
    importHash,
    recurringTransactionId,
    linkedTransactionId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('real_account_id')) {
      context.handle(
        _realAccountIdMeta,
        realAccountId.isAcceptableOrUnknown(
          data['real_account_id']!,
          _realAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_realAccountIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('payee')) {
      context.handle(
        _payeeMeta,
        payee.isAcceptableOrUnknown(data['payee']!, _payeeMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('transaction_date')) {
      context.handle(
        _transactionDateMeta,
        transactionDate.isAcceptableOrUnknown(
          data['transaction_date']!,
          _transactionDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionDateMeta);
    }
    if (data.containsKey('value_date')) {
      context.handle(
        _valueDateMeta,
        valueDate.isAcceptableOrUnknown(data['value_date']!, _valueDateMeta),
      );
    }
    if (data.containsKey('visibility_date')) {
      context.handle(
        _visibilityDateMeta,
        visibilityDate.isAcceptableOrUnknown(
          data['visibility_date']!,
          _visibilityDateMeta,
        ),
      );
    }
    if (data.containsKey('sync_date')) {
      context.handle(
        _syncDateMeta,
        syncDate.isAcceptableOrUnknown(data['sync_date']!, _syncDateMeta),
      );
    }
    if (data.containsKey('provision_date')) {
      context.handle(
        _provisionDateMeta,
        provisionDate.isAcceptableOrUnknown(
          data['provision_date']!,
          _provisionDateMeta,
        ),
      );
    }
    if (data.containsKey('step')) {
      context.handle(
        _stepMeta,
        step.isAcceptableOrUnknown(data['step']!, _stepMeta),
      );
    } else if (isInserting) {
      context.missing(_stepMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('import_hash')) {
      context.handle(
        _importHashMeta,
        importHash.isAcceptableOrUnknown(data['import_hash']!, _importHashMeta),
      );
    }
    if (data.containsKey('recurring_transaction_id')) {
      context.handle(
        _recurringTransactionIdMeta,
        recurringTransactionId.isAcceptableOrUnknown(
          data['recurring_transaction_id']!,
          _recurringTransactionIdMeta,
        ),
      );
    }
    if (data.containsKey('linked_transaction_id')) {
      context.handle(
        _linkedTransactionIdMeta,
        linkedTransactionId.isAcceptableOrUnknown(
          data['linked_transaction_id']!,
          _linkedTransactionIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      realAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}real_account_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      payee: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payee'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      transactionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}transaction_date'],
      )!,
      valueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}value_date'],
      ),
      visibilityDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}visibility_date'],
      ),
      syncDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sync_date'],
      ),
      provisionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}provision_date'],
      ),
      step: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}step'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      importHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}import_hash'],
      ),
      recurringTransactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurring_transaction_id'],
      ),
      linkedTransactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_transaction_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class TransactionData extends DataClass implements Insertable<TransactionData> {
  final String id;
  final String ownerId;
  final String realAccountId;
  final String? label;
  final String? note;
  final String? payee;
  final String? category;
  final double amount;
  final String type;
  final DateTime transactionDate;
  final DateTime? valueDate;
  final DateTime? visibilityDate;
  final DateTime? syncDate;
  final DateTime? provisionDate;
  final String step;
  final String status;
  final String? importHash;
  final String? recurringTransactionId;
  final String? linkedTransactionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TransactionData({
    required this.id,
    required this.ownerId,
    required this.realAccountId,
    this.label,
    this.note,
    this.payee,
    this.category,
    required this.amount,
    required this.type,
    required this.transactionDate,
    this.valueDate,
    this.visibilityDate,
    this.syncDate,
    this.provisionDate,
    required this.step,
    required this.status,
    this.importHash,
    this.recurringTransactionId,
    this.linkedTransactionId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_id'] = Variable<String>(ownerId);
    map['real_account_id'] = Variable<String>(realAccountId);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || payee != null) {
      map['payee'] = Variable<String>(payee);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['amount'] = Variable<double>(amount);
    map['type'] = Variable<String>(type);
    map['transaction_date'] = Variable<DateTime>(transactionDate);
    if (!nullToAbsent || valueDate != null) {
      map['value_date'] = Variable<DateTime>(valueDate);
    }
    if (!nullToAbsent || visibilityDate != null) {
      map['visibility_date'] = Variable<DateTime>(visibilityDate);
    }
    if (!nullToAbsent || syncDate != null) {
      map['sync_date'] = Variable<DateTime>(syncDate);
    }
    if (!nullToAbsent || provisionDate != null) {
      map['provision_date'] = Variable<DateTime>(provisionDate);
    }
    map['step'] = Variable<String>(step);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || importHash != null) {
      map['import_hash'] = Variable<String>(importHash);
    }
    if (!nullToAbsent || recurringTransactionId != null) {
      map['recurring_transaction_id'] = Variable<String>(
        recurringTransactionId,
      );
    }
    if (!nullToAbsent || linkedTransactionId != null) {
      map['linked_transaction_id'] = Variable<String>(linkedTransactionId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      ownerId: Value(ownerId),
      realAccountId: Value(realAccountId),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      payee: payee == null && nullToAbsent
          ? const Value.absent()
          : Value(payee),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      amount: Value(amount),
      type: Value(type),
      transactionDate: Value(transactionDate),
      valueDate: valueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(valueDate),
      visibilityDate: visibilityDate == null && nullToAbsent
          ? const Value.absent()
          : Value(visibilityDate),
      syncDate: syncDate == null && nullToAbsent
          ? const Value.absent()
          : Value(syncDate),
      provisionDate: provisionDate == null && nullToAbsent
          ? const Value.absent()
          : Value(provisionDate),
      step: Value(step),
      status: Value(status),
      importHash: importHash == null && nullToAbsent
          ? const Value.absent()
          : Value(importHash),
      recurringTransactionId: recurringTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurringTransactionId),
      linkedTransactionId: linkedTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedTransactionId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TransactionData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionData(
      id: serializer.fromJson<String>(json['id']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      realAccountId: serializer.fromJson<String>(json['realAccountId']),
      label: serializer.fromJson<String?>(json['label']),
      note: serializer.fromJson<String?>(json['note']),
      payee: serializer.fromJson<String?>(json['payee']),
      category: serializer.fromJson<String?>(json['category']),
      amount: serializer.fromJson<double>(json['amount']),
      type: serializer.fromJson<String>(json['type']),
      transactionDate: serializer.fromJson<DateTime>(json['transactionDate']),
      valueDate: serializer.fromJson<DateTime?>(json['valueDate']),
      visibilityDate: serializer.fromJson<DateTime?>(json['visibilityDate']),
      syncDate: serializer.fromJson<DateTime?>(json['syncDate']),
      provisionDate: serializer.fromJson<DateTime?>(json['provisionDate']),
      step: serializer.fromJson<String>(json['step']),
      status: serializer.fromJson<String>(json['status']),
      importHash: serializer.fromJson<String?>(json['importHash']),
      recurringTransactionId: serializer.fromJson<String?>(
        json['recurringTransactionId'],
      ),
      linkedTransactionId: serializer.fromJson<String?>(
        json['linkedTransactionId'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerId': serializer.toJson<String>(ownerId),
      'realAccountId': serializer.toJson<String>(realAccountId),
      'label': serializer.toJson<String?>(label),
      'note': serializer.toJson<String?>(note),
      'payee': serializer.toJson<String?>(payee),
      'category': serializer.toJson<String?>(category),
      'amount': serializer.toJson<double>(amount),
      'type': serializer.toJson<String>(type),
      'transactionDate': serializer.toJson<DateTime>(transactionDate),
      'valueDate': serializer.toJson<DateTime?>(valueDate),
      'visibilityDate': serializer.toJson<DateTime?>(visibilityDate),
      'syncDate': serializer.toJson<DateTime?>(syncDate),
      'provisionDate': serializer.toJson<DateTime?>(provisionDate),
      'step': serializer.toJson<String>(step),
      'status': serializer.toJson<String>(status),
      'importHash': serializer.toJson<String?>(importHash),
      'recurringTransactionId': serializer.toJson<String?>(
        recurringTransactionId,
      ),
      'linkedTransactionId': serializer.toJson<String?>(linkedTransactionId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TransactionData copyWith({
    String? id,
    String? ownerId,
    String? realAccountId,
    Value<String?> label = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<String?> payee = const Value.absent(),
    Value<String?> category = const Value.absent(),
    double? amount,
    String? type,
    DateTime? transactionDate,
    Value<DateTime?> valueDate = const Value.absent(),
    Value<DateTime?> visibilityDate = const Value.absent(),
    Value<DateTime?> syncDate = const Value.absent(),
    Value<DateTime?> provisionDate = const Value.absent(),
    String? step,
    String? status,
    Value<String?> importHash = const Value.absent(),
    Value<String?> recurringTransactionId = const Value.absent(),
    Value<String?> linkedTransactionId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TransactionData(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    realAccountId: realAccountId ?? this.realAccountId,
    label: label.present ? label.value : this.label,
    note: note.present ? note.value : this.note,
    payee: payee.present ? payee.value : this.payee,
    category: category.present ? category.value : this.category,
    amount: amount ?? this.amount,
    type: type ?? this.type,
    transactionDate: transactionDate ?? this.transactionDate,
    valueDate: valueDate.present ? valueDate.value : this.valueDate,
    visibilityDate: visibilityDate.present
        ? visibilityDate.value
        : this.visibilityDate,
    syncDate: syncDate.present ? syncDate.value : this.syncDate,
    provisionDate: provisionDate.present
        ? provisionDate.value
        : this.provisionDate,
    step: step ?? this.step,
    status: status ?? this.status,
    importHash: importHash.present ? importHash.value : this.importHash,
    recurringTransactionId: recurringTransactionId.present
        ? recurringTransactionId.value
        : this.recurringTransactionId,
    linkedTransactionId: linkedTransactionId.present
        ? linkedTransactionId.value
        : this.linkedTransactionId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TransactionData copyWithCompanion(TransactionsCompanion data) {
    return TransactionData(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      realAccountId: data.realAccountId.present
          ? data.realAccountId.value
          : this.realAccountId,
      label: data.label.present ? data.label.value : this.label,
      note: data.note.present ? data.note.value : this.note,
      payee: data.payee.present ? data.payee.value : this.payee,
      category: data.category.present ? data.category.value : this.category,
      amount: data.amount.present ? data.amount.value : this.amount,
      type: data.type.present ? data.type.value : this.type,
      transactionDate: data.transactionDate.present
          ? data.transactionDate.value
          : this.transactionDate,
      valueDate: data.valueDate.present ? data.valueDate.value : this.valueDate,
      visibilityDate: data.visibilityDate.present
          ? data.visibilityDate.value
          : this.visibilityDate,
      syncDate: data.syncDate.present ? data.syncDate.value : this.syncDate,
      provisionDate: data.provisionDate.present
          ? data.provisionDate.value
          : this.provisionDate,
      step: data.step.present ? data.step.value : this.step,
      status: data.status.present ? data.status.value : this.status,
      importHash: data.importHash.present
          ? data.importHash.value
          : this.importHash,
      recurringTransactionId: data.recurringTransactionId.present
          ? data.recurringTransactionId.value
          : this.recurringTransactionId,
      linkedTransactionId: data.linkedTransactionId.present
          ? data.linkedTransactionId.value
          : this.linkedTransactionId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionData(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('realAccountId: $realAccountId, ')
          ..write('label: $label, ')
          ..write('note: $note, ')
          ..write('payee: $payee, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('valueDate: $valueDate, ')
          ..write('visibilityDate: $visibilityDate, ')
          ..write('syncDate: $syncDate, ')
          ..write('provisionDate: $provisionDate, ')
          ..write('step: $step, ')
          ..write('status: $status, ')
          ..write('importHash: $importHash, ')
          ..write('recurringTransactionId: $recurringTransactionId, ')
          ..write('linkedTransactionId: $linkedTransactionId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    ownerId,
    realAccountId,
    label,
    note,
    payee,
    category,
    amount,
    type,
    transactionDate,
    valueDate,
    visibilityDate,
    syncDate,
    provisionDate,
    step,
    status,
    importHash,
    recurringTransactionId,
    linkedTransactionId,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionData &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.realAccountId == this.realAccountId &&
          other.label == this.label &&
          other.note == this.note &&
          other.payee == this.payee &&
          other.category == this.category &&
          other.amount == this.amount &&
          other.type == this.type &&
          other.transactionDate == this.transactionDate &&
          other.valueDate == this.valueDate &&
          other.visibilityDate == this.visibilityDate &&
          other.syncDate == this.syncDate &&
          other.provisionDate == this.provisionDate &&
          other.step == this.step &&
          other.status == this.status &&
          other.importHash == this.importHash &&
          other.recurringTransactionId == this.recurringTransactionId &&
          other.linkedTransactionId == this.linkedTransactionId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TransactionsCompanion extends UpdateCompanion<TransactionData> {
  final Value<String> id;
  final Value<String> ownerId;
  final Value<String> realAccountId;
  final Value<String?> label;
  final Value<String?> note;
  final Value<String?> payee;
  final Value<String?> category;
  final Value<double> amount;
  final Value<String> type;
  final Value<DateTime> transactionDate;
  final Value<DateTime?> valueDate;
  final Value<DateTime?> visibilityDate;
  final Value<DateTime?> syncDate;
  final Value<DateTime?> provisionDate;
  final Value<String> step;
  final Value<String> status;
  final Value<String?> importHash;
  final Value<String?> recurringTransactionId;
  final Value<String?> linkedTransactionId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.realAccountId = const Value.absent(),
    this.label = const Value.absent(),
    this.note = const Value.absent(),
    this.payee = const Value.absent(),
    this.category = const Value.absent(),
    this.amount = const Value.absent(),
    this.type = const Value.absent(),
    this.transactionDate = const Value.absent(),
    this.valueDate = const Value.absent(),
    this.visibilityDate = const Value.absent(),
    this.syncDate = const Value.absent(),
    this.provisionDate = const Value.absent(),
    this.step = const Value.absent(),
    this.status = const Value.absent(),
    this.importHash = const Value.absent(),
    this.recurringTransactionId = const Value.absent(),
    this.linkedTransactionId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String ownerId,
    required String realAccountId,
    this.label = const Value.absent(),
    this.note = const Value.absent(),
    this.payee = const Value.absent(),
    this.category = const Value.absent(),
    required double amount,
    required String type,
    required DateTime transactionDate,
    this.valueDate = const Value.absent(),
    this.visibilityDate = const Value.absent(),
    this.syncDate = const Value.absent(),
    this.provisionDate = const Value.absent(),
    required String step,
    required String status,
    this.importHash = const Value.absent(),
    this.recurringTransactionId = const Value.absent(),
    this.linkedTransactionId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ownerId = Value(ownerId),
       realAccountId = Value(realAccountId),
       amount = Value(amount),
       type = Value(type),
       transactionDate = Value(transactionDate),
       step = Value(step),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TransactionData> custom({
    Expression<String>? id,
    Expression<String>? ownerId,
    Expression<String>? realAccountId,
    Expression<String>? label,
    Expression<String>? note,
    Expression<String>? payee,
    Expression<String>? category,
    Expression<double>? amount,
    Expression<String>? type,
    Expression<DateTime>? transactionDate,
    Expression<DateTime>? valueDate,
    Expression<DateTime>? visibilityDate,
    Expression<DateTime>? syncDate,
    Expression<DateTime>? provisionDate,
    Expression<String>? step,
    Expression<String>? status,
    Expression<String>? importHash,
    Expression<String>? recurringTransactionId,
    Expression<String>? linkedTransactionId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (realAccountId != null) 'real_account_id': realAccountId,
      if (label != null) 'label': label,
      if (note != null) 'note': note,
      if (payee != null) 'payee': payee,
      if (category != null) 'category': category,
      if (amount != null) 'amount': amount,
      if (type != null) 'type': type,
      if (transactionDate != null) 'transaction_date': transactionDate,
      if (valueDate != null) 'value_date': valueDate,
      if (visibilityDate != null) 'visibility_date': visibilityDate,
      if (syncDate != null) 'sync_date': syncDate,
      if (provisionDate != null) 'provision_date': provisionDate,
      if (step != null) 'step': step,
      if (status != null) 'status': status,
      if (importHash != null) 'import_hash': importHash,
      if (recurringTransactionId != null)
        'recurring_transaction_id': recurringTransactionId,
      if (linkedTransactionId != null)
        'linked_transaction_id': linkedTransactionId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? ownerId,
    Value<String>? realAccountId,
    Value<String?>? label,
    Value<String?>? note,
    Value<String?>? payee,
    Value<String?>? category,
    Value<double>? amount,
    Value<String>? type,
    Value<DateTime>? transactionDate,
    Value<DateTime?>? valueDate,
    Value<DateTime?>? visibilityDate,
    Value<DateTime?>? syncDate,
    Value<DateTime?>? provisionDate,
    Value<String>? step,
    Value<String>? status,
    Value<String?>? importHash,
    Value<String?>? recurringTransactionId,
    Value<String?>? linkedTransactionId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      realAccountId: realAccountId ?? this.realAccountId,
      label: label ?? this.label,
      note: note ?? this.note,
      payee: payee ?? this.payee,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      transactionDate: transactionDate ?? this.transactionDate,
      valueDate: valueDate ?? this.valueDate,
      visibilityDate: visibilityDate ?? this.visibilityDate,
      syncDate: syncDate ?? this.syncDate,
      provisionDate: provisionDate ?? this.provisionDate,
      step: step ?? this.step,
      status: status ?? this.status,
      importHash: importHash ?? this.importHash,
      recurringTransactionId:
          recurringTransactionId ?? this.recurringTransactionId,
      linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (realAccountId.present) {
      map['real_account_id'] = Variable<String>(realAccountId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (payee.present) {
      map['payee'] = Variable<String>(payee.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (transactionDate.present) {
      map['transaction_date'] = Variable<DateTime>(transactionDate.value);
    }
    if (valueDate.present) {
      map['value_date'] = Variable<DateTime>(valueDate.value);
    }
    if (visibilityDate.present) {
      map['visibility_date'] = Variable<DateTime>(visibilityDate.value);
    }
    if (syncDate.present) {
      map['sync_date'] = Variable<DateTime>(syncDate.value);
    }
    if (provisionDate.present) {
      map['provision_date'] = Variable<DateTime>(provisionDate.value);
    }
    if (step.present) {
      map['step'] = Variable<String>(step.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (importHash.present) {
      map['import_hash'] = Variable<String>(importHash.value);
    }
    if (recurringTransactionId.present) {
      map['recurring_transaction_id'] = Variable<String>(
        recurringTransactionId.value,
      );
    }
    if (linkedTransactionId.present) {
      map['linked_transaction_id'] = Variable<String>(
        linkedTransactionId.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('realAccountId: $realAccountId, ')
          ..write('label: $label, ')
          ..write('note: $note, ')
          ..write('payee: $payee, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('valueDate: $valueDate, ')
          ..write('visibilityDate: $visibilityDate, ')
          ..write('syncDate: $syncDate, ')
          ..write('provisionDate: $provisionDate, ')
          ..write('step: $step, ')
          ..write('status: $status, ')
          ..write('importHash: $importHash, ')
          ..write('recurringTransactionId: $recurringTransactionId, ')
          ..write('linkedTransactionId: $linkedTransactionId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionSplitsTable extends TransactionSplits
    with TableInfo<$TransactionSplitsTable, TransactionSplitData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionSplitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES transactions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _virtualAccountIdMeta = const VerificationMeta(
    'virtualAccountId',
  );
  @override
  late final GeneratedColumn<String> virtualAccountId = GeneratedColumn<String>(
    'virtual_account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES virtual_accounts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transactionId,
    virtualAccountId,
    amount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_splits';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionSplitData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('virtual_account_id')) {
      context.handle(
        _virtualAccountIdMeta,
        virtualAccountId.isAcceptableOrUnknown(
          data['virtual_account_id']!,
          _virtualAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_virtualAccountIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionSplitData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionSplitData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      )!,
      virtualAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}virtual_account_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
    );
  }

  @override
  $TransactionSplitsTable createAlias(String alias) {
    return $TransactionSplitsTable(attachedDatabase, alias);
  }
}

class TransactionSplitData extends DataClass
    implements Insertable<TransactionSplitData> {
  final String id;
  final String transactionId;
  final String virtualAccountId;
  final double amount;
  const TransactionSplitData({
    required this.id,
    required this.transactionId,
    required this.virtualAccountId,
    required this.amount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transaction_id'] = Variable<String>(transactionId);
    map['virtual_account_id'] = Variable<String>(virtualAccountId);
    map['amount'] = Variable<double>(amount);
    return map;
  }

  TransactionSplitsCompanion toCompanion(bool nullToAbsent) {
    return TransactionSplitsCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      virtualAccountId: Value(virtualAccountId),
      amount: Value(amount),
    );
  }

  factory TransactionSplitData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionSplitData(
      id: serializer.fromJson<String>(json['id']),
      transactionId: serializer.fromJson<String>(json['transactionId']),
      virtualAccountId: serializer.fromJson<String>(json['virtualAccountId']),
      amount: serializer.fromJson<double>(json['amount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transactionId': serializer.toJson<String>(transactionId),
      'virtualAccountId': serializer.toJson<String>(virtualAccountId),
      'amount': serializer.toJson<double>(amount),
    };
  }

  TransactionSplitData copyWith({
    String? id,
    String? transactionId,
    String? virtualAccountId,
    double? amount,
  }) => TransactionSplitData(
    id: id ?? this.id,
    transactionId: transactionId ?? this.transactionId,
    virtualAccountId: virtualAccountId ?? this.virtualAccountId,
    amount: amount ?? this.amount,
  );
  TransactionSplitData copyWithCompanion(TransactionSplitsCompanion data) {
    return TransactionSplitData(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      virtualAccountId: data.virtualAccountId.present
          ? data.virtualAccountId.value
          : this.virtualAccountId,
      amount: data.amount.present ? data.amount.value : this.amount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionSplitData(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('virtualAccountId: $virtualAccountId, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, transactionId, virtualAccountId, amount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionSplitData &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.virtualAccountId == this.virtualAccountId &&
          other.amount == this.amount);
}

class TransactionSplitsCompanion extends UpdateCompanion<TransactionSplitData> {
  final Value<String> id;
  final Value<String> transactionId;
  final Value<String> virtualAccountId;
  final Value<double> amount;
  final Value<int> rowid;
  const TransactionSplitsCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.virtualAccountId = const Value.absent(),
    this.amount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionSplitsCompanion.insert({
    required String id,
    required String transactionId,
    required String virtualAccountId,
    required double amount,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       transactionId = Value(transactionId),
       virtualAccountId = Value(virtualAccountId),
       amount = Value(amount);
  static Insertable<TransactionSplitData> custom({
    Expression<String>? id,
    Expression<String>? transactionId,
    Expression<String>? virtualAccountId,
    Expression<double>? amount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (virtualAccountId != null) 'virtual_account_id': virtualAccountId,
      if (amount != null) 'amount': amount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionSplitsCompanion copyWith({
    Value<String>? id,
    Value<String>? transactionId,
    Value<String>? virtualAccountId,
    Value<double>? amount,
    Value<int>? rowid,
  }) {
    return TransactionSplitsCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      virtualAccountId: virtualAccountId ?? this.virtualAccountId,
      amount: amount ?? this.amount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (virtualAccountId.present) {
      map['virtual_account_id'] = Variable<String>(virtualAccountId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionSplitsCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('virtualAccountId: $virtualAccountId, ')
          ..write('amount: $amount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOutboxTable extends SyncOutbox
    with TableInfo<$SyncOutboxTable, SyncOutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _targetTableMeta = const VerificationMeta(
    'targetTable',
  );
  @override
  late final GeneratedColumn<String> targetTable = GeneratedColumn<String>(
    'target_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    targetTable,
    recordId,
    action,
    payload,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('target_table')) {
      context.handle(
        _targetTableMeta,
        targetTable.isAcceptableOrUnknown(
          data['target_table']!,
          _targetTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetTableMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncOutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOutboxData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      targetTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_table'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SyncOutboxTable createAlias(String alias) {
    return $SyncOutboxTable(attachedDatabase, alias);
  }
}

class SyncOutboxData extends DataClass implements Insertable<SyncOutboxData> {
  final int id;
  final String targetTable;
  final String recordId;
  final String action;
  final String payload;
  final DateTime createdAt;
  const SyncOutboxData({
    required this.id,
    required this.targetTable,
    required this.recordId,
    required this.action,
    required this.payload,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['target_table'] = Variable<String>(targetTable);
    map['record_id'] = Variable<String>(recordId);
    map['action'] = Variable<String>(action);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncOutboxCompanion toCompanion(bool nullToAbsent) {
    return SyncOutboxCompanion(
      id: Value(id),
      targetTable: Value(targetTable),
      recordId: Value(recordId),
      action: Value(action),
      payload: Value(payload),
      createdAt: Value(createdAt),
    );
  }

  factory SyncOutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOutboxData(
      id: serializer.fromJson<int>(json['id']),
      targetTable: serializer.fromJson<String>(json['targetTable']),
      recordId: serializer.fromJson<String>(json['recordId']),
      action: serializer.fromJson<String>(json['action']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'targetTable': serializer.toJson<String>(targetTable),
      'recordId': serializer.toJson<String>(recordId),
      'action': serializer.toJson<String>(action),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncOutboxData copyWith({
    int? id,
    String? targetTable,
    String? recordId,
    String? action,
    String? payload,
    DateTime? createdAt,
  }) => SyncOutboxData(
    id: id ?? this.id,
    targetTable: targetTable ?? this.targetTable,
    recordId: recordId ?? this.recordId,
    action: action ?? this.action,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncOutboxData copyWithCompanion(SyncOutboxCompanion data) {
    return SyncOutboxData(
      id: data.id.present ? data.id.value : this.id,
      targetTable: data.targetTable.present
          ? data.targetTable.value
          : this.targetTable,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      action: data.action.present ? data.action.value : this.action,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxData(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('recordId: $recordId, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, targetTable, recordId, action, payload, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOutboxData &&
          other.id == this.id &&
          other.targetTable == this.targetTable &&
          other.recordId == this.recordId &&
          other.action == this.action &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt);
}

class SyncOutboxCompanion extends UpdateCompanion<SyncOutboxData> {
  final Value<int> id;
  final Value<String> targetTable;
  final Value<String> recordId;
  final Value<String> action;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  const SyncOutboxCompanion({
    this.id = const Value.absent(),
    this.targetTable = const Value.absent(),
    this.recordId = const Value.absent(),
    this.action = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncOutboxCompanion.insert({
    this.id = const Value.absent(),
    required String targetTable,
    required String recordId,
    required String action,
    required String payload,
    required DateTime createdAt,
  }) : targetTable = Value(targetTable),
       recordId = Value(recordId),
       action = Value(action),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<SyncOutboxData> custom({
    Expression<int>? id,
    Expression<String>? targetTable,
    Expression<String>? recordId,
    Expression<String>? action,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetTable != null) 'target_table': targetTable,
      if (recordId != null) 'record_id': recordId,
      if (action != null) 'action': action,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncOutboxCompanion copyWith({
    Value<int>? id,
    Value<String>? targetTable,
    Value<String>? recordId,
    Value<String>? action,
    Value<String>? payload,
    Value<DateTime>? createdAt,
  }) {
    return SyncOutboxCompanion(
      id: id ?? this.id,
      targetTable: targetTable ?? this.targetTable,
      recordId: recordId ?? this.recordId,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (targetTable.present) {
      map['target_table'] = Variable<String>(targetTable.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxCompanion(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('recordId: $recordId, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $RealAccountsTable realAccounts = $RealAccountsTable(this);
  late final $VirtualAccountsTable virtualAccounts = $VirtualAccountsTable(
    this,
  );
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $TransactionSplitsTable transactionSplits =
      $TransactionSplitsTable(this);
  late final $SyncOutboxTable syncOutbox = $SyncOutboxTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    realAccounts,
    virtualAccounts,
    transactions,
    transactionSplits,
    syncOutbox,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'real_accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('virtual_accounts', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'real_accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('transactions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'transactions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('transaction_splits', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'virtual_accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('transaction_splits', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$RealAccountsTableCreateCompanionBuilder =
    RealAccountsCompanion Function({
      required String id,
      required String ownerId,
      required String name,
      Value<String?> bankName,
      Value<double> initialBalance,
      Value<double> balance,
      required String type,
      Value<bool> isPrincipal,
      required String sharedWithUserIds,
      Value<DateTime?> openingDate,
      Value<String?> accountNumber,
      Value<String?> officialName,
      Value<String?> iban,
      Value<String?> bic,
      Value<String?> swift,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$RealAccountsTableUpdateCompanionBuilder =
    RealAccountsCompanion Function({
      Value<String> id,
      Value<String> ownerId,
      Value<String> name,
      Value<String?> bankName,
      Value<double> initialBalance,
      Value<double> balance,
      Value<String> type,
      Value<bool> isPrincipal,
      Value<String> sharedWithUserIds,
      Value<DateTime?> openingDate,
      Value<String?> accountNumber,
      Value<String?> officialName,
      Value<String?> iban,
      Value<String?> bic,
      Value<String?> swift,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$RealAccountsTableReferences
    extends
        BaseReferences<_$LocalDatabase, $RealAccountsTable, RealAccountData> {
  $$RealAccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$VirtualAccountsTable, List<VirtualAccountData>>
  _virtualAccountsRefsTable(_$LocalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.virtualAccounts,
        aliasName: $_aliasNameGenerator(
          db.realAccounts.id,
          db.virtualAccounts.realAccountId,
        ),
      );

  $$VirtualAccountsTableProcessedTableManager get virtualAccountsRefs {
    final manager = $$VirtualAccountsTableTableManager(
      $_db,
      $_db.virtualAccounts,
    ).filter((f) => f.realAccountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _virtualAccountsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<TransactionData>>
  _transactionsRefsTable(_$LocalDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: $_aliasNameGenerator(
      db.realAccounts.id,
      db.transactions.realAccountId,
    ),
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.realAccountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RealAccountsTableFilterComposer
    extends Composer<_$LocalDatabase, $RealAccountsTable> {
  $$RealAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get initialBalance => $composableBuilder(
    column: $table.initialBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrincipal => $composableBuilder(
    column: $table.isPrincipal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sharedWithUserIds => $composableBuilder(
    column: $table.sharedWithUserIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openingDate => $composableBuilder(
    column: $table.openingDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountNumber => $composableBuilder(
    column: $table.accountNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get officialName => $composableBuilder(
    column: $table.officialName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iban => $composableBuilder(
    column: $table.iban,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bic => $composableBuilder(
    column: $table.bic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get swift => $composableBuilder(
    column: $table.swift,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> virtualAccountsRefs(
    Expression<bool> Function($$VirtualAccountsTableFilterComposer f) f,
  ) {
    final $$VirtualAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.virtualAccounts,
      getReferencedColumn: (t) => t.realAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VirtualAccountsTableFilterComposer(
            $db: $db,
            $table: $db.virtualAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.realAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RealAccountsTableOrderingComposer
    extends Composer<_$LocalDatabase, $RealAccountsTable> {
  $$RealAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get initialBalance => $composableBuilder(
    column: $table.initialBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrincipal => $composableBuilder(
    column: $table.isPrincipal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sharedWithUserIds => $composableBuilder(
    column: $table.sharedWithUserIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openingDate => $composableBuilder(
    column: $table.openingDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountNumber => $composableBuilder(
    column: $table.accountNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get officialName => $composableBuilder(
    column: $table.officialName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iban => $composableBuilder(
    column: $table.iban,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bic => $composableBuilder(
    column: $table.bic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get swift => $composableBuilder(
    column: $table.swift,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RealAccountsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $RealAccountsTable> {
  $$RealAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get bankName =>
      $composableBuilder(column: $table.bankName, builder: (column) => column);

  GeneratedColumn<double> get initialBalance => $composableBuilder(
    column: $table.initialBalance,
    builder: (column) => column,
  );

  GeneratedColumn<double> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<bool> get isPrincipal => $composableBuilder(
    column: $table.isPrincipal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sharedWithUserIds => $composableBuilder(
    column: $table.sharedWithUserIds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get openingDate => $composableBuilder(
    column: $table.openingDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountNumber => $composableBuilder(
    column: $table.accountNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get officialName => $composableBuilder(
    column: $table.officialName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iban =>
      $composableBuilder(column: $table.iban, builder: (column) => column);

  GeneratedColumn<String> get bic =>
      $composableBuilder(column: $table.bic, builder: (column) => column);

  GeneratedColumn<String> get swift =>
      $composableBuilder(column: $table.swift, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> virtualAccountsRefs<T extends Object>(
    Expression<T> Function($$VirtualAccountsTableAnnotationComposer a) f,
  ) {
    final $$VirtualAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.virtualAccounts,
      getReferencedColumn: (t) => t.realAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VirtualAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.virtualAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.realAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RealAccountsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $RealAccountsTable,
          RealAccountData,
          $$RealAccountsTableFilterComposer,
          $$RealAccountsTableOrderingComposer,
          $$RealAccountsTableAnnotationComposer,
          $$RealAccountsTableCreateCompanionBuilder,
          $$RealAccountsTableUpdateCompanionBuilder,
          (RealAccountData, $$RealAccountsTableReferences),
          RealAccountData,
          PrefetchHooks Function({
            bool virtualAccountsRefs,
            bool transactionsRefs,
          })
        > {
  $$RealAccountsTableTableManager(_$LocalDatabase db, $RealAccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RealAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RealAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RealAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> bankName = const Value.absent(),
                Value<double> initialBalance = const Value.absent(),
                Value<double> balance = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<bool> isPrincipal = const Value.absent(),
                Value<String> sharedWithUserIds = const Value.absent(),
                Value<DateTime?> openingDate = const Value.absent(),
                Value<String?> accountNumber = const Value.absent(),
                Value<String?> officialName = const Value.absent(),
                Value<String?> iban = const Value.absent(),
                Value<String?> bic = const Value.absent(),
                Value<String?> swift = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RealAccountsCompanion(
                id: id,
                ownerId: ownerId,
                name: name,
                bankName: bankName,
                initialBalance: initialBalance,
                balance: balance,
                type: type,
                isPrincipal: isPrincipal,
                sharedWithUserIds: sharedWithUserIds,
                openingDate: openingDate,
                accountNumber: accountNumber,
                officialName: officialName,
                iban: iban,
                bic: bic,
                swift: swift,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ownerId,
                required String name,
                Value<String?> bankName = const Value.absent(),
                Value<double> initialBalance = const Value.absent(),
                Value<double> balance = const Value.absent(),
                required String type,
                Value<bool> isPrincipal = const Value.absent(),
                required String sharedWithUserIds,
                Value<DateTime?> openingDate = const Value.absent(),
                Value<String?> accountNumber = const Value.absent(),
                Value<String?> officialName = const Value.absent(),
                Value<String?> iban = const Value.absent(),
                Value<String?> bic = const Value.absent(),
                Value<String?> swift = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => RealAccountsCompanion.insert(
                id: id,
                ownerId: ownerId,
                name: name,
                bankName: bankName,
                initialBalance: initialBalance,
                balance: balance,
                type: type,
                isPrincipal: isPrincipal,
                sharedWithUserIds: sharedWithUserIds,
                openingDate: openingDate,
                accountNumber: accountNumber,
                officialName: officialName,
                iban: iban,
                bic: bic,
                swift: swift,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RealAccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({virtualAccountsRefs = false, transactionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (virtualAccountsRefs) db.virtualAccounts,
                    if (transactionsRefs) db.transactions,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (virtualAccountsRefs)
                        await $_getPrefetchedData<
                          RealAccountData,
                          $RealAccountsTable,
                          VirtualAccountData
                        >(
                          currentTable: table,
                          referencedTable: $$RealAccountsTableReferences
                              ._virtualAccountsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RealAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).virtualAccountsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.realAccountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (transactionsRefs)
                        await $_getPrefetchedData<
                          RealAccountData,
                          $RealAccountsTable,
                          TransactionData
                        >(
                          currentTable: table,
                          referencedTable: $$RealAccountsTableReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RealAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.realAccountId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RealAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $RealAccountsTable,
      RealAccountData,
      $$RealAccountsTableFilterComposer,
      $$RealAccountsTableOrderingComposer,
      $$RealAccountsTableAnnotationComposer,
      $$RealAccountsTableCreateCompanionBuilder,
      $$RealAccountsTableUpdateCompanionBuilder,
      (RealAccountData, $$RealAccountsTableReferences),
      RealAccountData,
      PrefetchHooks Function({bool virtualAccountsRefs, bool transactionsRefs})
    >;
typedef $$VirtualAccountsTableCreateCompanionBuilder =
    VirtualAccountsCompanion Function({
      required String id,
      required String userId,
      required String realAccountId,
      required String name,
      Value<double> balance,
      required String type,
      Value<String?> icon,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$VirtualAccountsTableUpdateCompanionBuilder =
    VirtualAccountsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> realAccountId,
      Value<String> name,
      Value<double> balance,
      Value<String> type,
      Value<String?> icon,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$VirtualAccountsTableReferences
    extends
        BaseReferences<
          _$LocalDatabase,
          $VirtualAccountsTable,
          VirtualAccountData
        > {
  $$VirtualAccountsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RealAccountsTable _realAccountIdTable(_$LocalDatabase db) =>
      db.realAccounts.createAlias(
        $_aliasNameGenerator(
          db.virtualAccounts.realAccountId,
          db.realAccounts.id,
        ),
      );

  $$RealAccountsTableProcessedTableManager get realAccountId {
    final $_column = $_itemColumn<String>('real_account_id')!;

    final manager = $$RealAccountsTableTableManager(
      $_db,
      $_db.realAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_realAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $TransactionSplitsTable,
    List<TransactionSplitData>
  >
  _transactionSplitsRefsTable(_$LocalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.transactionSplits,
        aliasName: $_aliasNameGenerator(
          db.virtualAccounts.id,
          db.transactionSplits.virtualAccountId,
        ),
      );

  $$TransactionSplitsTableProcessedTableManager get transactionSplitsRefs {
    final manager =
        $$TransactionSplitsTableTableManager(
          $_db,
          $_db.transactionSplits,
        ).filter(
          (f) => f.virtualAccountId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _transactionSplitsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VirtualAccountsTableFilterComposer
    extends Composer<_$LocalDatabase, $VirtualAccountsTable> {
  $$VirtualAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RealAccountsTableFilterComposer get realAccountId {
    final $$RealAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.realAccountId,
      referencedTable: $db.realAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RealAccountsTableFilterComposer(
            $db: $db,
            $table: $db.realAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> transactionSplitsRefs(
    Expression<bool> Function($$TransactionSplitsTableFilterComposer f) f,
  ) {
    final $$TransactionSplitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionSplits,
      getReferencedColumn: (t) => t.virtualAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionSplitsTableFilterComposer(
            $db: $db,
            $table: $db.transactionSplits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VirtualAccountsTableOrderingComposer
    extends Composer<_$LocalDatabase, $VirtualAccountsTable> {
  $$VirtualAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RealAccountsTableOrderingComposer get realAccountId {
    final $$RealAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.realAccountId,
      referencedTable: $db.realAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RealAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.realAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VirtualAccountsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $VirtualAccountsTable> {
  $$VirtualAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$RealAccountsTableAnnotationComposer get realAccountId {
    final $$RealAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.realAccountId,
      referencedTable: $db.realAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RealAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.realAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> transactionSplitsRefs<T extends Object>(
    Expression<T> Function($$TransactionSplitsTableAnnotationComposer a) f,
  ) {
    final $$TransactionSplitsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.transactionSplits,
          getReferencedColumn: (t) => t.virtualAccountId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionSplitsTableAnnotationComposer(
                $db: $db,
                $table: $db.transactionSplits,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$VirtualAccountsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $VirtualAccountsTable,
          VirtualAccountData,
          $$VirtualAccountsTableFilterComposer,
          $$VirtualAccountsTableOrderingComposer,
          $$VirtualAccountsTableAnnotationComposer,
          $$VirtualAccountsTableCreateCompanionBuilder,
          $$VirtualAccountsTableUpdateCompanionBuilder,
          (VirtualAccountData, $$VirtualAccountsTableReferences),
          VirtualAccountData,
          PrefetchHooks Function({
            bool realAccountId,
            bool transactionSplitsRefs,
          })
        > {
  $$VirtualAccountsTableTableManager(
    _$LocalDatabase db,
    $VirtualAccountsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VirtualAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VirtualAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VirtualAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> realAccountId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> balance = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VirtualAccountsCompanion(
                id: id,
                userId: userId,
                realAccountId: realAccountId,
                name: name,
                balance: balance,
                type: type,
                icon: icon,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String realAccountId,
                required String name,
                Value<double> balance = const Value.absent(),
                required String type,
                Value<String?> icon = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => VirtualAccountsCompanion.insert(
                id: id,
                userId: userId,
                realAccountId: realAccountId,
                name: name,
                balance: balance,
                type: type,
                icon: icon,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VirtualAccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({realAccountId = false, transactionSplitsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionSplitsRefs) db.transactionSplits,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (realAccountId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.realAccountId,
                                    referencedTable:
                                        $$VirtualAccountsTableReferences
                                            ._realAccountIdTable(db),
                                    referencedColumn:
                                        $$VirtualAccountsTableReferences
                                            ._realAccountIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionSplitsRefs)
                        await $_getPrefetchedData<
                          VirtualAccountData,
                          $VirtualAccountsTable,
                          TransactionSplitData
                        >(
                          currentTable: table,
                          referencedTable: $$VirtualAccountsTableReferences
                              ._transactionSplitsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VirtualAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionSplitsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.virtualAccountId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$VirtualAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $VirtualAccountsTable,
      VirtualAccountData,
      $$VirtualAccountsTableFilterComposer,
      $$VirtualAccountsTableOrderingComposer,
      $$VirtualAccountsTableAnnotationComposer,
      $$VirtualAccountsTableCreateCompanionBuilder,
      $$VirtualAccountsTableUpdateCompanionBuilder,
      (VirtualAccountData, $$VirtualAccountsTableReferences),
      VirtualAccountData,
      PrefetchHooks Function({bool realAccountId, bool transactionSplitsRefs})
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required String ownerId,
      required String realAccountId,
      Value<String?> label,
      Value<String?> note,
      Value<String?> payee,
      Value<String?> category,
      required double amount,
      required String type,
      required DateTime transactionDate,
      Value<DateTime?> valueDate,
      Value<DateTime?> visibilityDate,
      Value<DateTime?> syncDate,
      Value<DateTime?> provisionDate,
      required String step,
      required String status,
      Value<String?> importHash,
      Value<String?> recurringTransactionId,
      Value<String?> linkedTransactionId,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<String> ownerId,
      Value<String> realAccountId,
      Value<String?> label,
      Value<String?> note,
      Value<String?> payee,
      Value<String?> category,
      Value<double> amount,
      Value<String> type,
      Value<DateTime> transactionDate,
      Value<DateTime?> valueDate,
      Value<DateTime?> visibilityDate,
      Value<DateTime?> syncDate,
      Value<DateTime?> provisionDate,
      Value<String> step,
      Value<String> status,
      Value<String?> importHash,
      Value<String?> recurringTransactionId,
      Value<String?> linkedTransactionId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$TransactionsTableReferences
    extends
        BaseReferences<_$LocalDatabase, $TransactionsTable, TransactionData> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RealAccountsTable _realAccountIdTable(_$LocalDatabase db) =>
      db.realAccounts.createAlias(
        $_aliasNameGenerator(db.transactions.realAccountId, db.realAccounts.id),
      );

  $$RealAccountsTableProcessedTableManager get realAccountId {
    final $_column = $_itemColumn<String>('real_account_id')!;

    final manager = $$RealAccountsTableTableManager(
      $_db,
      $_db.realAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_realAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $TransactionSplitsTable,
    List<TransactionSplitData>
  >
  _transactionSplitsRefsTable(_$LocalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.transactionSplits,
        aliasName: $_aliasNameGenerator(
          db.transactions.id,
          db.transactionSplits.transactionId,
        ),
      );

  $$TransactionSplitsTableProcessedTableManager get transactionSplitsRefs {
    final manager = $$TransactionSplitsTableTableManager(
      $_db,
      $_db.transactionSplits,
    ).filter((f) => f.transactionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _transactionSplitsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$LocalDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payee => $composableBuilder(
    column: $table.payee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get valueDate => $composableBuilder(
    column: $table.valueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get visibilityDate => $composableBuilder(
    column: $table.visibilityDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncDate => $composableBuilder(
    column: $table.syncDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get provisionDate => $composableBuilder(
    column: $table.provisionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get importHash => $composableBuilder(
    column: $table.importHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurringTransactionId => $composableBuilder(
    column: $table.recurringTransactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedTransactionId => $composableBuilder(
    column: $table.linkedTransactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RealAccountsTableFilterComposer get realAccountId {
    final $$RealAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.realAccountId,
      referencedTable: $db.realAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RealAccountsTableFilterComposer(
            $db: $db,
            $table: $db.realAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> transactionSplitsRefs(
    Expression<bool> Function($$TransactionSplitsTableFilterComposer f) f,
  ) {
    final $$TransactionSplitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionSplits,
      getReferencedColumn: (t) => t.transactionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionSplitsTableFilterComposer(
            $db: $db,
            $table: $db.transactionSplits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$LocalDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payee => $composableBuilder(
    column: $table.payee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get valueDate => $composableBuilder(
    column: $table.valueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get visibilityDate => $composableBuilder(
    column: $table.visibilityDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncDate => $composableBuilder(
    column: $table.syncDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get provisionDate => $composableBuilder(
    column: $table.provisionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get importHash => $composableBuilder(
    column: $table.importHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurringTransactionId => $composableBuilder(
    column: $table.recurringTransactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedTransactionId => $composableBuilder(
    column: $table.linkedTransactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RealAccountsTableOrderingComposer get realAccountId {
    final $$RealAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.realAccountId,
      referencedTable: $db.realAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RealAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.realAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get payee =>
      $composableBuilder(column: $table.payee, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get valueDate =>
      $composableBuilder(column: $table.valueDate, builder: (column) => column);

  GeneratedColumn<DateTime> get visibilityDate => $composableBuilder(
    column: $table.visibilityDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncDate =>
      $composableBuilder(column: $table.syncDate, builder: (column) => column);

  GeneratedColumn<DateTime> get provisionDate => $composableBuilder(
    column: $table.provisionDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get step =>
      $composableBuilder(column: $table.step, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get importHash => $composableBuilder(
    column: $table.importHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurringTransactionId => $composableBuilder(
    column: $table.recurringTransactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get linkedTransactionId => $composableBuilder(
    column: $table.linkedTransactionId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$RealAccountsTableAnnotationComposer get realAccountId {
    final $$RealAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.realAccountId,
      referencedTable: $db.realAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RealAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.realAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> transactionSplitsRefs<T extends Object>(
    Expression<T> Function($$TransactionSplitsTableAnnotationComposer a) f,
  ) {
    final $$TransactionSplitsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.transactionSplits,
          getReferencedColumn: (t) => t.transactionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionSplitsTableAnnotationComposer(
                $db: $db,
                $table: $db.transactionSplits,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $TransactionsTable,
          TransactionData,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (TransactionData, $$TransactionsTableReferences),
          TransactionData,
          PrefetchHooks Function({
            bool realAccountId,
            bool transactionSplitsRefs,
          })
        > {
  $$TransactionsTableTableManager(_$LocalDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> realAccountId = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> payee = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> transactionDate = const Value.absent(),
                Value<DateTime?> valueDate = const Value.absent(),
                Value<DateTime?> visibilityDate = const Value.absent(),
                Value<DateTime?> syncDate = const Value.absent(),
                Value<DateTime?> provisionDate = const Value.absent(),
                Value<String> step = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> importHash = const Value.absent(),
                Value<String?> recurringTransactionId = const Value.absent(),
                Value<String?> linkedTransactionId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                ownerId: ownerId,
                realAccountId: realAccountId,
                label: label,
                note: note,
                payee: payee,
                category: category,
                amount: amount,
                type: type,
                transactionDate: transactionDate,
                valueDate: valueDate,
                visibilityDate: visibilityDate,
                syncDate: syncDate,
                provisionDate: provisionDate,
                step: step,
                status: status,
                importHash: importHash,
                recurringTransactionId: recurringTransactionId,
                linkedTransactionId: linkedTransactionId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ownerId,
                required String realAccountId,
                Value<String?> label = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> payee = const Value.absent(),
                Value<String?> category = const Value.absent(),
                required double amount,
                required String type,
                required DateTime transactionDate,
                Value<DateTime?> valueDate = const Value.absent(),
                Value<DateTime?> visibilityDate = const Value.absent(),
                Value<DateTime?> syncDate = const Value.absent(),
                Value<DateTime?> provisionDate = const Value.absent(),
                required String step,
                required String status,
                Value<String?> importHash = const Value.absent(),
                Value<String?> recurringTransactionId = const Value.absent(),
                Value<String?> linkedTransactionId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                ownerId: ownerId,
                realAccountId: realAccountId,
                label: label,
                note: note,
                payee: payee,
                category: category,
                amount: amount,
                type: type,
                transactionDate: transactionDate,
                valueDate: valueDate,
                visibilityDate: visibilityDate,
                syncDate: syncDate,
                provisionDate: provisionDate,
                step: step,
                status: status,
                importHash: importHash,
                recurringTransactionId: recurringTransactionId,
                linkedTransactionId: linkedTransactionId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({realAccountId = false, transactionSplitsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionSplitsRefs) db.transactionSplits,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (realAccountId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.realAccountId,
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._realAccountIdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._realAccountIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionSplitsRefs)
                        await $_getPrefetchedData<
                          TransactionData,
                          $TransactionsTable,
                          TransactionSplitData
                        >(
                          currentTable: table,
                          referencedTable: $$TransactionsTableReferences
                              ._transactionSplitsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TransactionsTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionSplitsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.transactionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $TransactionsTable,
      TransactionData,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (TransactionData, $$TransactionsTableReferences),
      TransactionData,
      PrefetchHooks Function({bool realAccountId, bool transactionSplitsRefs})
    >;
typedef $$TransactionSplitsTableCreateCompanionBuilder =
    TransactionSplitsCompanion Function({
      required String id,
      required String transactionId,
      required String virtualAccountId,
      required double amount,
      Value<int> rowid,
    });
typedef $$TransactionSplitsTableUpdateCompanionBuilder =
    TransactionSplitsCompanion Function({
      Value<String> id,
      Value<String> transactionId,
      Value<String> virtualAccountId,
      Value<double> amount,
      Value<int> rowid,
    });

final class $$TransactionSplitsTableReferences
    extends
        BaseReferences<
          _$LocalDatabase,
          $TransactionSplitsTable,
          TransactionSplitData
        > {
  $$TransactionSplitsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TransactionsTable _transactionIdTable(_$LocalDatabase db) =>
      db.transactions.createAlias(
        $_aliasNameGenerator(
          db.transactionSplits.transactionId,
          db.transactions.id,
        ),
      );

  $$TransactionsTableProcessedTableManager get transactionId {
    final $_column = $_itemColumn<String>('transaction_id')!;

    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $VirtualAccountsTable _virtualAccountIdTable(_$LocalDatabase db) =>
      db.virtualAccounts.createAlias(
        $_aliasNameGenerator(
          db.transactionSplits.virtualAccountId,
          db.virtualAccounts.id,
        ),
      );

  $$VirtualAccountsTableProcessedTableManager get virtualAccountId {
    final $_column = $_itemColumn<String>('virtual_account_id')!;

    final manager = $$VirtualAccountsTableTableManager(
      $_db,
      $_db.virtualAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_virtualAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionSplitsTableFilterComposer
    extends Composer<_$LocalDatabase, $TransactionSplitsTable> {
  $$TransactionSplitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  $$TransactionsTableFilterComposer get transactionId {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VirtualAccountsTableFilterComposer get virtualAccountId {
    final $$VirtualAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.virtualAccountId,
      referencedTable: $db.virtualAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VirtualAccountsTableFilterComposer(
            $db: $db,
            $table: $db.virtualAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionSplitsTableOrderingComposer
    extends Composer<_$LocalDatabase, $TransactionSplitsTable> {
  $$TransactionSplitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  $$TransactionsTableOrderingComposer get transactionId {
    final $$TransactionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableOrderingComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VirtualAccountsTableOrderingComposer get virtualAccountId {
    final $$VirtualAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.virtualAccountId,
      referencedTable: $db.virtualAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VirtualAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.virtualAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionSplitsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $TransactionSplitsTable> {
  $$TransactionSplitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  $$TransactionsTableAnnotationComposer get transactionId {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VirtualAccountsTableAnnotationComposer get virtualAccountId {
    final $$VirtualAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.virtualAccountId,
      referencedTable: $db.virtualAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VirtualAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.virtualAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionSplitsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $TransactionSplitsTable,
          TransactionSplitData,
          $$TransactionSplitsTableFilterComposer,
          $$TransactionSplitsTableOrderingComposer,
          $$TransactionSplitsTableAnnotationComposer,
          $$TransactionSplitsTableCreateCompanionBuilder,
          $$TransactionSplitsTableUpdateCompanionBuilder,
          (TransactionSplitData, $$TransactionSplitsTableReferences),
          TransactionSplitData,
          PrefetchHooks Function({bool transactionId, bool virtualAccountId})
        > {
  $$TransactionSplitsTableTableManager(
    _$LocalDatabase db,
    $TransactionSplitsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionSplitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionSplitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionSplitsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> transactionId = const Value.absent(),
                Value<String> virtualAccountId = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionSplitsCompanion(
                id: id,
                transactionId: transactionId,
                virtualAccountId: virtualAccountId,
                amount: amount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String transactionId,
                required String virtualAccountId,
                required double amount,
                Value<int> rowid = const Value.absent(),
              }) => TransactionSplitsCompanion.insert(
                id: id,
                transactionId: transactionId,
                virtualAccountId: virtualAccountId,
                amount: amount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransactionSplitsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({transactionId = false, virtualAccountId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (transactionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.transactionId,
                                    referencedTable:
                                        $$TransactionSplitsTableReferences
                                            ._transactionIdTable(db),
                                    referencedColumn:
                                        $$TransactionSplitsTableReferences
                                            ._transactionIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (virtualAccountId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.virtualAccountId,
                                    referencedTable:
                                        $$TransactionSplitsTableReferences
                                            ._virtualAccountIdTable(db),
                                    referencedColumn:
                                        $$TransactionSplitsTableReferences
                                            ._virtualAccountIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$TransactionSplitsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $TransactionSplitsTable,
      TransactionSplitData,
      $$TransactionSplitsTableFilterComposer,
      $$TransactionSplitsTableOrderingComposer,
      $$TransactionSplitsTableAnnotationComposer,
      $$TransactionSplitsTableCreateCompanionBuilder,
      $$TransactionSplitsTableUpdateCompanionBuilder,
      (TransactionSplitData, $$TransactionSplitsTableReferences),
      TransactionSplitData,
      PrefetchHooks Function({bool transactionId, bool virtualAccountId})
    >;
typedef $$SyncOutboxTableCreateCompanionBuilder =
    SyncOutboxCompanion Function({
      Value<int> id,
      required String targetTable,
      required String recordId,
      required String action,
      required String payload,
      required DateTime createdAt,
    });
typedef $$SyncOutboxTableUpdateCompanionBuilder =
    SyncOutboxCompanion Function({
      Value<int> id,
      Value<String> targetTable,
      Value<String> recordId,
      Value<String> action,
      Value<String> payload,
      Value<DateTime> createdAt,
    });

class $$SyncOutboxTableFilterComposer
    extends Composer<_$LocalDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncOutboxTableOrderingComposer
    extends Composer<_$LocalDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncOutboxTableAnnotationComposer
    extends Composer<_$LocalDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncOutboxTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $SyncOutboxTable,
          SyncOutboxData,
          $$SyncOutboxTableFilterComposer,
          $$SyncOutboxTableOrderingComposer,
          $$SyncOutboxTableAnnotationComposer,
          $$SyncOutboxTableCreateCompanionBuilder,
          $$SyncOutboxTableUpdateCompanionBuilder,
          (
            SyncOutboxData,
            BaseReferences<_$LocalDatabase, $SyncOutboxTable, SyncOutboxData>,
          ),
          SyncOutboxData,
          PrefetchHooks Function()
        > {
  $$SyncOutboxTableTableManager(_$LocalDatabase db, $SyncOutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> targetTable = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SyncOutboxCompanion(
                id: id,
                targetTable: targetTable,
                recordId: recordId,
                action: action,
                payload: payload,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String targetTable,
                required String recordId,
                required String action,
                required String payload,
                required DateTime createdAt,
              }) => SyncOutboxCompanion.insert(
                id: id,
                targetTable: targetTable,
                recordId: recordId,
                action: action,
                payload: payload,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $SyncOutboxTable,
      SyncOutboxData,
      $$SyncOutboxTableFilterComposer,
      $$SyncOutboxTableOrderingComposer,
      $$SyncOutboxTableAnnotationComposer,
      $$SyncOutboxTableCreateCompanionBuilder,
      $$SyncOutboxTableUpdateCompanionBuilder,
      (
        SyncOutboxData,
        BaseReferences<_$LocalDatabase, $SyncOutboxTable, SyncOutboxData>,
      ),
      SyncOutboxData,
      PrefetchHooks Function()
    >;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$RealAccountsTableTableManager get realAccounts =>
      $$RealAccountsTableTableManager(_db, _db.realAccounts);
  $$VirtualAccountsTableTableManager get virtualAccounts =>
      $$VirtualAccountsTableTableManager(_db, _db.virtualAccounts);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$TransactionSplitsTableTableManager get transactionSplits =>
      $$TransactionSplitsTableTableManager(_db, _db.transactionSplits);
  $$SyncOutboxTableTableManager get syncOutbox =>
      $$SyncOutboxTableTableManager(_db, _db.syncOutbox);
}

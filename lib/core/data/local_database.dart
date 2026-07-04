import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'local_database.g.dart';

@DataClassName('RealAccountData')
class RealAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text()();
  TextColumn get name => text()();
  TextColumn get bankName => text().nullable()();
  RealColumn get initialBalance => real().withDefault(const Constant(0.0))();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  TextColumn get type => text()(); // internal, external, externalGeneric
  BoolColumn get isPrincipal => boolean().withDefault(const Constant(false))();
  TextColumn get sharedWithUserIds => text()(); // Store as JSON string
  DateTimeColumn get openingDate => dateTime().nullable()();
  TextColumn get accountNumber => text().nullable()();
  TextColumn get officialName => text().nullable()();
  TextColumn get iban => text().nullable()();
  TextColumn get bic => text().nullable()();
  TextColumn get swift => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('VirtualAccountData')
class VirtualAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get realAccountId => text().references(RealAccounts, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  TextColumn get type => text()(); // systemFree, userBudget, systemCommitted, flowToDistribute
  TextColumn get icon => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionData')
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text()();
  TextColumn get realAccountId => text().references(RealAccounts, #id, onDelete: KeyAction.cascade)();
  TextColumn get label => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get payee => text().nullable()();
  TextColumn get category => text().nullable()();
  RealColumn get amount => real()();
  TextColumn get type => text()(); // debit, credit, provision, transfer
  DateTimeColumn get transactionDate => dateTime()();
  DateTimeColumn get valueDate => dateTime().nullable()();
  DateTimeColumn get visibilityDate => dateTime().nullable()();
  DateTimeColumn get syncDate => dateTime().nullable()();
  DateTimeColumn get provisionDate => dateTime().nullable()();
  TextColumn get step => text()(); // planned, toSchedule, scheduled, pending, completed, cancelled
  TextColumn get status => text()(); // toProvision, provisioned, toDistribute, toTransfer, transferred, toCorrect, corrected, none
  TextColumn get importHash => text().nullable()();
  TextColumn get recurringTransactionId => text().nullable()();
  TextColumn get linkedTransactionId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionSplitData')
class TransactionSplits extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text().references(Transactions, #id, onDelete: KeyAction.cascade)();
  TextColumn get virtualAccountId => text().references(VirtualAccounts, #id, onDelete: KeyAction.cascade)();
  RealColumn get amount => real()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SyncOutboxData')
class SyncOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get targetTable => text()();
  TextColumn get recordId => text()();
  TextColumn get action => text()(); // INSERT, UPDATE, DELETE
  TextColumn get payload => text()(); // JSON string
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [RealAccounts, VirtualAccounts, Transactions, TransactionSplits, SyncOutbox])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_openConnection());

  // Named constructor for testing with a custom executor
  LocalDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'finance_manager');
  }
}

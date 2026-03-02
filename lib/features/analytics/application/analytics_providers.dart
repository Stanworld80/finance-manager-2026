import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../accounts/data/account_providers.dart';
import '../../accounts/domain/account_models.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../../../core/providers.dart';

part 'analytics_providers.g.dart';

class FundSource {
  final String name;
  final double amount;
  final double percentage;

  FundSource({
    required this.name,
    required this.amount,
    required this.percentage,
  });
}

@riverpod
Future<List<FundSource>> envelopeFundSources(
  EnvelopeFundSourcesRef ref,
  String virtualAccountId,
) async {
  final auth = ref.watch(firebaseAuthProvider);
  final user = auth.currentUser;
  if (user == null) return [];

  final txRepo = ref.watch(transactionRepositoryProvider);
  final transactions = await txRepo.watchTransactions(user.uid).first;
  final realAccounts = await ref.watch(realAccountsProvider.future);
  final allVirtualAccounts = await ref.watch(allVirtualAccountsProvider.future);

  final virtualAccountNames = {for (var v in allVirtualAccounts) v.id: v.name};

  final Map<String, double> sources = {};
  double totalInflow = 0;

  for (final tx in transactions) {
    if (tx.step != TransactionStep.completed &&
        tx.step != TransactionStep.pending) {
      continue;
    }

    double inflow = 0;
    for (final split in tx.splits) {
      if (split.virtualAccountId == virtualAccountId && split.amount > 0) {
        inflow += split.amount;
      }
    }

    if (inflow <= 0) continue;

    totalInflow += inflow;
    String sourceName = "Autre / Inconnu";

    if (tx.externalEntityId != null) {
      final entity = realAccounts.firstWhere(
        (a) => a.id == tx.externalEntityId,
        orElse: () => RealAccount(
          id: tx.externalEntityId!,
          ownerId: user.uid,
          name: "Entité inconnue",
          balance: 0,
          type: RealAccountType.external,
        ),
      );
      sourceName = entity.name;
    } else if (tx.type == TransactionType.transfer) {
      // Find the source envelope (negative split)
      final sourceSplit = tx.splits.firstWhere(
        (s) => s.amount < 0,
        orElse: () => tx.splits.first,
      );
      final sourceNameResolved =
          virtualAccountNames[sourceSplit.virtualAccountId] ?? "Compte inconnu";
      sourceName = "Virement interne ($sourceNameResolved)";
    } else if (tx.splits.any(
      (s) => s.virtualAccountId == SystemAccounts.external,
    )) {
      sourceName = "Monde Extérieur (Indéfini)";
    }

    sources[sourceName] = (sources[sourceName] ?? 0) + inflow;
  }

  if (totalInflow == 0) return [];

  final List<FundSource> result = sources.entries.map((e) {
    return FundSource(
      name: e.key,
      amount: e.value,
      percentage: (e.value / totalInflow) * 100,
    );
  }).toList();

  result.sort((a, b) => b.amount.compareTo(a.amount));
  return result;
}

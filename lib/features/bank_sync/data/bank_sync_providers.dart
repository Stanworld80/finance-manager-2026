import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/bank_sync_models.dart';

// Simulating a Repository for now
class BankSyncRepository {
  Future<List<BankInstitution>> getAvailableInstitutions() async {
    // Mock Data
    return [
      const BankInstitution(
        id: 'ca',
        name: 'Crédit Agricole',
        logoUrl: 'assets/banks/ca.png',
        providerType: BankProviderType.mock,
      ),
      const BankInstitution(
        id: 'lbp',
        name: 'La Banque Postale',
        logoUrl: 'assets/banks/lbp.png',
        providerType: BankProviderType.mock,
      ),
      const BankInstitution(
        id: 'paypal',
        name: 'PayPal',
        logoUrl: 'assets/banks/paypal.png',
        providerType: BankProviderType.mock,
      ),
    ];
  }

  Future<void> connectInstitution(String userId, String institutionId) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    // Save connection to Firestore...
  }
}

final bankSyncRepositoryProvider = Provider((ref) => BankSyncRepository());

final availableBanksProvider = FutureProvider<List<BankInstitution>>((ref) {
  return ref.watch(bankSyncRepositoryProvider).getAvailableInstitutions();
});

enum BankConnectionStatus { connected, disconnected, error, syncing }

enum BankProviderType {
  manual,
  gocardless, // Example aggregator
  mock,
}

class BankInstitution {
  final String id;
  final String name;
  final String logoUrl;
  final BankProviderType providerType;

  const BankInstitution({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.providerType,
  });
}

class BankConnection {
  final String id;
  final String userId;
  final String institutionId;
  final BankConnectionStatus status;
  final DateTime lastSync;
  final String? externalReferenceId; // ID in the aggregator system

  const BankConnection({
    required this.id,
    required this.userId,
    required this.institutionId,
    required this.status,
    required this.lastSync,
    this.externalReferenceId,
  });
}

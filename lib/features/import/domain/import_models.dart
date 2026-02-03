enum TransactionField {
  skip,
  date,
  amount,
  description,
  payee,
  category, // Optional
}

class ImportMapping {
  final Map<int, TransactionField> columnMapping;
  final String dateFormat; // e.g., 'dd/MM/yyyy' or 'yyyy-MM-dd'

  const ImportMapping({
    required this.columnMapping,
    this.dateFormat = 'yyyy-MM-dd',
  });
}

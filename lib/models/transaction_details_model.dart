class TransactionDetails {
  final String id;
  final String wording;
  final double amount;
  final DateTime date;
  final String accountId;

  TransactionDetails({
    required this.id,
    required this.wording,
    required this.amount,
    required this.date,
    required this.accountId,
  });

  factory TransactionDetails.fromJson(Map<String, dynamic> json) {
    return TransactionDetails(
      id: json['id'].toString(), // Convertir l'ID numérique en String
      wording: json['wording'] ?? 'Transaction sans libellé',
      amount: (json['value'] as num).toDouble(),
      // La documentation POWENS recommande 'rdate' (real date) pour la date de transaction effective.
      date: DateTime.parse(json['rdate'] ?? json['date']),
      accountId: json['id_account'].toString(), // Convertir l'ID numérique en String
    );
  }
}

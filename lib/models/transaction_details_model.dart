class TransactionDetails {
  final String id;
  final double amount;
  final DateTime date;
  final String accountId;
  final String wording;
  final String? category; // Catégorie Powens, nullable
  final String? categoryLabel; // Libellé humain de la catégorie Powens (expansion)

  TransactionDetails({
    required this.id,
    required this.wording,
    required this.amount,
    required this.date,
    required this.accountId,
    this.category,
    this.categoryLabel,
  });

  factory TransactionDetails.fromJson(Map<String, dynamic> json) {
    // Récupération du label de catégorie via l’expansion ?expand=categories
    String? label;
    if (json.containsKey('categories') && json['categories'] != null) {
      // Peut être un objet ou une liste (selon API)
      if (json['categories'] is Map && json['categories']['label'] != null) {
        label = json['categories']['label'];
      } else if (json['categories'] is List && json['categories'].isNotEmpty && json['categories'][0]['label'] != null) {
        label = json['categories'][0]['label'];
      }
    }
    return TransactionDetails(
      id: json['id'].toString(), // Convertir l'ID numérique en String
      wording: json['wording'] ?? 'Transaction sans libellé',
      amount: (json['value'] as num).toDouble(),
      // La documentation POWENS recommande 'rdate' (real date) pour la date de transaction effective.
      date: DateTime.parse(json['rdate'] ?? json['date']),
      accountId: json['id_account'].toString(), // Convertir l'ID numérique en String
      category: json['category'], // Clé catégorie Powens, peut être null
      categoryLabel: label,
    );
  }
}

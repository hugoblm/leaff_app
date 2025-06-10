class AccountDetails {
  final String id;
  final String name;
  final double balance;
  final String connectionId;

  AccountDetails({
    required this.id,
    required this.name,
    required this.balance,
    required this.connectionId,
  });

  factory AccountDetails.fromJson(Map<String, dynamic> json) {
    return AccountDetails(
      id: json['id'].toString(), // Convertir l'ID numérique en String
      name: json['name'] ?? 'Compte sans nom',
      balance: (json['balance'] as num).toDouble(),
      connectionId: json['id_connection'].toString(), // Convertir l'ID numérique en String
    );
  }
}

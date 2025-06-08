import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String accountId,
    required String bankConnectionId,
    required String label,
    required double amount,
    required String currency,
    required DateTime date,
    required DateTime? valueDate,
    required String? description,
    required String? category,
    required String? type,
    required String? status,
    required String? originalAmount,
    required String? originalCurrency,
    required String? reference,
    required Map<String, dynamic>? metadata,
    required DateTime? createdAt,
    required DateTime? updatedAt,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  // Méthode utilitaire pour créer une transaction à partir d'une réponse de l'API POWENS
  factory Transaction.fromPowensApi(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      accountId: json['account_id'] as String,
      bankConnectionId: json['connection_id'] as String,
      label: json['name'] as String? ?? 'Transaction sans nom',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'EUR',
      date: DateTime.parse(json['date'] as String),
      valueDate: json['value_date'] != null 
          ? DateTime.parse(json['value_date'] as String) 
          : null,
      description: json['description'] as String?,
      category: json['category'] as String?,
      type: json['type'] as String?,
      status: json['status'] as String?,
      originalAmount: json['original_amount'] as String?,
      originalCurrency: json['original_currency'] as String?,
      reference: json['reference'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }
}
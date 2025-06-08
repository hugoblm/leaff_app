// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransactionImpl _$$TransactionImplFromJson(Map<String, dynamic> json) =>
    _$TransactionImpl(
      id: json['id'] as String,
      accountId: json['accountId'] as String,
      bankConnectionId: json['bankConnectionId'] as String,
      label: json['label'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      date: DateTime.parse(json['date'] as String),
      valueDate: json['valueDate'] == null
          ? null
          : DateTime.parse(json['valueDate'] as String),
      description: json['description'] as String?,
      category: json['category'] as String?,
      type: json['type'] as String?,
      status: json['status'] as String?,
      originalAmount: json['originalAmount'] as String?,
      originalCurrency: json['originalCurrency'] as String?,
      reference: json['reference'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$TransactionImplToJson(_$TransactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'accountId': instance.accountId,
      'bankConnectionId': instance.bankConnectionId,
      'label': instance.label,
      'amount': instance.amount,
      'currency': instance.currency,
      'date': instance.date.toIso8601String(),
      'valueDate': instance.valueDate?.toIso8601String(),
      'description': instance.description,
      'category': instance.category,
      'type': instance.type,
      'status': instance.status,
      'originalAmount': instance.originalAmount,
      'originalCurrency': instance.originalCurrency,
      'reference': instance.reference,
      'metadata': instance.metadata,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

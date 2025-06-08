// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bank_connection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BankConnectionImpl _$$BankConnectionImplFromJson(Map<String, dynamic> json) =>
    _$BankConnectionImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logoUrl'] as String,
      lastSync: DateTime.parse(json['lastSync'] as String),
      isActive: json['isActive'] as bool,
      accountIds: (json['accountIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$BankConnectionImplToJson(
        _$BankConnectionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'logoUrl': instance.logoUrl,
      'lastSync': instance.lastSync.toIso8601String(),
      'isActive': instance.isActive,
      'accountIds': instance.accountIds,
    };

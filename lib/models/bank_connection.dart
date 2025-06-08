import 'package:freezed_annotation/freezed_annotation.dart';

part 'bank_connection.freezed.dart';
part 'bank_connection.g.dart';

@freezed
class BankConnection with _$BankConnection {
  const factory BankConnection({
    required String id,
    required String name,
    required String logoUrl,
    required DateTime lastSync,
    required bool isActive,
    @Default([]) List<String> accountIds,
  }) = _BankConnection;

  factory BankConnection.fromJson(Map<String, dynamic> json) =>
      _$BankConnectionFromJson(json);
}

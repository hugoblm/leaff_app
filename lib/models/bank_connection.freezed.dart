// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bank_connection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BankConnection _$BankConnectionFromJson(Map<String, dynamic> json) {
  return _BankConnection.fromJson(json);
}

/// @nodoc
mixin _$BankConnection {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get logoUrl => throw _privateConstructorUsedError;
  DateTime get lastSync => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  List<String> get accountIds => throw _privateConstructorUsedError;

  /// Serializes this BankConnection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BankConnection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BankConnectionCopyWith<BankConnection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BankConnectionCopyWith<$Res> {
  factory $BankConnectionCopyWith(
          BankConnection value, $Res Function(BankConnection) then) =
      _$BankConnectionCopyWithImpl<$Res, BankConnection>;
  @useResult
  $Res call(
      {String id,
      String name,
      String logoUrl,
      DateTime lastSync,
      bool isActive,
      List<String> accountIds});
}

/// @nodoc
class _$BankConnectionCopyWithImpl<$Res, $Val extends BankConnection>
    implements $BankConnectionCopyWith<$Res> {
  _$BankConnectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BankConnection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? logoUrl = null,
    Object? lastSync = null,
    Object? isActive = null,
    Object? accountIds = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      logoUrl: null == logoUrl
          ? _value.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String,
      lastSync: null == lastSync
          ? _value.lastSync
          : lastSync // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      accountIds: null == accountIds
          ? _value.accountIds
          : accountIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BankConnectionImplCopyWith<$Res>
    implements $BankConnectionCopyWith<$Res> {
  factory _$$BankConnectionImplCopyWith(_$BankConnectionImpl value,
          $Res Function(_$BankConnectionImpl) then) =
      __$$BankConnectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String logoUrl,
      DateTime lastSync,
      bool isActive,
      List<String> accountIds});
}

/// @nodoc
class __$$BankConnectionImplCopyWithImpl<$Res>
    extends _$BankConnectionCopyWithImpl<$Res, _$BankConnectionImpl>
    implements _$$BankConnectionImplCopyWith<$Res> {
  __$$BankConnectionImplCopyWithImpl(
      _$BankConnectionImpl _value, $Res Function(_$BankConnectionImpl) _then)
      : super(_value, _then);

  /// Create a copy of BankConnection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? logoUrl = null,
    Object? lastSync = null,
    Object? isActive = null,
    Object? accountIds = null,
  }) {
    return _then(_$BankConnectionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      logoUrl: null == logoUrl
          ? _value.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String,
      lastSync: null == lastSync
          ? _value.lastSync
          : lastSync // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      accountIds: null == accountIds
          ? _value._accountIds
          : accountIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BankConnectionImpl implements _BankConnection {
  const _$BankConnectionImpl(
      {required this.id,
      required this.name,
      required this.logoUrl,
      required this.lastSync,
      required this.isActive,
      final List<String> accountIds = const []})
      : _accountIds = accountIds;

  factory _$BankConnectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$BankConnectionImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String logoUrl;
  @override
  final DateTime lastSync;
  @override
  final bool isActive;
  final List<String> _accountIds;
  @override
  @JsonKey()
  List<String> get accountIds {
    if (_accountIds is EqualUnmodifiableListView) return _accountIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_accountIds);
  }

  @override
  String toString() {
    return 'BankConnection(id: $id, name: $name, logoUrl: $logoUrl, lastSync: $lastSync, isActive: $isActive, accountIds: $accountIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BankConnectionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl) &&
            (identical(other.lastSync, lastSync) ||
                other.lastSync == lastSync) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            const DeepCollectionEquality()
                .equals(other._accountIds, _accountIds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, logoUrl, lastSync,
      isActive, const DeepCollectionEquality().hash(_accountIds));

  /// Create a copy of BankConnection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BankConnectionImplCopyWith<_$BankConnectionImpl> get copyWith =>
      __$$BankConnectionImplCopyWithImpl<_$BankConnectionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BankConnectionImplToJson(
      this,
    );
  }
}

abstract class _BankConnection implements BankConnection {
  const factory _BankConnection(
      {required final String id,
      required final String name,
      required final String logoUrl,
      required final DateTime lastSync,
      required final bool isActive,
      final List<String> accountIds}) = _$BankConnectionImpl;

  factory _BankConnection.fromJson(Map<String, dynamic> json) =
      _$BankConnectionImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get logoUrl;
  @override
  DateTime get lastSync;
  @override
  bool get isActive;
  @override
  List<String> get accountIds;

  /// Create a copy of BankConnection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BankConnectionImplCopyWith<_$BankConnectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

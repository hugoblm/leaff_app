class ConnectorDetails {
  final String uuid;
  final String name;
  final String? logoUrl;

  ConnectorDetails({
    required this.uuid,
    required this.name,
    this.logoUrl,
  });

  factory ConnectorDetails.fromJson(Map<String, dynamic> json) {
    return ConnectorDetails(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      logoUrl: json['logo'] as String?, // adapte si le champ logo existe
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'logo': logoUrl,
    };
  }
} 
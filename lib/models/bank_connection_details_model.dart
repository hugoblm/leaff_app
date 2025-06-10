class BankConnectionDetails {
  final String id;
  final String? connectorUuid; // UUID du connecteur
  final String? bankName;      // Nom de l'établissement, tiré de connector.name
  final String? connectorName; // Nom du connecteur, tiré de connector.name
  final String? status;        // État de la dernière synchro (de connection.state)
  final DateTime? lastUpdate;  // Date de dernière mise à jour réussie (de connection.last_update)
  final bool? isActiveFromApi; // État d'activité de la connexion (de connection.active)

  // Le logo n'est plus stocké ici, il sera construit dynamiquement

  BankConnectionDetails({
    required this.id,
    required this.connectorUuid,
    this.bankName,
    this.connectorName,
    this.status,
    this.lastUpdate,
    this.isActiveFromApi,
  });

  factory BankConnectionDetails.fromJson(Map<String, dynamic> json) {

    final connectorData = json['connector'] as Map<String, dynamic>?;
    
    // L'ID de connexion est un Integer dans l'API, nous le convertissons en String.
    final connectionId = json['id']?.toString();
    if (connectionId == null) {
      throw ArgumentError('Connection ID is missing or null in JSON');
    }

    return BankConnectionDetails(
      id: connectionId,
      // L'UUID du connecteur est directement dans l'objet connection
      connectorUuid: json['connector_uuid'] as String?,
      // Le nom de la banque et du connecteur vient de l'objet 'connector' qui doit être "expand"
      bankName: connectorData?['name'] as String?,
      connectorName: connectorData?['name'] as String?,
      status: json['state'] as String?, // 'state' dans l'API, peut être null si succès
      lastUpdate: json['last_update'] != null
          ? DateTime.tryParse(json['last_update'] as String)
          : null,
      isActiveFromApi: json['active'] as bool?,
    );
  }

  // Méthode pour un affichage simplifié ou pour le debug
  @override
  String toString() {
    return 'BankConnectionDetails(id: $id, bankName: $bankName, connectorName: $connectorName, status: $status, isActiveFromApi: $isActiveFromApi)';
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart'; // Pour générer le state
import 'package:url_launcher/url_launcher_string.dart';

import '../config/powens_config.dart';
import '../models/bank_connection_details_model.dart';
import '../models/account_details_model.dart';
import '../models/transaction_details_model.dart';
import '../models/connector_details_model.dart';

class TransactionPage {
  final List<TransactionDetails> transactions;
  final String? nextUrl;

  TransactionPage({required this.transactions, this.nextUrl});
}

class PowensService with ChangeNotifier {
  // ... (autres champs et méthodes déjà présents)


  // Clés pour le stockage sécurisé
  static const String _powensAccessTokenKey = 'powens_access_token';
  static const String _powensUserIdKey = 'powens_user_id';
  static const String _powensTokenTypeKey = 'powens_token_type';
  static const String _connectionIdsKey = 'powens_connection_ids'; // Stocke une liste d'IDs en JSON
  static const String _powensStateKey = 'powens_auth_state'; // Clé pour stocker le state CSRF
  static const String _connectionsDetailsKey = 'powens_connections_details'; // Ajouté pour stocker les détails
  static const String _connectorsDetailsKey = 'powens_connectors_details'; // Ajouté pour stocker les détails des connectors

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? _clientId;
  String? _clientSecret;

  String? _accessToken;
  String? _userId;
  String? _tokenType; // Généralement 'Bearer'

  List<String> _connectionIds = [];
  bool _isAuthenticated = false;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId; // Utile pour l'association avec l'utilisateur Leaff
  // String? get accessToken => _accessToken; // Exposer avec prudence
  List<String> get connectionIds => _connectionIds;

  // Constructeur privé
  PowensService._();

  // Méthode d'initialisation statique pour créer et initialiser le service
  static Future<PowensService> initialize() async {
    // PowensConfig.load() doit être appelé une fois au démarrage de l'app (ex: dans main.dart).
    // On suppose ici qu'il a déjà été appelé.
    // Si ce n'est pas garanti, décommentez la ligne suivante :
    // await PowensConfig.load(); 
    
    final service = PowensService._();
    service._clientId = PowensConfig.clientId;
    service._clientSecret = PowensConfig.clientSecret;
    await service._loadAuthData();
    // Ajout : déclenche le rafraîchissement des connecteurs si le cache est vide
    final String? connectorsJson = await service._secureStorage.read(key: _connectorsDetailsKey);
    if (connectorsJson == null) {
      debugPrint('[POWENS INIT] Cache connecteurs vide, déclenchement du refreshAllConnectorDetails()...');
      await service.refreshAllConnectorDetails();
    } else {
      debugPrint('[POWENS INIT] Cache connecteurs déjà présent, aucun refresh nécessaire.');
    }
    return service;
  }

  Future<void> _loadAuthData() async {
    try {
      _accessToken = await _secureStorage.read(key: _powensAccessTokenKey);
      _userId = await _secureStorage.read(key: _powensUserIdKey);
      _tokenType = await _secureStorage.read(key: _powensTokenTypeKey);

      if (_accessToken != null && _accessToken!.isNotEmpty &&
          _userId != null && _userId!.isNotEmpty &&
          _tokenType != null && _tokenType!.isNotEmpty) {
        _isAuthenticated = true;
        debugPrint('PowensService: Données d\'authentification chargées depuis le stockage sécurisé.');
      } else {
        _isAuthenticated = false;
        debugPrint('PowensService: Données d\'authentification non trouvées ou incomplètes dans le stockage sécurisé.');
      }

      final String? connectionIdsJson = await _secureStorage.read(key: _connectionIdsKey);
      if (connectionIdsJson != null && connectionIdsJson.isNotEmpty) {
        _connectionIds = List<String>.from(jsonDecode(connectionIdsJson));
      } else {
        _connectionIds = [];
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des données d\'authentification Powens: $e');
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  Future<void> _clearAuthData() async {
    await Future.wait([
      _secureStorage.delete(key: _powensAccessTokenKey),
      _secureStorage.delete(key: _powensUserIdKey),
      _secureStorage.delete(key: _powensTokenTypeKey),
      _secureStorage.delete(key: _connectionIdsKey),
    ]);
    _accessToken = null;
    _userId = null;
    _tokenType = null;
    _connectionIds = [];
    _isAuthenticated = false;
    notifyListeners();
    debugPrint('PowensService: Données d\'authentification et connexions effacées.');
  }

  // --- DATA FETCHING METHODS ---

  Future<List<AccountDetails>> getAccounts() async {
    if (!_isAuthenticated || _userId == null) {
      debugPrint('Erreur: Utilisateur non authentifié pour getAccounts.');
      return [];
    }

    final String url = PowensConfig.apiBaseUrlV2 + PowensConfig.getUserAccountsEndpoint(_userId!); 
    debugPrint('PowensService: Récupération des comptes depuis: $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': '$_tokenType $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> accountsJson = data['accounts'];
        return accountsJson.map((json) => AccountDetails.fromJson(json)).toList();
      } else {
        debugPrint('Erreur lors de la récupération des comptes: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Exception lors de la récupération des comptes: $e');
      return [];
    }
  }

  Future<TransactionPage> getTransactions({String? url}) async {
    if (!_isAuthenticated || _userId == null) {
      debugPrint('Erreur: Utilisateur non authentifié pour getTransactions.');
      return TransactionPage(transactions: [], nextUrl: null);
    }

    // Si aucune URL spécifique n'est fournie, construire l'URL initiale avec une limite.
    final String requestUrl = url ?? (PowensConfig.apiBaseUrlV2 + PowensConfig.getUserTransactionsEndpoint(_userId!) + '?limit=100&expand=categories');
    debugPrint('PowensService: Récupération des transactions depuis: $requestUrl');

    try {
      final response = await http.get(
        Uri.parse(requestUrl),
        headers: {
          'Authorization': '$_tokenType $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> transactionsJson = data['transactions'];
        final String? nextUrl = data['next']; // L'API fournit l'URL complète pour la page suivante

        for (final txJson in transactionsJson) {
          //debugPrint('[POWENS RAW TRANSACTION] ' + txJson.toString());
        }
        final transactions = transactionsJson.map((json) => TransactionDetails.fromJson(json)).toList();
        return TransactionPage(transactions: transactions, nextUrl: nextUrl);
      } else {
        debugPrint('Erreur lors de la récupération des transactions: ${response.statusCode} - ${response.body}');
        // Retourner le corps de l'erreur pourrait aider au débogage côté UI
        throw Exception('Failed to load transactions: ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception lors de la récupération des transactions: $e');
      throw Exception('Exception while loading transactions: $e');
    }
  }

  /// Initialise un utilisateur Powens (si nécessaire) et obtient un access_token.
  /// Retourne le `userId` Powens si l'initialisation est réussie, sinon `null`.
  /// Cette méthode doit être appelée avant toute autre interaction nécessitant une authentification Powens
  /// si l'utilisateur n'est pas déjà authentifié (par exemple, lors de la première connexion Powens).
  Future<String?> initializePowensUserAndGetId() async {
    debugPrint('PowensService: initializePowensUserAndGetId CALLED');
    if (_isAuthenticated && _userId != null) {
      debugPrint('PowensService: Exiting early from initializePowensUserAndGetId - already authenticated. UserId: $_userId');
      return _userId;
    }

    if (_clientId == null || _clientSecret == null) {
      debugPrint('ERREUR CRITIQUE: POWENS_CLIENT_ID ou POWENS_CLIENT_SECRET non chargés depuis PowensConfig.');
      debugPrint('Assurez-vous que PowensConfig.load() est appelé avant d\'utiliser PowensService.');
      // Tenter de les charger ici en fallback, bien que ce soit mieux dans main.dart
      await PowensConfig.load(); 
      _clientId = PowensConfig.clientId;
      _clientSecret = PowensConfig.clientSecret;
      if (_clientId == null || _clientSecret == null) {
        debugPrint('PowensService: Exiting early from initializePowensUserAndGetId - client_id or client_secret is null after fallback load.');
        return null;
      }
    }

    final String authInitUrl = PowensConfig.getAuthInitEndpointUrl();
    debugPrint('PowensService: Initialisation de l\'utilisateur Powens via: $authInitUrl');

    try {
      final response = await http.post(
        Uri.parse(authInitUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId!,
          'client_secret': _clientSecret!,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['auth_token']; // Corrigé pour correspondre à la réponse de Powens
        _userId = data['id_user']?.toString(); // Corrigé pour correspondre à la réponse de Powens
        _tokenType = 'Bearer'; // Défini à 'Bearer' car 'type: "permanent"' est une métadonnée

        debugPrint('PowensService: Raw response body for /auth/init: ${response.body}');
        debugPrint('PowensService: Parsed _accessToken: $_accessToken');
        debugPrint('PowensService: Parsed _userId: $_userId');
        debugPrint('PowensService: Parsed _tokenType: $_tokenType');

        if (_accessToken != null && _userId != null && _tokenType != null) {
          await _secureStorage.write(key: _powensAccessTokenKey, value: _accessToken!);
          await _secureStorage.write(key: _powensUserIdKey, value: _userId!);
          await _secureStorage.write(key: _powensTokenTypeKey, value: _tokenType!);
          _isAuthenticated = true;
          notifyListeners();
          debugPrint('PowensService: Utilisateur Powens initialisé avec succès. UserId: $_userId, TokenType: $_tokenType');
          return _userId;
        } else {
          debugPrint('Erreur: Données manquantes après parsing de /auth/init. _accessToken is null: ${_accessToken == null}, _userId is null: ${_userId == null}, _tokenType is null: ${_tokenType == null}. Body: ${response.body}');
          _clearAuthData(); // Nettoyer en cas de réponse partielle
          return null;
        }
      } else {
        debugPrint('Erreur lors de l\'initialisation de l\'utilisateur Powens: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Exception lors de l\'initialisation de l\'utilisateur Powens: $e');
      return null;
    }
  }

  Future<bool> login() async {
    if (!_isAuthenticated || _accessToken == null || _accessToken!.isEmpty) {
      debugPrint('Erreur: PowensService non authentifié pour le login. Assurez-vous que initializePowensUserAndGetId() a été appelé et a réussi, ou que les données sont chargées.');
      return false;
    }

    final String state = const Uuid().v4();
    await _secureStorage.write(key: _powensStateKey, value: state);

    try {
      final String tempCodeUrl = PowensConfig.getTemporaryCodeEndpointUrl();
      debugPrint('PowensService: Obtention du code temporaire depuis: $tempCodeUrl');

      final response = await http.get(
        Uri.parse(tempCodeUrl),
        headers: {
          'Authorization': '$_tokenType $_accessToken', // Utilise le tokenType et accessToken stockés
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? temporaryCode = data['code'];

        if (temporaryCode == null || temporaryCode.isEmpty) {
          debugPrint('Erreur: Code temporaire non reçu ou vide. Réponse: ${response.body}');
          await _secureStorage.delete(key: _powensStateKey);
          return false;
        }
        debugPrint('PowensService: Code temporaire obtenu: $temporaryCode');

        final String webviewUrl = PowensConfig.getWebviewConnectUrl(
          temporaryCode: temporaryCode,
          state: state,
        );
        debugPrint('PowensService: Lancement de la Webview Powens: $webviewUrl');

        if (await canLaunchUrlString(webviewUrl)) {
          final bool launched = await launchUrlString(
            webviewUrl,
            mode: LaunchMode.externalApplication,
          );
          if (!launched) {
            debugPrint('PowensService: Échec du lancement de l\'URL de la Webview.');
            await _secureStorage.delete(key: _powensStateKey);
            return false;
          }
          return true;
        } else {
          debugPrint('PowensService: Impossible de lancer l\'URL de la Webview: $webviewUrl');
          await _secureStorage.delete(key: _powensStateKey);
          return false;
        }
      } else {
        debugPrint('Erreur lors de l\'obtention du code temporaire: ${response.statusCode} - ${response.body}');
        await _secureStorage.delete(key: _powensStateKey);
        return false;
      }
    } catch (e) {
      debugPrint('Erreur lors du processus de login Powens: $e');
      await _secureStorage.delete(key: _powensStateKey);
      return false;
    }
  }

  Future<bool> handleWebviewCallback(Uri responseUrl) async {
    debugPrint('PowensService: Traitement du callback Webview: $responseUrl');
    final String? connectionIdParam = responseUrl.queryParameters['connection_id'];
    final String? receivedState = responseUrl.queryParameters['state'];
    final String? errorParam = responseUrl.queryParameters['error'];
    final String? errorDescriptionParam = responseUrl.queryParameters['error_description'];

    final String? storedState = await _secureStorage.read(key: _powensStateKey);
    await _secureStorage.delete(key: _powensStateKey);

    if (errorParam != null) {
      debugPrint('Erreur Powens Webview: $errorParam - $errorDescriptionParam');
      return false;
    }

    if (receivedState == null || storedState == null || receivedState != storedState) {
      debugPrint('Invalide state. CSRF possible? Reçu: $receivedState, Attendu: $storedState');
      return false;
    }

    if (connectionIdParam == null || connectionIdParam.isEmpty) {
      debugPrint('Erreur: connection_id manquant dans le callback.');
      return false;
    }

    if (!_connectionIds.contains(connectionIdParam)) {
      _connectionIds.add(connectionIdParam);
      final String connectionIdsJson = jsonEncode(_connectionIds);
      await _secureStorage.write(key: _connectionIdsKey, value: connectionIdsJson);
      debugPrint('PowensService: Connection ID $connectionIdParam ajouté et sauvegardé.');
      notifyListeners(); // Notifier les écouteurs que les données ont changé
    } else {
      debugPrint('PowensService: Connection ID $connectionIdParam déjà présent.');
    }

    // --- AJOUT : Rafraîchir la liste des connexions et des comptes après callback ---
    debugPrint('PowensService: Rafraîchissement des connexions et comptes après callback...');
    final connections = await listUserConnections();
    debugPrint('PowensService: Connexions après callback: $connections');
    final accounts = await getAccounts();
    debugPrint('PowensService: Comptes après callback:');
    for (final acc in accounts) {
      debugPrint('  id: \\${acc.id} (type: \\${acc.id.runtimeType}), connectionId: \\${acc.connectionId}');
    }
    // --- FIN AJOUT ---

    notifyListeners();
    return true;
  }

  /// Récupère la liste des IDs de connexion pour l'utilisateur Powens authentifié.
  Future<List<String>> listUserConnections() async {
    if (!_isAuthenticated || _accessToken == null || _accessToken!.isEmpty || _userId == null || _userId!.isEmpty) {
      debugPrint('PowensService: Authentification, accessToken ou userId manquant pour listUserConnections.');
      return [];
    }

    final String apiUrl = '${PowensConfig.apiBaseUrlV2}/users/$_userId/connections';
    debugPrint('PowensService: Listage des connexions depuis $apiUrl');

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': '$_tokenType $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decodedBody = jsonDecode(response.body);
        List<dynamic> connectionsList;

        if (decodedBody is List) {
          connectionsList = decodedBody;
        } else if (decodedBody is Map<String, dynamic> && 
                   decodedBody.containsKey('connections') && 
                   decodedBody['connections'] is List) {
          connectionsList = decodedBody['connections'];
        } else {
          debugPrint('Format de réponse inattendu pour listUserConnections: ${response.body}');
          return [];
        }

        final List<String> ids = connectionsList
            .map((conn) => conn['id']?.toString())
            .where((id) => id != null)
            .cast<String>()
            .toList();
        _connectionIds = ids; // Mettre à jour la liste locale
        final String connectionIdsJson = jsonEncode(_connectionIds);
        await _secureStorage.write(key: _connectionIdsKey, value: connectionIdsJson); // Sauvegarder la liste fraîche
        debugPrint('PowensService: Liste des connexions récupérée: $ids');
        return ids;
      } else {
        debugPrint('PowensService: Erreur lors du listage des connexions. Statut: ${response.statusCode}, Body: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('PowensService: Exception lors du listage des connexions: $e');
      return [];
    }
  }

  // --- Méthodes pour stocker et charger les détails de connexion ---
  Future<void> _storeConnectionDetails(BankConnectionDetails details) async {
    final String? jsonString = await _secureStorage.read(key: _connectionsDetailsKey);
    Map<String, dynamic> map = jsonString != null ? jsonDecode(jsonString) : {};
    map[details.id] = details.toJson();
    await _secureStorage.write(key: _connectionsDetailsKey, value: jsonEncode(map));
  }

  Future<Map<String, BankConnectionDetails>> loadAllConnectionDetails() async {
    final String? jsonString = await _secureStorage.read(key: _connectionsDetailsKey);
    if (jsonString == null) return {};
    final Map<String, dynamic> map = jsonDecode(jsonString);
    return map.map((k, v) => MapEntry(k, BankConnectionDetails.fromJson(v)));
  }

  Future<BankConnectionDetails?> getConnectionDetails(String connectionId) async {
    if (!_isAuthenticated || _accessToken == null || _accessToken!.isEmpty || _userId == null || _userId!.isEmpty) {
      debugPrint('PowensService: Authentification, accessToken ou userId manquant pour getConnectionDetails.');
      return null;
    }

    final String apiUrl = '${PowensConfig.apiBaseUrlV2}/users/$_userId/connections/$connectionId?expand=connector';
    debugPrint('PowensService: Récupération des détails pour connectionId: $connectionId, userId: $_userId depuis $apiUrl');

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': '$_tokenType $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        final Map<String, dynamic> connectionData = jsonData.containsKey('connection') 
            ? jsonData['connection'] as Map<String, dynamic> 
            : jsonData;
        final details = BankConnectionDetails.fromJson(connectionData);
        // Ajout : stocker les détails localement
        await _storeConnectionDetails(details);
        return details;
      } else {
        debugPrint('PowensService: Erreur lors de la récupération des détails de la connexion $connectionId. Statut: ${response.statusCode}, Body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('PowensService: Exception lors de la récupération des détails de la connexion $connectionId: $e');
      return null;
    }
  }

  /// Rafraîchit et stocke les détails de toutes les connexions de l'utilisateur
  Future<void> refreshAllConnectionDetails() async {
    final ids = await listUserConnections();
    for (final id in ids) {
      final details = await getConnectionDetails(id);
      if (details != null) {
        await _storeConnectionDetails(details);
      }
    }
  }

  Future<void> refreshAllConnectorDetails() async {
  debugPrint('[POWENS] Appel refreshAllConnectorDetails()');
    final ids = await listUserConnections();
    final Set<String> connectorUuids = {};
    for (final id in ids) {
      final details = await getConnectionDetails(id);
      if (details?.connectorUuid != null) {
        connectorUuids.add(details!.connectorUuid!);
      }
    }
    for (final uuid in connectorUuids) {
      debugPrint('[POWENS] Récupération des détails du connecteur $uuid');
      final connector = await getConnectorDetails(uuid);
      if (connector != null) {
        debugPrint('[POWENS] ConnectorDetails récupéré pour $uuid: ${connector.toJson()}');
        await _storeConnectorDetails(connector);
      } else {
        debugPrint('[POWENS] ConnectorDetails introuvable pour $uuid');
      }
    }
  }

  Future<ConnectorDetails?> getConnectorDetails(String connectorUuid) async {
  debugPrint('[POWENS] Appel getConnectorDetails($connectorUuid)');
    final String apiUrl = '${PowensConfig.apiBaseUrlV2}/connectors/$connectorUuid';
    final response = await http.get(Uri.parse(apiUrl));
  debugPrint('[POWENS] Réponse API getConnectorDetails: ${response.statusCode} - ${response.body}');
  if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return ConnectorDetails.fromJson(json);
    }
    return null;
  }

  Future<void> _storeConnectorDetails(ConnectorDetails details) async {
  debugPrint('[POWENS] Sauvegarde du connecteur ${details.uuid} → ${details.name}');
    final String? jsonString = await _secureStorage.read(key: _connectorsDetailsKey);
    Map<String, dynamic> map = jsonString != null ? jsonDecode(jsonString) : {};
    map[details.uuid] = details.toJson();
    await _secureStorage.write(key: _connectorsDetailsKey, value: jsonEncode(map));
  }

  Future<Map<String, ConnectorDetails>> loadAllConnectorDetails() async {
  debugPrint('[POWENS] Appel loadAllConnectorDetails()');
    final String? jsonString = await _secureStorage.read(key: _connectorsDetailsKey);
  debugPrint('[POWENS] Contenu brut _connectorsDetailsKey: '
      + (jsonString == null ? 'null' : jsonString));
  if (jsonString == null) return {};
  final Map<String, dynamic> map = jsonDecode(jsonString);
  debugPrint('[POWENS] Map décodée depuis le storage:');
  map.forEach((k, v) => debugPrint('  $k → $v'));
  final parsed = map.map((k, v) => MapEntry(k, ConnectorDetails.fromJson(v)));
  debugPrint('[POWENS] Map finale connectorUuid → ConnectorDetails:');
  parsed.forEach((k, v) => debugPrint('  $k → ${v.name}'));
  return parsed;
}

  /// Supprime une connexion bancaire Powens
  Future<bool> deleteConnection(String connectionId) async {
    if (!_isAuthenticated || _accessToken == null || _accessToken!.isEmpty || _userId == null || _userId!.isEmpty) {
      debugPrint('PowensService: Authentification, accessToken ou userId manquant pour deleteConnection.');
      return false;
    }
    final String apiUrl = '${PowensConfig.apiBaseUrlV2}/users/$_userId/connections/$connectionId';
    debugPrint('PowensService: Suppression de la connexion $connectionId via $apiUrl');
    try {
      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': '$_tokenType $_accessToken',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        debugPrint('PowensService: Connexion $connectionId supprimée avec succès.');
        // Met à jour le cache local
        await refreshAllConnectionDetails();
        await refreshAllConnectorDetails();
        return true;
      } else {
        debugPrint('PowensService: Erreur lors de la suppression de la connexion $connectionId. Statut: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('PowensService: Exception lors de la suppression de la connexion $connectionId: $e');
      return false;
    }
  }

}

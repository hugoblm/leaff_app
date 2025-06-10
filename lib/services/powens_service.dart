import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart'; // Pour générer le state
import 'package:url_launcher/url_launcher_string.dart';

import '../config/powens_config.dart';
import '../models/bank_connection_details_model.dart';

class PowensService with ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Clés pour le stockage sécurisé
  static const String _powensAccessTokenKey = 'powens_access_token';
  static const String _powensUserIdKey = 'powens_user_id';
  static const String _powensTokenTypeKey = 'powens_token_type';
  static const String _connectionIdsKey = 'powens_connection_ids'; // Stocke une liste d'IDs en JSON
  static const String _powensStateKey = 'powens_auth_state'; // Clé pour stocker le state CSRF

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
    } else {
      debugPrint('PowensService: Connection ID $connectionIdParam déjà présent.');
    }
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
        return BankConnectionDetails.fromJson(connectionData);
      } else {
        debugPrint('PowensService: Erreur lors de la récupération des détails de la connexion $connectionId. Statut: ${response.statusCode}, Body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('PowensService: Exception lors de la récupération des détails de la connexion $connectionId: $e');
      return null;
    }
  }

}

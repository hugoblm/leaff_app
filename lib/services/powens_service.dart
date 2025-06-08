import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';
import 'package:uuid/uuid.dart'; // Pour générer le state

import '../config/powens_config.dart';

class PowensService with ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Clés pour le stockage sécurisé
  static const String _permanentUserAuthTokenKey = 'powens_permanent_user_auth_token';
  static const String _connectionIdKey = 'powens_connection_id';
  static const String _powensStateKey = 'powens_auth_state'; // Clé pour stocker le state CSRF

  // --- MVP: Placeholder pour le token utilisateur permanent ---
  // REMPLACEZ CETTE VALEUR PAR VOTRE TOKEN UTILISATEUR PERMANENT OBTENU MANUELLEMENT
  // Ce token est normalement obtenu via un appel backend sécurisé à POST /2.0/auth/init
  static const String _placeholderPermanentUserAuthToken = 'apKrQSyuO4fOJi7Kj09G8hs1pcokDEuzE2P9IW45bwUwexl0sfOLxoHEsezDXkyuzFWaz41RCOzXGavXeBukmW_fVcIT3EAPoJCp7cz451_XDqchYu9ODSKkNjE69m2I';
  // --- Fin Placeholder ---

  String? _permanentUserAuthToken;
  String? _connectionId;
  bool _isAuthenticated = false;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get permanentUserAuthToken => _permanentUserAuthToken; // Pour debug ou usage futur
  String? get connectionId => _connectionId; // Pour debug ou usage futur

  // Constructeur et Initialisation
  // Le constructeur public appelle _loadAuthData pour simplifier l'initialisation depuis l'extérieur.
  PowensService() {
    _loadAuthData();
  }

  // Méthode d'initialisation statique si un chargement asynchrone est nécessaire avant la création
  static Future<PowensService> initialize() async {
    await PowensConfig.load(); // S'assure que PowensConfig est chargé
    final service = PowensService._internal();
    await service._loadAuthData(); // Charge les données d'authentification après la config
    return service;
  }

  // Constructeur privé utilisé par la méthode d'initialisation statique
  PowensService._internal();

  Future<void> _loadAuthData() async {
    try {
      _permanentUserAuthToken = await _secureStorage.read(key: _permanentUserAuthTokenKey);
      _connectionId = await _secureStorage.read(key: _connectionIdKey);

      if (_permanentUserAuthToken != null && _permanentUserAuthToken!.isNotEmpty) {
        _isAuthenticated = true;
      } else {
        // MVP: Utilisation du placeholder si aucun token n'est stocké
        _permanentUserAuthToken = _placeholderPermanentUserAuthToken;
        if (_placeholderPermanentUserAuthToken == 'METTRE_VOTRE_TOKEN_PERMANENT_UTILISATEUR_ICI') {
            debugPrint('--------------------------------------------------------------------------');
            debugPrint('ATTENTION: Le token utilisateur permanent POWENS n\'est pas configuré !');
            debugPrint('Veuillez remplacer la valeur de _placeholderPermanentUserAuthToken dans powens_service.dart');
            debugPrint('--------------------------------------------------------------------------');
            _isAuthenticated = false; // Non authentifié si le placeholder n'est pas changé
        } else {
            _isAuthenticated = true;
            // Optionnel: Sauvegarder le placeholder dans le storage pour les sessions suivantes
            // await _secureStorage.write(key: _permanentUserAuthTokenKey, value: _permanentUserAuthToken!);
            debugPrint('PowensService: Utilisation du token utilisateur permanent placeholder.');
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des données d\u0027authentification Powens: $e');
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  Future<void> _clearAuthData() async {
    await Future.wait([
      _secureStorage.delete(key: _permanentUserAuthTokenKey),
      _secureStorage.delete(key: _connectionIdKey),
      _secureStorage.delete(key: _powensStateKey), // Nettoyer aussi le state CSRF
    ]);
    _permanentUserAuthToken = null;
    _connectionId = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<bool> login() async {
    // Vérifie si le token est null, vide, ou s'il est toujours égal à la valeur initiale du placeholder.
    if (_permanentUserAuthToken == null || 
        _permanentUserAuthToken!.isEmpty || 
        _permanentUserAuthToken == 'METTRE_VOTRE_TOKEN_PERMANENT_UTILISATEUR_ICI') {
      debugPrint('Erreur: Token utilisateur permanent Powens non disponible ou non configuré.');
      debugPrint('Veuillez vérifier la configuration de _placeholderPermanentUserAuthToken ou le stockage sécurisé.');
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
          'Authorization': 'Bearer $_permanentUserAuthToken',
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
            mode: LaunchMode.externalApplication, // ou LaunchMode.inAppWebView si préféré et configuré
          );
          if (!launched) {
            debugPrint('PowensService: Échec du lancement de l\u0027URL de la Webview.');
            await _secureStorage.delete(key: _powensStateKey);
            return false;
          }
          return true;
        } else {
          debugPrint('PowensService: Impossible de lancer l\u0027URL de la Webview: $webviewUrl');
          await _secureStorage.delete(key: _powensStateKey);
          return false;
        }
      } else {
        debugPrint('Erreur lors de l\u0027obtention du code temporaire: ${response.statusCode} - ${response.body}');
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
    await _secureStorage.delete(key: _powensStateKey); // Supprimer le state après lecture

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

    _connectionId = connectionIdParam;
    await _secureStorage.write(key: _connectionIdKey, value: _connectionId!);
    debugPrint('PowensService: connection_id stocké avec succès: $_connectionId');
    // Potentiellement mettre à jour _isAuthenticated ici si la logique le demande, 
    // mais la présence du permanent token est le principal indicateur.
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await _clearAuthData();
    debugPrint('PowensService: Déconnexion effectuée.');
  }

  // --- Méthodes de l'ancien flux OAuth (commentées/à adapter/supprimer) ---
  /*
  Future<void> _saveTokens(
      String accessToken, String refreshToken, int expiresIn) async {
    // ... ancienne logique ...
  }

  Future<bool> _refreshAccessToken() async {
    // ... ancienne logique ...
    return false;
  }

  Future<bool> exchangeCodeForTokens(String code, String? receivedState) async {
    // ... ancienne logique ...
    return false;
  }

  Future<Map<String, dynamic>?> getUserInfo() async {
    // À réimplémenter avec le permanentUserAuthToken et les nouveaux endpoints v2
    // Nécessitera probablement le connection_id pour certaines opérations
    if (!_isAuthenticated || _permanentUserAuthToken == null) return null;
    debugPrint('PowensService: getUserInfo() non implémenté pour le nouveau flux.');
    return null;
  }

  Future<List<dynamic>?> getAccounts() async {
    // À réimplémenter avec le permanentUserAuthToken et les nouveaux endpoints v2
    // (ex: GET /users/{userId}/connections/{connectionId}/accounts ou /users/me/accounts)
    if (!_isAuthenticated || _permanentUserAuthToken == null) return null;
    debugPrint('PowensService: getAccounts() non implémenté pour le nouveau flux.');
    return null;
  }

  Future<List<dynamic>?> getTransactions({String? accountId}) async {
    // À réimplémenter avec le permanentUserAuthToken et les nouveaux endpoints v2
    // (ex: GET /users/{userId}/connections/{connectionId}/accounts/{accountId}/transactions)
    if (!_isAuthenticated || _permanentUserAuthToken == null) return null;
    debugPrint('PowensService: getTransactions() non implémenté pour le nouveau flux.');
    return null;
  }
  */
}

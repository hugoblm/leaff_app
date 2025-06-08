import 'package:flutter_dotenv/flutter_dotenv.dart';

class PowensConfig {
  static String? _clientId;
  // static String? _clientSecret; // Client Secret: Utilisé pour l'appel auth/init côté backend (non dans l'app client pour la prod).
                                // Pour le MVP sandbox, le permanentUserAuthToken sera obtenu manuellement.
  static String? _redirectUri;

  // Configuration pour le domaine API spécifique à l'application (ex: 'leaff-app-sandbox')
  static const String _apiDomainName = 'leaff-app-sandbox'; // Défini par l'utilisateur

  // URLs de base v2 et Webview
  static const String apiBaseUrlV2 = 'https://$_apiDomainName.biapi.pro/2.0';
  static const String webviewBaseUrl = 'https://webview.powens.com';
  static const String defaultLang = 'fr'; // Langue par défaut pour la Webview

  // Endpoints spécifiques v2
  static const String temporaryCodeEndpoint = '/auth/token/code'; // GET, pour obtenir le code temporaire depuis apiBaseUrlV2
  // Le flux de connexion est un chemin dans webviewBaseUrl, pas un endpoint API direct
  static const String webviewConnectFlowPath = '/connect'; 

  static Future<void> load() async {
    await dotenv.load(fileName: ".env");
    _clientId = dotenv.env['POWENS_CLIENT_ID'];
    // _clientSecret = dotenv.env['POWENS_CLIENT_SECRET']; // Ne pas charger si non utilisé directement.
    _redirectUri = dotenv.env['POWENS_REDIRECT_URI'] ?? 'leaffapp://oauth-callback';

    if (_clientId == null) { // _clientSecret n'est plus critique pour le flux client direct après auth/init
      throw Exception('POWENS_CLIENT_ID non défini dans .env');
    }
  }

  static String get clientId => _clientId!;
  // static String get clientSecret => _clientSecret!; // Ne pas exposer si non nécessaire directement
  static String get redirectUri => _redirectUri!;
  static String get apiDomainNameForWebview => '$_apiDomainName.biapi.pro';

  static String getTemporaryCodeEndpointUrl() {
    return '$apiBaseUrlV2$temporaryCodeEndpoint';
  }

  static String getWebviewConnectUrl({
    required String temporaryCode,
    required String state,
  }) {
    final queryParameters = {
      'domain': apiDomainNameForWebview, // Ex: leaff-app-sandbox.biapi.pro
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'code': temporaryCode, // Le code temporaire obtenu précédemment
      'state': state, // Pour la sécurité CSRF
      // Autres paramètres optionnels selon la doc Webview (connector_ids, capabilities, etc.) si besoin
      // 'connector_capabilities': 'bank', // Par défaut à 'bank' si non spécifié
    };

    // Format: https://webview.powens.com/{lang}/{flow}?domain={domain}.biapi.pro&{parameters}
    final uri = Uri.parse('$webviewBaseUrl/$defaultLang$webviewConnectFlowPath')
        .replace(queryParameters: queryParameters);
    return uri.toString();
  }
}

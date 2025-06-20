import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

import 'services/auth_service.dart';
import 'services/powens_service.dart';
import 'config/powens_config.dart';
import 'services/rss_service.dart' show RSSService;
import 'auth/auth_check.dart';
import 'theme/app_theme.dart'; // Import du thème personnalisé
import 'services/location_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final _appLinks = AppLinks(); // Instance de AppLinks
StreamSubscription<Uri>?
    _linkSubscription; // Pour gérer l'abonnement au flux de liens

void main() async {
  // Assurer l'initialisation des bindings Flutter.
  WidgetsFlutterBinding.ensureInitialized();

  // Rafraîchir la localisation à l'ouverture de l'app
  await LocationService.enableLocation();

  // Initialiser la localisation pour le formatage des dates (corrige le crash).
  await initializeDateFormatting('fr_FR', null);
  await Firebase.initializeApp(); // Initialisation directe de Firebase

  // Charger les variables d'environnement
  await dotenv.load(fileName: ".env");

  // Charger la configuration Powens (qui utilise dotenv)
  await PowensConfig.load();

  // Initialiser le service POWENS
  final powensService = await PowensService.initialize();

  // Initialiser la gestion des deep links
  await _initAppLinks(powensService, context: navigatorKey.currentContext);

  // Charger la police Instrument Sans
  GoogleFonts.config.allowRuntimeFetching = true;

  runApp(
    ChangeNotifierProvider(
      create: (context) => powensService,
      child: const LeaffApp(),
    ),
  );
}

// Fonction pour initialiser la gestion des deep links
Future<void> _initAppLinks(PowensService powensService,
    {BuildContext? context}) async {
  try {
    // Vérifier le lien initial qui a pu lancer l'application
    final initialUri = await _appLinks.getInitialAppLink();
    if (initialUri != null) {
      print('Lien initial reçu: $initialUri');
      _handleIncomingLink(initialUri, powensService, context: context);
    }

    // Écouter les liens entrants pendant que l'application est active
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      print('Lien entrant reçu: $uri');
      _handleIncomingLink(uri, powensService, context: context);
    }, onError: (err) {
      print('Erreur sur le flux de liens: $err');
      // Gérer les erreurs de manière appropriée
    });
  } catch (e) {
    print('Erreur lors de l' 'initialisation des app_links: $e');
  }
}

// Fonction pour traiter un lien entrant
void _handleIncomingLink(Uri? uri, PowensService powensService,
    {BuildContext? context}) {
  if (uri == null) return;

  print('Traitement du lien: $uri');

  // Vérifier si le lien correspond au callback de POWENS
  if (uri.scheme == 'leaffapp' && uri.host == 'oauth-callback') {
    print('Callback POWENS détecté: $uri');

    // Appeler la nouvelle méthode de PowensService qui gère le callback complet
    // Elle extrait connection_id, state, et gère les erreurs.
    powensService.handleWebviewCallback(uri).then((success) {
      if (success) {
        print(
            'Traitement du callback POWENS réussi ! Connection ID potentiellement stocké.');
        // TODO: Mettre à jour l'UI ou naviguer si nécessaire.
        // Par exemple, afficher un message de succès. Utiliser navigatorKey.currentContext
        // avec prudence car il peut être null si l'UI n'est pas encore construite.
        // if (navigatorKey.currentContext != null) {
        //   ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        //     const SnackBar(content: Text('Connexion bancaire réussie!')),
        //   );
        //   // Navigator.of(navigatorKey.currentContext!).pushReplacementNamed('/home'); // ou une page de confirmation
        // }
      } else {
        print('Échec du traitement du callback POWENS.');
        // TODO: Gérer l'échec (ex: afficher un message à l'utilisateur).
        // if (navigatorKey.currentContext != null) {
        //   ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        //     const SnackBar(content: Text('Erreur lors de la connexion bancaire.')),
        //   );
        // }
      }
    }).catchError((error) {
      print('Erreur lors de l' 'appel à handleWebviewCallback: $error');
      // TODO: Gérer l'erreur (ex: afficher un message à l'utilisateur).
      // if (navigatorKey.currentContext != null) {
      //   ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      //     const SnackBar(content: Text('Une erreur technique est survenue.')),
      //   );
      // }
    });
  } else {
    print('Lien non pertinent pour POWENS: $uri');
  }
}

class LeaffApp extends StatelessWidget {
  const LeaffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => RSSService()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Leaff',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme.copyWith(
          textTheme: GoogleFonts.instrumentSansTextTheme(
            Theme.of(context).textTheme,
          ),
        ),
        // Désactivation du thème sombre pour forcer le thème clair
        darkTheme: AppTheme.lightTheme, // Utiliser le même thème clair
        themeMode: ThemeMode.light, // Forcer le thème clair
        home: const AuthCheck(),
      ),
    );
  }
}

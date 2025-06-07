import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/rss_service.dart';
import 'auth/auth_check.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initializeFirebase();
  runApp(const LeaffApp());
}

class LeaffApp extends StatelessWidget {
  const LeaffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        Provider(create: (context) => RSSService()),
      ],
      child: MaterialApp(
        title: 'Leaff - Low Carbon Living',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF212529),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Instrument Sans',
        ),
        home: const AuthCheck(),
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

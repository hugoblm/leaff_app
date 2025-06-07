import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDf28VImvQtCcmWQMy6691E49DQ1dUTN_o", // API Key
          appId: "1:763792070353:ios:3606c988ef90e03f1e17f0", // App ID
          messagingSenderId: "763792070353", // Sender ID
          projectId: "leaf-8a985", // Project ID
        ),
      );
    } catch (e) {
      print('Error initializing Firebase: $e');
    }
  }

  static Future<UserCredential> signInWithGoogle() async {
    try {
      // Déclencher l'authentification Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      
      if (googleUser == null) throw Exception('Authentication cancelled');

      // Obtenir l'authentification Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Créer les credentials pour Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Signer avec Firebase
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}

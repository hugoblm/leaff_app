import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'navigation_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  Future<void> signIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      
      if (user != null) {
        _currentUser = UserModel.fromFirebaseUser(user);
        notifyListeners();
        // Redirection vers la page d'accueil
        NavigationService.popUntilFirst();
        NavigationService.replaceWith('/home');
      }
    } catch (e) {
      print('Error signing in: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      _currentUser = null;
      notifyListeners();
      // Redirection vers la page de connexion
      NavigationService.popUntilFirst();
      NavigationService.replaceWith('/welcome');
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Méthode pour obtenir les informations de l'utilisateur
  UserModel? getUserInfo() {
    return _currentUser;
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'navigation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

  Future<void> savePowensUserId(String powensUserId) async {
    final User? firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      print('AuthService: Aucun utilisateur connecté pour sauvegarder le Powens User ID.');
      return;
    }

    try {
      await _firestore.collection('users').doc(firebaseUser.uid).set(
        {
          'powensUserId': powensUserId,
          // Ajoutez d'autres champs que vous pourriez vouloir sauvegarder/mettre à jour en même temps
          // 'lastModified': FieldValue.serverTimestamp(), // Exemple
        },
        SetOptions(merge: true), // merge:true pour ne pas écraser les autres champs du document
      );
      print('AuthService: Powens User ID sauvegardé dans Firestore pour l''utilisateur ${firebaseUser.uid}');
      // Optionnel: Mettre à jour le modèle local _currentUser si UserModel a un champ powensUserId
      // if (_currentUser != null) {
      //   _currentUser = _currentUser!.copyWith(powensUserId: powensUserId); // Supposant une méthode copyWith
      //   notifyListeners();
      // }
    } catch (e) {
      print('AuthService: Erreur lors de la sauvegarde du Powens User ID dans Firestore: $e');
      // Gérer l'erreur de manière appropriée (ex: throw)
    }
  }
}

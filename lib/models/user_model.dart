import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String? uid;
  final String? email;
  final String? displayName;
  final String? photoURL;

  UserModel({
    this.uid,
    this.email,
    this.displayName,
    this.photoURL,
  });

  UserModel.fromFirebaseUser(User user)
      : uid = user.uid,
        email = user.email,
        displayName = user.displayName,
        photoURL = user.photoURL;

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      email: json['email'],
      displayName: json['displayName'],
      photoURL: json['photoURL'],
    );
  }
}

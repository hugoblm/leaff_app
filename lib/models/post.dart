import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Post {
  final String id;
  final String userId;
  final String userName;
  final String? userProfileImageUrl;
  final String title;
  final String content;
  final DateTime createdAt;
  final int commentCount;
  final Map<String, bool> likes;
  final Map<String, bool> reports;

  /// Calculé dynamiquement à partir de la map likes
  int get likeCount => likes.values.where((v) => v).length;

  /// Retourne true si l'utilisateur donné a liké ce post
  bool likedBy(String userId) => likes[userId] == true;

  /// Retourne true si l'utilisateur donné a signalé ce post
  bool reportedBy(String userId) => reports[userId] == true;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfileImageUrl,
    required this.title,
    required this.content,
    required this.createdAt,
    this.commentCount = 0,
    Map<String, bool>? likes,
    Map<String, bool>? reports,
  })  : likes = likes ?? {},
        reports = reports ?? {};

  /// Mapping Firestore/JSON -> Post
  factory Post.fromJson(Map<String, dynamic> json) {
    // Supporte Timestamp Firestore ou String ISO pour createdAt
    DateTime parseCreatedAt(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return Post(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userProfileImageUrl: json['userProfileImageUrl'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: parseCreatedAt(json['createdAt']),
      commentCount: json['commentCount'] ?? 0,
      likes: (json['likes'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v == true)) ??
          {},
      reports: (json['reports'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v == true)) ??
          {},
    );
  }

  /// Mapping Post -> Firestore/JSON
  Map<String, dynamic> toJson() {
    final createdAtValue =
        createdAt is DateTime ? Timestamp.fromDate(createdAt) : createdAt;
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userProfileImageUrl': userProfileImageUrl,
      'title': title,
      'content': content,
      'createdAt': createdAtValue,
      'commentCount': commentCount,
      'likes': likes,
      'reports': reports,
    };
  }

  /// Crée une copie du post avec des modifications
  Post copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfileImageUrl,
    String? title,
    String? content,
    DateTime? createdAt,
    int? commentCount,
    Map<String, bool>? likes,
    Map<String, bool>? reports,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      commentCount: commentCount ?? this.commentCount,
      likes: likes ?? this.likes,
      reports: reports ?? this.reports,
    );
  }
}

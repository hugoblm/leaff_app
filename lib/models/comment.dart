import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String? userProfileImageUrl;
  final String content;
  final DateTime createdAt;
  final Map<String, bool> likes;
  final Map<String, bool> reports;

  /// Calculé dynamiquement à partir de la map likes
  int get likeCount => likes.values.where((v) => v).length;

  /// Retourne true si l'utilisateur donné a liké ce commentaire
  bool likedBy(String userId) => likes[userId] == true;

  /// Retourne true si l'utilisateur donné a signalé ce commentaire
  bool reportedBy(String userId) => reports[userId] == true;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userProfileImageUrl,
    required this.content,
    required this.createdAt,
    Map<String, bool>? likes,
    Map<String, bool>? reports,
  })  : likes = likes ?? {},
        reports = reports ?? {};

  /// Mapping Firestore/JSON -> Comment
  factory Comment.fromJson(Map<String, dynamic> json) {
    DateTime parseCreatedAt(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return Comment(
      id: json['id'] ?? '',
      postId: json['postId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userProfileImageUrl: json['userProfileImageUrl'],
      content: json['content'] ?? '',
      createdAt: parseCreatedAt(json['createdAt']),
      likes: (json['likes'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v == true)) ??
          {},
      reports: (json['reports'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v == true)) ??
          {},
    );
  }

  /// Mapping Comment -> Firestore/JSON
  Map<String, dynamic> toJson() {
    final createdAtValue =
        createdAt is DateTime ? Timestamp.fromDate(createdAt) : createdAt;
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userProfileImageUrl': userProfileImageUrl,
      'content': content,
      'createdAt': createdAtValue,
      'likes': likes,
      'reports': reports,
    };
  }

  /// Crée une copie du commentaire avec des modifications
  Comment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? userName,
    String? userProfileImageUrl,
    String? content,
    DateTime? createdAt,
    Map<String, bool>? likes,
    Map<String, bool>? reports,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      reports: reports ?? this.reports,
    );
  }
}

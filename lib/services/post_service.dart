import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';
import '../models/comment.dart';
import 'package:flutter/foundation.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'posts';

  /// Fetch posts with pagination (ordered by createdAt desc)
  Future<List<Post>> fetchPosts(
      {int limit = 10, DocumentSnapshot? startAfter}) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(limit);
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Post.fromJson(data);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new post
  Future<void> createPost(Post post) async {
    try {
      final data = post.toJson();
      data.remove('id'); // Firestore gère l'id
      await _firestore.collection(_collection).add(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Like or unlike a post (toggle)
  Future<void> toggleLike(
      {required String postId,
      required String userId,
      required bool like}) async {
    final postRef = _firestore.collection(_collection).doc(postId);
    final likeField = 'likes.$userId';
    debugPrint(
        '[toggleLike] postId: $postId, userId: $userId, like: $like, likeField: $likeField');
    try {
      debugPrint('[toggleLike] update data: { $likeField: $like }');
      await postRef.update({likeField: like});
    } catch (e) {
      debugPrint('[toggleLike] ERROR: $e');
      rethrow;
    }
  }

  /// Fetch comments for a specific post
  Future<List<Comment>> fetchComments(String postId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .doc(postId)
          .collection('comments')
          .orderBy('createdAt', descending: false)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['postId'] = postId;
        return Comment.fromJson(data);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Add a comment to a post (batch: add + increment commentCount)
  Future<void> addComment(Comment comment) async {
    try {
      final batch = _firestore.batch();
      final commentsRef = _firestore
          .collection(_collection)
          .doc(comment.postId)
          .collection('comments');
      final data = comment.toJson();
      data.remove('id'); // Firestore will handle the ID
      data.remove('postId'); // Not needed in the subcollection
      final commentRef = commentsRef.doc();
      batch.set(commentRef, data);
      final postRef = _firestore.collection(_collection).doc(comment.postId);
      batch.update(postRef, {'commentCount': FieldValue.increment(1)});
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a comment (batch: delete + decrement commentCount)
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      final batch = _firestore.batch();
      final commentRef = _firestore
          .collection(_collection)
          .doc(postId)
          .collection('comments')
          .doc(commentId);
      batch.delete(commentRef);
      final postRef = _firestore.collection(_collection).doc(postId);
      batch.update(postRef, {'commentCount': FieldValue.increment(-1)});
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// Like or unlike a comment (toggle)
  Future<void> toggleCommentLike({
    required String postId,
    required String commentId,
    required String userId,
    required bool like,
  }) async {
    final commentRef = _firestore
        .collection(_collection)
        .doc(postId)
        .collection('comments')
        .doc(commentId);
    final likeField = 'likes.$userId';
    try {
      await commentRef.update({likeField: like});
    } catch (e) {
      rethrow;
    }
  }

  /// Listen to real-time updates (optionnel)
  Stream<List<Post>> listenToPosts({int limit = 10}) {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return Post.fromJson(data);
            }).toList());
  }

  /// Signaler ou désignaler un post
  Future<void> reportPost({
    required String postId,
    required String userId,
    required bool report,
  }) async {
    final postRef = _firestore.collection(_collection).doc(postId);
    final reportField = 'reports.$userId';
    try {
      await postRef.update({reportField: report});
    } catch (e) {
      rethrow;
    }
  }

  /// Signaler ou désignaler un commentaire
  Future<void> reportComment({
    required String postId,
    required String commentId,
    required String userId,
    required bool report,
  }) async {
    final commentRef = _firestore
        .collection(_collection)
        .doc(postId)
        .collection('comments')
        .doc(commentId);
    final reportField = 'reports.$userId';
    try {
      await commentRef.update({reportField: report});
    } catch (e) {
      rethrow;
    }
  }
}

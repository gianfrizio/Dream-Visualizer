import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/saved_dream.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Flag per controllare se Firebase è disponibile
  static bool _isFirebaseAvailable = true;

  // Collections
  static const String _dreamsCollection = 'community_dreams';
  static const String _commentsCollection = 'comments';
  static const String _likesCollection = 'likes';
  static const String _usersCollection = 'users';

  // Fallback locale storage per quando Firebase non è disponibile
  static final Map<String, Map<String, dynamic>> _localDreams = {};
  static final Map<String, List<Map<String, dynamic>>> _localComments = {};
  static final Map<String, Map<String, dynamic>> _localLikes = {};

  // === USER MANAGEMENT ===

  // Get current user ID (creates anonymous user if needed)
  static Future<String> getCurrentUserId() async {
    try {
      User? user = _auth.currentUser;

      if (user == null) {
        // Create anonymous user
        UserCredential credential = await _auth.signInAnonymously();
        user = credential.user!;

        // Create user document
        await _firestore.collection(_usersCollection).doc(user.uid).set({
          'created_at': FieldValue.serverTimestamp(),
          'is_anonymous': true,
          'display_name': 'Anonymous User',
        });
      }

      return user.uid;
    } catch (e) {
  debugPrint('Firebase not available, using local user ID: $e');
      _isFirebaseAvailable = false;
      // Fallback: usa un ID locale fisso
      return 'local_user_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // === DREAMS MANAGEMENT ===

  // Share dream to community
  static Future<void> shareDreamToCommunity(SavedDream dream) async {
    try {
      final userId = await getCurrentUserId();

      final dreamData = {
        'id': dream.id,
        'title': dream.title,
        'dream_text': dream.dreamText,
        'interpretation': dream.interpretation,
        'tags': dream.tags,
        'language': dream.language,
        'author_id': userId,
        'author_name': 'Anonymous Dreamer',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'likes_count': 0,
        'comments_count': 0,
        'is_public': true,
      };

      await _firestore
          .collection(_dreamsCollection)
          .doc(dream.id)
          .set(dreamData);
  debugPrint('Dream ${dream.id} shared to community');
    } catch (e) {
  debugPrint('Error sharing dream: $e');
      throw e;
    }
  }

  // Remove dream from community
  static Future<void> removeDreamFromCommunity(String dreamId) async {
    try {
      await _firestore.collection(_dreamsCollection).doc(dreamId).delete();

      // Also delete associated comments and likes
      await _deleteAssociatedData(dreamId);

  debugPrint('Dream $dreamId removed from community');
    } catch (e) {
  debugPrint('Error removing dream: $e');
      throw e;
    }
  }

  // Get community dreams
  static Future<List<SavedDream>> getCommunityDreams({
    String? language,
    String? category,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection(_dreamsCollection)
          .where('is_public', isEqualTo: true)
          .orderBy('created_at', descending: true);

      if (language != null && language != 'all') {
        query = query.where('language', isEqualTo: language);
      }

      if (limit > 0) {
        query = query.limit(limit);
      }

      final QuerySnapshot snapshot = await query.get();

      final dreams = <SavedDream>[];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final dream = SavedDream(
          id: data['id'] ?? doc.id,
          title: data['title'] ?? '',
          dreamText: data['dream_text'] ?? '',
          interpretation: data['interpretation'] ?? '',
          createdAt:
              (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          tags: List<String>.from(data['tags'] ?? []),
          language: data['language'] ?? 'italian',
          isSharedWithCommunity: true,
        );

        dreams.add(dream);
      }

      return dreams;
    } catch (e) {
  debugPrint('Error loading community dreams: $e');
      return [];
    }
  }

  // === LIKES MANAGEMENT ===

  // Toggle dream like
  static Future<Map<String, dynamic>> toggleDreamLike(String dreamId) async {
    try {
      final userId = await getCurrentUserId();
      final likeDocId = '${dreamId}_$userId';

      final likeDoc = _firestore.collection(_likesCollection).doc(likeDocId);
      final likeSnapshot = await likeDoc.get();

      bool isLiked = likeSnapshot.exists;

      if (isLiked) {
        // Remove like
        await likeDoc.delete();

        // Decrement like count
        await _firestore.collection(_dreamsCollection).doc(dreamId).update({
          'likes_count': FieldValue.increment(-1),
        });
      } else {
        // Add like
        await likeDoc.set({
          'dream_id': dreamId,
          'user_id': userId,
          'created_at': FieldValue.serverTimestamp(),
        });

        // Increment like count
        await _firestore.collection(_dreamsCollection).doc(dreamId).update({
          'likes_count': FieldValue.increment(1),
        });
      }

      // Get updated like count
      final dreamDoc = await _firestore
          .collection(_dreamsCollection)
          .doc(dreamId)
          .get();
      final likeCount = dreamDoc.data()?['likes_count'] ?? 0;

      return {'isLiked': !isLiked, 'likeCount': likeCount};
    } catch (e) {
  debugPrint('Error toggling dream like: $e');
      throw e;
    }
  }

  // Get dream likes count
  static Future<int> getDreamLikes(String dreamId) async {
    try {
      final dreamDoc = await _firestore
          .collection(_dreamsCollection)
          .doc(dreamId)
          .get();
      return dreamDoc.data()?['likes_count'] ?? 0;
    } catch (e) {
  debugPrint('Error getting dream likes: $e');
      return 0;
    }
  }

  // Check if user liked dream
  static Future<bool> hasUserLikedDream(String dreamId) async {
    try {
      final userId = await getCurrentUserId();
      final likeDocId = '${dreamId}_$userId';

      final likeDoc = await _firestore
          .collection(_likesCollection)
          .doc(likeDocId)
          .get();
      return likeDoc.exists;
    } catch (e) {
  debugPrint('Error checking user like: $e');
      return false;
    }
  }

  // === COMMENTS MANAGEMENT ===

  // Add comment to dream
  static Future<void> addComment(String dreamId, String content) async {
    try {
      final userId = await getCurrentUserId();

      final commentData = {
        'dream_id': dreamId,
        'author_id': userId,
        'author_name': 'Tu', // Can be customized later
        'content': content,
        'created_at': FieldValue.serverTimestamp(),
        'likes_count': 0,
        'edited': false,
      };

      await _firestore.collection(_commentsCollection).add(commentData);

      // Increment comments count
      await _firestore.collection(_dreamsCollection).doc(dreamId).update({
        'comments_count': FieldValue.increment(1),
      });

      debugPrint('Comment added to dream $dreamId');
    } catch (e) {
      debugPrint('Error adding comment: $e');
      throw e;
    }
  }

  // Get comments for dream
  static Future<List<Map<String, dynamic>>> getDreamComments(
    String dreamId,
  ) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_commentsCollection)
          .where('dream_id', isEqualTo: dreamId)
          .orderBy('created_at', descending: true)
          .get();

      final comments = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        // Convert timestamp to string for compatibility
        if (data['created_at'] != null) {
          final timestamp = data['created_at'] as Timestamp;
          data['timestamp'] = timestamp.toDate().toIso8601String();
        }

        comments.add(data);
      }

      return comments;
    } catch (e) {
      debugPrint('Error loading comments: $e');
      return [];
    }
  }

  // Edit comment
  static Future<bool> editComment(String commentId, String newContent) async {
    try {
      await _firestore.collection(_commentsCollection).doc(commentId).update({
        'content': newContent,
        'edited': true,
        'edited_at': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error editing comment: $e');
      return false;
    }
  }

  // Delete comment
  static Future<bool> deleteComment(String dreamId, String commentId) async {
    try {
      await _firestore.collection(_commentsCollection).doc(commentId).delete();

      // Decrement comments count
      await _firestore.collection(_dreamsCollection).doc(dreamId).update({
        'comments_count': FieldValue.increment(-1),
      });

      return true;
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      return false;
    }
  }

  // === COMMENT LIKES ===

  // Toggle comment like
  static Future<Map<String, dynamic>> toggleCommentLike(
    String commentId,
  ) async {
    try {
      final userId = await getCurrentUserId();
      final likeDocId = 'comment_${commentId}_$userId';

      final likeDoc = _firestore.collection(_likesCollection).doc(likeDocId);
      final likeSnapshot = await likeDoc.get();

      bool isLiked = likeSnapshot.exists;

      if (isLiked) {
        // Remove like
        await likeDoc.delete();

        // Decrement like count
        await _firestore.collection(_commentsCollection).doc(commentId).update({
          'likes_count': FieldValue.increment(-1),
        });
      } else {
        // Add like
        await likeDoc.set({
          'comment_id': commentId,
          'user_id': userId,
          'created_at': FieldValue.serverTimestamp(),
        });

        // Increment like count
        await _firestore.collection(_commentsCollection).doc(commentId).update({
          'likes_count': FieldValue.increment(1),
        });
      }

      // Get updated like count
      final commentDoc = await _firestore
          .collection(_commentsCollection)
          .doc(commentId)
          .get();
      final likeCount = commentDoc.data()?['likes_count'] ?? 0;

      return {'isLiked': !isLiked, 'likeCount': likeCount};
    } catch (e) {
      debugPrint('Error toggling comment like: $e');
      throw e;
    }
  }

  // Get comment likes
  static Future<int> getCommentLikes(String commentId) async {
    try {
      final commentDoc = await _firestore
          .collection(_commentsCollection)
          .doc(commentId)
          .get();
      return commentDoc.data()?['likes_count'] ?? 0;
    } catch (e) {
      debugPrint('Error getting comment likes: $e');
      return 0;
    }
  }

  // Check if user liked comment
  static Future<bool> hasUserLikedComment(String commentId) async {
    try {
      final userId = await getCurrentUserId();
      final likeDocId = 'comment_${commentId}_$userId';

      final likeDoc = await _firestore
          .collection(_likesCollection)
          .doc(likeDocId)
          .get();
      return likeDoc.exists;
    } catch (e) {
      debugPrint('Error checking comment like: $e');
      return false;
    }
  }

  // === UTILITY METHODS ===

  // Delete all associated data for a dream
  static Future<void> _deleteAssociatedData(String dreamId) async {
    try {
      // Delete comments
      final commentsSnapshot = await _firestore
          .collection(_commentsCollection)
          .where('dream_id', isEqualTo: dreamId)
          .get();

      for (final doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete likes
      final likesSnapshot = await _firestore
          .collection(_likesCollection)
          .where('dream_id', isEqualTo: dreamId)
          .get();

      for (final doc in likesSnapshot.docs) {
        await doc.reference.delete();
      }

      debugPrint('Associated data deleted for dream $dreamId');
    } catch (e) {
      debugPrint('Error deleting associated data: $e');
    }
  }

  // === REAL-TIME LISTENERS ===

  // Listen to dream likes changes
  static Stream<int> listenToDreamLikes(String dreamId) {
    return _firestore
        .collection(_dreamsCollection)
        .doc(dreamId)
        .snapshots()
        .map((doc) => doc.data()?['likes_count'] ?? 0);
  }

  // Listen to comments changes
  static Stream<List<Map<String, dynamic>>> listenToDreamComments(
    String dreamId,
  ) {
    return _firestore
        .collection(_commentsCollection)
        .where('dream_id', isEqualTo: dreamId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          final comments = <Map<String, dynamic>>[];
          for (final doc in snapshot.docs) {
            final data = doc.data();
            data['id'] = doc.id;

            // Convert timestamp
            if (data['created_at'] != null) {
              final timestamp = data['created_at'] as Timestamp;
              data['timestamp'] = timestamp.toDate().toIso8601String();
            }

            comments.add(data);
          }
          return comments;
        });
  }

  // === SYNC WITH LOCAL STORAGE ===

  // Sync local dream to cloud
  static Future<void> syncLocalDreamToCloud(SavedDream dream) async {
    try {
      if (dream.isSharedWithCommunity) {
        await shareDreamToCommunity(dream);
      }
    } catch (e) {
      debugPrint('Error syncing dream to cloud: $e');
    }
  }
}

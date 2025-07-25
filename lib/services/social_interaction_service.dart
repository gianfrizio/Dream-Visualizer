import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SocialInteractionService {
  static const String _likesKey = 'dream_likes';
  static const String _commentsKey = 'dream_comments';
  static const String _commentLikesKey = 'comment_likes';
  static const String _userLikesKey = 'user_likes';
  static const String _userCommentLikesKey = 'user_comment_likes';

  // === GESTIONE LIKE DEI SOGNI ===

  // Ottiene il numero di like per un sogno
  Future<int> getDreamLikes(String dreamId) async {
    final prefs = await SharedPreferences.getInstance();
    final likesData = prefs.getString(_likesKey);

    if (likesData == null) return 0;

    final Map<String, dynamic> likes = jsonDecode(likesData);
    return likes[dreamId] ?? 0;
  }

  // Controlla se l'utente ha messo like a un sogno
  Future<bool> hasUserLikedDream(String dreamId) async {
    final prefs = await SharedPreferences.getInstance();
    final userLikesData = prefs.getString(_userLikesKey);

    if (userLikesData == null) return false;

    final List<dynamic> userLikes = jsonDecode(userLikesData);
    return userLikes.contains(dreamId);
  }

  // Toggle like per un sogno
  Future<Map<String, dynamic>> toggleDreamLike(String dreamId) async {
    final prefs = await SharedPreferences.getInstance();

    // Carica i dati attuali
    final likesData = prefs.getString(_likesKey) ?? '{}';
    final userLikesData = prefs.getString(_userLikesKey) ?? '[]';

    Map<String, dynamic> likes = jsonDecode(likesData);
    List<dynamic> userLikes = jsonDecode(userLikesData);

    bool isLiked = userLikes.contains(dreamId);
    int currentLikes = likes[dreamId] ?? 0;

    if (isLiked) {
      // Rimuovi like
      userLikes.remove(dreamId);
      likes[dreamId] = (currentLikes - 1).clamp(0, double.infinity).toInt();
    } else {
      // Aggiungi like
      userLikes.add(dreamId);
      likes[dreamId] = currentLikes + 1;
    }

    // Salva i dati aggiornati
    await prefs.setString(_likesKey, jsonEncode(likes));
    await prefs.setString(_userLikesKey, jsonEncode(userLikes));

    return {'isLiked': !isLiked, 'likeCount': likes[dreamId]};
  }

  // === GESTIONE COMMENTI ===

  // Struttura per un commento
  static Map<String, dynamic> createComment({
    required String id,
    required String dreamId,
    required String author,
    required String content,
    required DateTime timestamp,
    int likes = 0,
  }) {
    return {
      'id': id,
      'dreamId': dreamId,
      'author': author,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'likes': likes,
    };
  }

  // Aggiunge un commento a un sogno
  Future<void> addComment(String dreamId, String author, String content) async {
    final prefs = await SharedPreferences.getInstance();
    final commentsData = prefs.getString(_commentsKey) ?? '{}';

    Map<String, dynamic> allComments = jsonDecode(commentsData);
    List<dynamic> dreamComments = allComments[dreamId] ?? [];

    final comment = createComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dreamId: dreamId,
      author: author,
      content: content,
      timestamp: DateTime.now(),
    );

    dreamComments.insert(0, comment); // Nuovo commento in cima
    allComments[dreamId] = dreamComments;

    await prefs.setString(_commentsKey, jsonEncode(allComments));
  }

  // Ottiene i commenti per un sogno
  Future<List<Map<String, dynamic>>> getDreamComments(String dreamId) async {
    final prefs = await SharedPreferences.getInstance();
    final commentsData = prefs.getString(_commentsKey) ?? '{}';

    Map<String, dynamic> allComments = jsonDecode(commentsData);
    List<dynamic> dreamComments = allComments[dreamId] ?? [];

    return dreamComments.cast<Map<String, dynamic>>();
  }

  // === GESTIONE LIKE DEI COMMENTI ===

  // Ottiene il numero di like per un commento
  Future<int> getCommentLikes(String commentId) async {
    final prefs = await SharedPreferences.getInstance();
    final commentLikesData = prefs.getString(_commentLikesKey) ?? '{}';

    Map<String, dynamic> commentLikes = jsonDecode(commentLikesData);
    return commentLikes[commentId] ?? 0;
  }

  // Controlla se l'utente ha messo like a un commento
  Future<bool> hasUserLikedComment(String commentId) async {
    final prefs = await SharedPreferences.getInstance();
    final userCommentLikesData = prefs.getString(_userCommentLikesKey) ?? '[]';

    List<dynamic> userCommentLikes = jsonDecode(userCommentLikesData);
    return userCommentLikes.contains(commentId);
  }

  // Toggle like per un commento
  Future<Map<String, dynamic>> toggleCommentLike(String commentId) async {
    final prefs = await SharedPreferences.getInstance();

    final commentLikesData = prefs.getString(_commentLikesKey) ?? '{}';
    final userCommentLikesData = prefs.getString(_userCommentLikesKey) ?? '[]';

    Map<String, dynamic> commentLikes = jsonDecode(commentLikesData);
    List<dynamic> userCommentLikes = jsonDecode(userCommentLikesData);

    bool isLiked = userCommentLikes.contains(commentId);
    int currentLikes = commentLikes[commentId] ?? 0;

    if (isLiked) {
      userCommentLikes.remove(commentId);
      commentLikes[commentId] = (currentLikes - 1)
          .clamp(0, double.infinity)
          .toInt();
    } else {
      userCommentLikes.add(commentId);
      commentLikes[commentId] = currentLikes + 1;
    }

    await prefs.setString(_commentLikesKey, jsonEncode(commentLikes));
    await prefs.setString(_userCommentLikesKey, jsonEncode(userCommentLikes));

    return {'isLiked': !isLiked, 'likeCount': commentLikes[commentId]};
  }

  // === GESTIONE ELIMINAZIONE COMMENTI ===

  // Modifica un commento esistente
  Future<bool> editComment(
    String dreamId,
    String commentId,
    String newContent,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final commentsData = prefs.getString(_commentsKey) ?? '{}';

    Map<String, dynamic> allComments = jsonDecode(commentsData);
    List<dynamic> dreamComments = allComments[dreamId] ?? [];

    // Trova e modifica il commento
    for (int i = 0; i < dreamComments.length; i++) {
      if (dreamComments[i]['id'] == commentId) {
        dreamComments[i]['content'] = newContent;
        dreamComments[i]['edited'] = true;
        dreamComments[i]['editedAt'] = DateTime.now().millisecondsSinceEpoch;

        // Salva i commenti aggiornati
        allComments[dreamId] = dreamComments;
        await prefs.setString(_commentsKey, jsonEncode(allComments));

        return true;
      }
    }

    return false; // Commento non trovato
  }

  // Elimina un commento e i suoi like associati
  Future<bool> deleteComment(String dreamId, String commentId) async {
    final prefs = await SharedPreferences.getInstance();
    final commentsData = prefs.getString(_commentsKey) ?? '{}';

    Map<String, dynamic> allComments = jsonDecode(commentsData);
    List<dynamic> dreamComments = allComments[dreamId] ?? [];

    // Trova e rimuovi il commento
    final originalLength = dreamComments.length;
    dreamComments.removeWhere((comment) => comment['id'] == commentId);

    if (dreamComments.length < originalLength) {
      // Salva i commenti aggiornati
      allComments[dreamId] = dreamComments;
      await prefs.setString(_commentsKey, jsonEncode(allComments));

      // Rimuovi i like associati al commento
      await _removeCommentLikes(commentId);

      return true;
    }

    return false; // Commento non trovato
  } // Rimuove i like associati a un commento eliminato

  Future<void> _removeCommentLikes(String commentId) async {
    final prefs = await SharedPreferences.getInstance();

    // Rimuovi dai like dei commenti
    final commentLikesData = prefs.getString(_commentLikesKey) ?? '{}';
    Map<String, dynamic> commentLikes = jsonDecode(commentLikesData);
    commentLikes.remove(commentId);
    await prefs.setString(_commentLikesKey, jsonEncode(commentLikes));

    // Rimuovi dai like dell'utente
    final userCommentLikesData = prefs.getString(_userCommentLikesKey) ?? '[]';
    List<dynamic> userCommentLikes = jsonDecode(userCommentLikesData);
    userCommentLikes.remove(commentId);
    await prefs.setString(_userCommentLikesKey, jsonEncode(userCommentLikes));
  }

  // === UTILITÀ ===

  // Pulisce tutti i dati sociali (per testing)
  Future<void> clearAllSocialData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_likesKey);
    await prefs.remove(_commentsKey);
    await prefs.remove(_commentLikesKey);
    await prefs.remove(_userLikesKey);
    await prefs.remove(_userCommentLikesKey);
  }
}

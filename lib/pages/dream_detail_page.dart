import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/saved_dream.dart';
import '../services/favorites_service.dart';
import '../services/social_interaction_service.dart';
import '../services/translation_service.dart';

class DreamDetailPage extends StatefulWidget {
  final SavedDream dream;
  final bool isOwner;

  const DreamDetailPage({super.key, required this.dream, this.isOwner = false});

  @override
  State<DreamDetailPage> createState() => _DreamDetailPageState();
}

class _DreamDetailPageState extends State<DreamDetailPage> {
  bool _isLiked = false;
  int _likeCount = 12; // Placeholder
  bool _isFavorite = false;

  // Servizio per gestire i preferiti
  final FavoritesService _favoritesService = FavoritesService();

  // Servizio per gestire like e commenti
  final SocialInteractionService _socialService = SocialInteractionService();

  // Mappa per tracciare i like dei commenti
  final Map<String, int> _commentLikes = {};
  final Set<String> _likedComments = {};

  // Variabili per la traduzione
  bool _isTranslating = false;
  bool _isTranslated = false;
  String? _translatedTitle;
  String? _translatedContent;
  String? _translatedInterpretation;
  List<String>? _translatedTags;

  // Traduzione dei commenti
  final Map<String, String> _translatedComments = {};
  bool _areCommentsTranslated = false;

  List<Comment> _comments = [
    Comment(
      id: '1',
      author: 'Maria R.',
      content: 'Che sogno interessante! Anche io ho fatto qualcosa di simile.',
      timestamp: DateTime.now().subtract(Duration(hours: 2)),
      likes: 3,
      edited: false,
    ),
    Comment(
      id: '2',
      author: 'Giuseppe T.',
      content:
          'L\'interpretazione mi sembra molto accurata. Complimenti per la condivisione!',
      timestamp: DateTime.now().subtract(Duration(hours: 5)),
      likes: 7,
      edited: false,
    ),
    Comment(
      id: '3',
      author: 'Laura M.',
      content:
          'Mi ricorda un sogno che ho fatto da bambina. Grazie per aver condiviso.',
      timestamp: DateTime.now().subtract(Duration(days: 1)),
      likes: 2,
      edited: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Inizializza i like dei commenti
    for (var comment in _comments) {
      _commentLikes[comment.id] = comment.likes;
    }
    // Carica lo stato dei preferiti
    _loadFavoriteStatus();
    // Carica dati sociali (like del sogno, commenti persistenti)
    _loadSocialData();
  }

  Future<void> _loadSocialData() async {
    // Carica like del sogno
    final dreamLikes = await _socialService.getDreamLikes(widget.dream.id);
    final isLiked = await _socialService.hasUserLikedDream(widget.dream.id);

    // Carica commenti persistenti
    final persistentComments = await _socialService.getDreamComments(
      widget.dream.id,
    );

    setState(() {
      _likeCount = dreamLikes;
      _isLiked = isLiked;

      // Sostituisci completamente la lista con i commenti persistenti
      _comments = persistentComments
          .map(
            (commentData) => Comment(
              id: commentData['id'],
              author: commentData['author'],
              content: commentData['content'],
              timestamp: commentData['timestamp'] is String
                  ? DateTime.parse(commentData['timestamp'])
                  : DateTime.fromMillisecondsSinceEpoch(
                      commentData['timestamp'],
                    ),
              likes: commentData['likes'],
              edited: commentData['edited'] ?? false,
            ),
          )
          .toList();
    });

    // Carica like dei commenti
    _loadCommentLikes();
  }

  Future<void> _loadCommentLikes() async {
    for (var comment in _comments) {
      final likes = await _socialService.getCommentLikes(comment.id);
      final isLiked = await _socialService.hasUserLikedComment(comment.id);

      setState(() {
        _commentLikes[comment.id] = likes;
        if (isLiked) {
          _likedComments.add(comment.id);
        }
      });
    }
  }

  Future<void> _loadFavoriteStatus() async {
    final isFav = await _favoritesService.isFavorite(widget.dream.id);
    setState(() {
      _isFavorite = isFav;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _isTranslated && _translatedTitle != null
                    ? _translatedTitle!
                    : widget.dream.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background:
                  widget.dream.imageUrl != null &&
                      widget.dream.imageUrl!.isNotEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(widget.dream.imageUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.primaryColor,
                            theme.primaryColor.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.nights_stay,
                          size: 80,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
            ),
            actions: [
              IconButton(
                onPressed: _translateDream,
                icon: Stack(
                  children: [
                    Icon(
                      _isTranslated
                          ? Icons.translate_outlined
                          : Icons.translate,
                    ),
                    if (_isTranslating)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: Localizations.localeOf(context).languageCode == 'en'
                    ? (_isTranslated ? 'Show original' : 'Translate')
                    : (_isTranslated ? 'Mostra originale' : 'Traduci'),
              ),
              IconButton(onPressed: _shareDream, icon: Icon(Icons.share)),
              if (widget.isOwner)
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text(
                            Localizations.localeOf(context).languageCode == 'en'
                                ? 'Edit'
                                : 'Modifica',
                          ),
                        ],
                      ),
                      onTap: () => _editDream(),
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            Localizations.localeOf(context).languageCode == 'en'
                                ? 'Delete'
                                : 'Elimina',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                      onTap: () => _deleteDream(),
                    ),
                  ],
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con info utente e data
                  _buildUserHeader(theme),
                  SizedBox(height: 24),

                  // Contenuto del sogno
                  _buildDreamContent(theme),
                  SizedBox(height: 24),

                  // Interpretazione
                  _buildInterpretation(theme),
                  SizedBox(height: 24),

                  // Tags
                  if (widget.dream.tags.isNotEmpty) _buildTags(theme),
                  if (widget.dream.tags.isNotEmpty) SizedBox(height: 24),

                  // Actions (like, condividi)
                  _buildActions(theme),
                  SizedBox(height: 32),

                  // Sezione commenti
                  _buildCommentsSection(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Icon(Icons.person, color: theme.colorScheme.primary, size: 28),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isOwner
                    ? (Localizations.localeOf(context).languageCode == 'en'
                          ? 'My dreams'
                          : 'I miei sogni')
                    : (Localizations.localeOf(context).languageCode == 'en'
                          ? 'Anonymous Dreamer'
                          : 'Sognatore Anonimo'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                _formatDate(widget.dream.createdAt),
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (widget.dream.isSharedWithCommunity)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.public, size: 14, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  Localizations.localeOf(context).languageCode == 'en'
                      ? 'Public'
                      : 'Pubblico',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDreamContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.nights_stay, color: theme.colorScheme.primary, size: 20),
            SizedBox(width: 8),
            Text(
              Localizations.localeOf(context).languageCode == 'en'
                  ? 'The Dream'
                  : 'Il Sogno',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Text(
            _isTranslated && _translatedContent != null
                ? _translatedContent!
                : widget.dream.dreamText,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterpretation(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.psychology, color: theme.colorScheme.primary, size: 20),
            SizedBox(width: 8),
            Text(
              Localizations.localeOf(context).languageCode == 'en'
                  ? 'Interpretation'
                  : 'Interpretazione',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Text(
            _isTranslated && _translatedInterpretation != null
                ? _translatedInterpretation!
                : widget.dream.interpretation,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTags(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Localizations.localeOf(context).languageCode == 'en' ? 'Tags' : 'Tag',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              (_isTranslated && _translatedTags != null
                      ? _translatedTags!
                      : widget.dream.tags)
                  .asMap()
                  .entries
                  .map((entry) {
                    final tag = entry.value;

                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(
                          0.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  })
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildActions(ThemeData theme) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _toggleLike,
          icon: Icon(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked
                ? Colors.red
                : theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          label: Text('$_likeCount'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isLiked
                ? Colors.red.withOpacity(0.1)
                : theme.colorScheme.surfaceVariant.withOpacity(0.3),
            foregroundColor: _isLiked
                ? Colors.red
                : theme.colorScheme.onSurface.withOpacity(0.6),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _showAddCommentDialog,
          icon: Icon(Icons.comment),
          label: Text(
            Localizations.localeOf(context).languageCode == 'en'
                ? 'Comment'
                : 'Commenta',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            foregroundColor: theme.colorScheme.primary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        Spacer(),
        IconButton(
          onPressed: _toggleFavorite,
          icon: Icon(
            _isFavorite ? Icons.bookmark : Icons.bookmark_border,
            color: _isFavorite
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        IconButton(
          onPressed: _shareDream,
          icon: Icon(
            Icons.share,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.comment, color: theme.colorScheme.primary, size: 20),
            SizedBox(width: 8),
            Text(
              Localizations.localeOf(context).languageCode == 'en'
                  ? 'Comments (${_comments.length})'
                  : 'Commenti (${_comments.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        ..._comments
            .map((comment) => _buildCommentCard(comment, theme))
            .toList(),
      ],
    );
  }

  Widget _buildCommentCard(Comment comment, ThemeData theme) {
    return GestureDetector(
      onLongPress: comment.author == 'Tu'
          ? () => _showCommentContextMenu(comment)
          : null,
      child: Card(
        margin: EdgeInsets.only(bottom: 12),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      comment.author[0],
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              comment.author,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            // Indicatore di commento modificato
                            if (comment.edited == true) ...[
                              SizedBox(width: 4),
                              Icon(
                                Icons.edit,
                                size: 12,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _formatDate(comment.timestamp),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _likeComment(comment),
                    icon: Icon(
                      _likedComments.contains(comment.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 16,
                      color: _likedComments.contains(comment.id)
                          ? Colors.red
                          : null,
                    ),
                    label: Text(
                      '${_commentLikes[comment.id] ?? comment.likes}',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface.withOpacity(
                        0.6,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _areCommentsTranslated &&
                              _translatedComments[comment.id] != null
                          ? _translatedComments[comment.id]!
                          : comment.content,
                      style: TextStyle(
                        height: 1.4,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  // Pulsante traduzione per il commento
                  if (!_isTranslating)
                    IconButton(
                      onPressed: () => _translateComment(comment),
                      icon: Icon(
                        _areCommentsTranslated &&
                                _translatedComments[comment.id] != null
                            ? Icons.translate_outlined
                            : Icons.translate,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      iconSize: 16,
                      padding: EdgeInsets.all(4),
                      constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                      tooltip:
                          Localizations.localeOf(context).languageCode == 'en'
                          ? (_areCommentsTranslated &&
                                    _translatedComments[comment.id] != null
                                ? 'Show original'
                                : 'Translate')
                          : (_areCommentsTranslated &&
                                    _translatedComments[comment.id] != null
                                ? 'Mostra originale'
                                : 'Traduci'),
                    ),
                ],
              ),
              // Hint per il menu contestuale
              if (comment.author == 'Tu')
                Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 12,
                        color: theme.colorScheme.primary.withOpacity(0.6),
                      ),
                      SizedBox(width: 4),
                      Text(
                        Localizations.localeOf(context).languageCode == 'en'
                            ? 'Long press for options'
                            : 'Tieni premuto per opzioni',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.primary.withOpacity(0.6),
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}g fa';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h fa';
    } else {
      return '${difference.inMinutes}m fa';
    }
  }

  void _toggleLike() async {
    final result = await _socialService.toggleDreamLike(widget.dream.id);

    setState(() {
      _isLiked = result['isLiked'];
      _likeCount = result['likeCount'];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isLiked
              ? (Localizations.localeOf(context).languageCode == 'en'
                    ? '❤️ You like this dream!'
                    : '❤️ Ti piace questo sogno!')
              : (Localizations.localeOf(context).languageCode == 'en'
                    ? '💔 You no longer like this'
                    : '💔 Non ti piace più'),
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _shareDream() {
    // Per ora condividi solo il testo, in futuro verrà aggiunto il link
    // TODO: Quando l'app sarà online, generare link del tipo:
    // https://dreamvisualizer.app/dream/${widget.dream.id}

    final dreamUrl = 'https://dreamvisualizer.app/dream/${widget.dream.id}';
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    final shareText = isEnglish
        ? 'Check out this interesting dream: "${widget.dream.title}"\n\n'
              '${widget.dream.dreamText}\n\n'
              'View on DreamVisualizer: $dreamUrl'
        : 'Guarda questo sogno interessante: "${widget.dream.title}"\n\n'
              '${widget.dream.dreamText}\n\n'
              'Visualizza su DreamVisualizer: $dreamUrl';

    Share.share(
      shareText,
      subject: isEnglish
          ? 'Dream shared from DreamVisualizer'
          : 'Sogno condiviso da DreamVisualizer',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEnglish
              ? '🔗 Dream shared with link!'
              : '🔗 Sogno condiviso con link!',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAddCommentDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          Localizations.localeOf(context).languageCode == 'en'
              ? 'Add a comment'
              : 'Aggiungi un commento',
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: Localizations.localeOf(context).languageCode == 'en'
                ? 'Write your comment...'
                : 'Scrivi il tuo commento...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              Localizations.localeOf(context).languageCode == 'en'
                  ? 'Cancel'
                  : 'Annulla',
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                // Aggiungi il commento usando il servizio persistente
                await _socialService.addComment(
                  widget.dream.id,
                  'Tu',
                  controller.text.trim(),
                );

                // Ricarica i commenti per mostrare il nuovo commento
                await _loadSocialData();

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      Localizations.localeOf(context).languageCode == 'en'
                          ? '💬 Comment added!'
                          : '💬 Commento aggiunto!',
                    ),
                  ),
                );
              }
            },
            child: Text(
              Localizations.localeOf(context).languageCode == 'en'
                  ? 'Publish'
                  : 'Pubblica',
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFavorite() async {
    final isFav = await _favoritesService.toggleFavorite(widget.dream);
    setState(() {
      _isFavorite = isFav;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite
              ? (Localizations.localeOf(context).languageCode == 'en'
                    ? '⭐ Added to favorites!'
                    : '⭐ Aggiunto ai preferiti!')
              : (Localizations.localeOf(context).languageCode == 'en'
                    ? '💔 Removed from favorites'
                    : '💔 Rimosso dai preferiti'),
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _likeComment(Comment comment) async {
    try {
      // Aggiorna usando il servizio persistente
      final result = await _socialService.toggleCommentLike(comment.id);

      // Aggiorna immediatamente lo stato locale
      setState(() {
        _commentLikes[comment.id] = result['likeCount'];
        if (result['isLiked']) {
          _likedComments.add(comment.id);
        } else {
          _likedComments.remove(comment.id);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['isLiked']
                ? (Localizations.localeOf(context).languageCode == 'en'
                      ? '❤️ You like ${comment.author}\'s comment!'
                      : '❤️ Ti piace il commento di ${comment.author}!')
                : (Localizations.localeOf(context).languageCode == 'en'
                      ? '💔 You no longer like ${comment.author}\'s comment'
                      : '💔 Non ti piace più il commento di ${comment.author}'),
          ),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Errore toggle like commento: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'en'
                ? 'Error updating like'
                : 'Errore nell\'aggiornamento del like',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Mostra il menu contestuale per i commenti dell'utente
  void _showCommentContextMenu(Comment comment) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                Localizations.localeOf(context).languageCode == 'en'
                    ? 'Comment Options'
                    : 'Opzioni Commento',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text(
                  Localizations.localeOf(context).languageCode == 'en'
                      ? 'Edit Comment'
                      : 'Modifica Commento',
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _editComment(comment);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text(
                  Localizations.localeOf(context).languageCode == 'en'
                      ? 'Delete Comment'
                      : 'Elimina Commento',
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _deleteComment(comment.id);
                },
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // Metodo per modificare un commento
  void _editComment(Comment comment) {
    final TextEditingController editController = TextEditingController(
      text: comment.content,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            Localizations.localeOf(context).languageCode == 'en'
                ? 'Edit Comment'
                : 'Modifica Commento',
          ),
          content: TextField(
            controller: editController,
            decoration: InputDecoration(
              hintText: Localizations.localeOf(context).languageCode == 'en'
                  ? 'Edit your comment...'
                  : 'Modifica il tuo commento...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            maxLength: 500,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                Localizations.localeOf(context).languageCode == 'en'
                    ? 'Cancel'
                    : 'Annulla',
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newContent = editController.text.trim();
                if (newContent.isNotEmpty && newContent != comment.content) {
                  final success = await _socialService.editComment(
                    widget.dream.id,
                    comment.id,
                    newContent,
                  );

                  if (success) {
                    Navigator.of(context).pop();

                    // Aggiorna la lista dei commenti
                    final updatedComments = await _socialService
                        .getDreamComments(widget.dream.id);
                    setState(() {
                      _comments = updatedComments
                          .map(
                            (c) => Comment(
                              id: c['id'],
                              author: c['author'],
                              content: c['content'],
                              timestamp: c['timestamp'] is String
                                  ? DateTime.parse(c['timestamp'])
                                  : DateTime.fromMillisecondsSinceEpoch(
                                      c['timestamp'],
                                    ),
                              likes: c['likes'] ?? 0,
                              edited: c['edited'] ?? false,
                            ),
                          )
                          .toList();
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          Localizations.localeOf(context).languageCode == 'en'
                              ? '✏️ Comment updated successfully!'
                              : '✏️ Commento aggiornato con successo!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          Localizations.localeOf(context).languageCode == 'en'
                              ? 'Error updating comment'
                              : 'Errore nell\'aggiornamento del commento',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                Localizations.localeOf(context).languageCode == 'en'
                    ? 'Save'
                    : 'Salva',
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteComment(String commentId) async {
    // Mostra dialog di conferma
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            Localizations.localeOf(context).languageCode == 'en'
                ? 'Delete Comment'
                : 'Elimina Commento',
          ),
          content: Text(
            Localizations.localeOf(context).languageCode == 'en'
                ? 'Are you sure you want to delete this comment?'
                : 'Sei sicuro di voler eliminare questo commento?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                Localizations.localeOf(context).languageCode == 'en'
                    ? 'Cancel'
                    : 'Annulla',
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                Localizations.localeOf(context).languageCode == 'en'
                    ? 'Delete'
                    : 'Elimina',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final success = await _socialService.deleteComment(
          widget.dream.id,
          commentId,
        );

        if (success) {
          // Rimuovi il commento dalla lista locale
          setState(() {
            _comments.removeWhere((comment) => comment.id == commentId);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Localizations.localeOf(context).languageCode == 'en'
                    ? '🗑️ Comment deleted successfully!'
                    : '🗑️ Commento eliminato con successo!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Localizations.localeOf(context).languageCode == 'en'
                    ? 'Error: Comment not found'
                    : 'Errore: Commento non trovato',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('Errore eliminazione commento: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'en'
                  ? 'Error deleting comment'
                  : 'Errore nell\'eliminazione del commento',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editDream() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Localizations.localeOf(context).languageCode == 'en'
              ? '✏️ Edit dream (feature in development)'
              : '✏️ Modifica sogno (funzione in sviluppo)',
        ),
      ),
    );
  }

  void _deleteDream() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          Localizations.localeOf(context).languageCode == 'en'
              ? 'Delete dream'
              : 'Elimina sogno',
        ),
        content: Text(
          Localizations.localeOf(context).languageCode == 'en'
              ? 'Are you sure you want to delete this dream?'
              : 'Sei sicuro di voler eliminare questo sogno?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              Localizations.localeOf(context).languageCode == 'en'
                  ? 'Cancel'
                  : 'Annulla',
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    Localizations.localeOf(context).languageCode == 'en'
                        ? '🗑️ Dream deleted'
                        : '🗑️ Sogno eliminato',
                  ),
                ),
              );
            },
            child: Text(
              Localizations.localeOf(context).languageCode == 'en'
                  ? 'Delete'
                  : 'Elimina',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // Funzione per tradurre il sogno
  Future<void> _translateDream() async {
    if (_isTranslating) return;

    setState(() {
      _isTranslating = true;
    });

    try {
      final currentLang = Localizations.localeOf(context).languageCode;
      final targetLang = currentLang; // Traduce NELLA lingua dell'app

      // Se è già tradotto, torna alla versione originale
      if (_isTranslated) {
        setState(() {
          _isTranslated = false;
          _isTranslating = false;
          _translatedTitle = null;
          _translatedContent = null;
          _translatedInterpretation = null;
          _translatedTags = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLang == 'en'
                  ? '↩️ Original version restored'
                  : '↩️ Versione originale ripristinata',
            ),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Rileva la lingua del sogno
      final dreamLang = TranslationService.detectLanguage(
        widget.dream.dreamText,
      );

      print('Dream language detected: $dreamLang, target: $targetLang');

      // Traduci sempre se la lingua è incerta, oppure se è diversa dalla target
      if (dreamLang == 'auto' || dreamLang != targetLang) {
        // Se la lingua è incerta, prova a tradurre comunque
        final sourceLang = dreamLang == 'auto'
            ? (targetLang == 'en' ? 'it' : 'en')
            : dreamLang;

        final translatedTitle = await TranslationService.translateText(
          widget.dream.title,
          sourceLang,
          targetLang,
        );
        final translatedContent = await TranslationService.translateText(
          widget.dream.dreamText,
          sourceLang,
          targetLang,
        );
        final translatedInterpretation = await TranslationService.translateText(
          widget.dream.interpretation,
          sourceLang,
          targetLang,
        );
        final translatedTags = await TranslationService.translateTags(
          widget.dream.tags,
          sourceLang,
          targetLang,
        );

        // Verifica che le traduzioni siano diverse dagli originali
        if (translatedTitle != widget.dream.title ||
            translatedContent != widget.dream.dreamText ||
            translatedInterpretation != widget.dream.interpretation) {
          setState(() {
            _translatedTitle = translatedTitle;
            _translatedContent = translatedContent;
            _translatedInterpretation = translatedInterpretation;
            _translatedTags = translatedTags;
            _isTranslated = true;
            _isTranslating = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                currentLang == 'en'
                    ? '🌐 Dream translated!'
                    : '🌐 Sogno tradotto!',
              ),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // La traduzione non ha prodotto risultati diversi
          setState(() {
            _isTranslating = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                currentLang == 'en'
                    ? '⚠️ Dream is already in target language'
                    : '⚠️ Il sogno è già nella lingua di destinazione',
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // La lingua del sogno è già quella target
        setState(() {
          _isTranslating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLang == 'en'
                  ? '⚠️ Dream is already in target language'
                  : '⚠️ Il sogno è già nella lingua di destinazione',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Translation error: $e');
      setState(() {
        _isTranslating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'en'
                ? 'Translation error: $e'
                : 'Errore di traduzione: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Funzione per tradurre un singolo commento
  Future<void> _translateComment(Comment comment) async {
    if (_isTranslating) return;

    setState(() {
      _isTranslating = true;
    });

    try {
      final currentLang = Localizations.localeOf(context).languageCode;
      final targetLang = currentLang; // Traduce NELLA lingua dell'app

      // Se il commento è già tradotto, lo rimuoviamo dalla mappa (torna all'originale)
      if (_translatedComments.containsKey(comment.id)) {
        setState(() {
          _translatedComments.remove(comment.id);
          _isTranslating = false;
          // Se non ci sono più commenti tradotti, reset dello stato generale
          if (_translatedComments.isEmpty) {
            _areCommentsTranslated = false;
          }
        });
        return;
      }

      // Rileva la lingua del commento
      final commentLang = TranslationService.detectLanguage(comment.content);

      // Traduci solo se necessario
      if (commentLang != targetLang) {
        final translatedContent = await TranslationService.translateText(
          comment.content,
          commentLang,
          targetLang,
        );

        setState(() {
          _translatedComments[comment.id] = translatedContent;
          _areCommentsTranslated = true;
          _isTranslating = false;
        });

        // Mostra messaggio di conferma
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLang == 'en'
                  ? '🌐 Comment translated!'
                  : '🌐 Commento tradotto!',
            ),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        setState(() {
          _isTranslating = false;
        });
      }
    } catch (e) {
      setState(() {
        _isTranslating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'en'
                ? 'Translation error'
                : 'Errore di traduzione',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}

class Comment {
  final String id;
  final String author;
  final String content;
  final DateTime timestamp;
  final int likes;
  final bool edited;

  Comment({
    required this.id,
    required this.author,
    required this.content,
    required this.timestamp,
    required this.likes,
    this.edited = false,
  });
}

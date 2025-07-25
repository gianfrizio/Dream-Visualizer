import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/saved_dream.dart';

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
  final List<Comment> _comments = [
    Comment(
      id: '1',
      author: 'Maria R.',
      content: 'Che sogno interessante! Anche io ho fatto qualcosa di simile.',
      timestamp: DateTime.now().subtract(Duration(hours: 2)),
      likes: 3,
    ),
    Comment(
      id: '2',
      author: 'Giuseppe T.',
      content:
          'L\'interpretazione mi sembra molto accurata. Complimenti per la condivisione!',
      timestamp: DateTime.now().subtract(Duration(hours: 5)),
      likes: 7,
    ),
    Comment(
      id: '3',
      author: 'Laura M.',
      content:
          'Mi ricorda un sogno che ho fatto da bambina. Grazie per aver condiviso.',
      timestamp: DateTime.now().subtract(Duration(days: 1)),
      likes: 2,
    ),
  ];

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
                widget.dream.title,
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
              IconButton(onPressed: _shareDream, icon: Icon(Icons.share)),
              if (widget.isOwner)
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Modifica'),
                        ],
                      ),
                      onTap: () => _editDream(),
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Elimina', style: TextStyle(color: Colors.red)),
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
          backgroundColor: theme.primaryColor.withOpacity(0.1),
          child: Icon(Icons.person, color: theme.primaryColor, size: 28),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isOwner ? 'I miei sogni' : 'Sognatore Anonimo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.primaryColor,
                ),
              ),
              Text(
                _formatDate(widget.dream.createdAt),
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
                  'Pubblico',
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
            Icon(Icons.nights_stay, color: theme.primaryColor, size: 20),
            SizedBox(width: 8),
            Text(
              'Il Sogno',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            widget.dream.dreamText,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey[800],
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
            Icon(Icons.psychology, color: theme.primaryColor, size: 20),
            SizedBox(width: 8),
            Text(
              'Interpretazione',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
          ),
          child: Text(
            widget.dream.interpretation,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey[800],
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
          'Tag',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.dream.tags.map((tag) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
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
            color: _isLiked ? Colors.red : Colors.grey[600],
          ),
          label: Text('$_likeCount'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isLiked
                ? Colors.red.withOpacity(0.1)
                : Colors.grey[100],
            foregroundColor: _isLiked ? Colors.red : Colors.grey[600],
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
          label: Text('Commenta'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            foregroundColor: theme.primaryColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        Spacer(),
        IconButton(
          onPressed: _shareDream,
          icon: Icon(Icons.share, color: Colors.grey[600]),
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
            Icon(Icons.comment, color: theme.primaryColor, size: 20),
            SizedBox(width: 8),
            Text(
              'Commenti (${_comments.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
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
    return Card(
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
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                  child: Text(
                    comment.author[0],
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.author,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatDate(comment.timestamp),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _likeComment(comment),
                  icon: Icon(Icons.favorite_border, size: 16),
                  label: Text('${comment.likes}'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              comment.content,
              style: TextStyle(height: 1.4, color: Colors.grey[700]),
            ),
          ],
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

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isLiked ? '❤️ Ti piace questo sogno!' : '💔 Non ti piace più',
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _shareDream() {
    Share.share(
      'Guarda questo sogno interessante: "${widget.dream.title}"\n\n${widget.dream.dreamText}',
      subject: 'Sogno condiviso da DreamVisualizer',
    );
  }

  void _showAddCommentDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Aggiungi un commento'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Scrivi il tuo commento...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('💬 Commento aggiunto!')),
                );
              }
            },
            child: Text('Pubblica'),
          ),
        ],
      ),
    );
  }

  void _likeComment(Comment comment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❤️ Ti piace il commento di ${comment.author}!')),
    );
  }

  void _editDream() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✏️ Modifica sogno (funzione in sviluppo)')),
    );
  }

  void _deleteDream() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Elimina sogno'),
        content: Text('Sei sicuro di voler eliminare questo sogno?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('🗑️ Sogno eliminato')));
            },
            child: Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class Comment {
  final String id;
  final String author;
  final String content;
  final DateTime timestamp;
  final int likes;

  Comment({
    required this.id,
    required this.author,
    required this.content,
    required this.timestamp,
    required this.likes,
  });
}

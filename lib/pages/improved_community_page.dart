import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/saved_dream.dart';
import '../services/dream_storage_service.dart';
import '../services/favorites_service.dart';
import '../services/social_interaction_service.dart';
import 'dream_detail_page.dart';
import '../l10n/app_localizations.dart';

class ImprovedCommunityPage extends StatefulWidget {
  const ImprovedCommunityPage({super.key});

  @override
  State<ImprovedCommunityPage> createState() => _ImprovedCommunityPageState();
}

class _ImprovedCommunityPageState extends State<ImprovedCommunityPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final DreamStorageService _dreamStorage = DreamStorageService();
  final FavoritesService _favoritesService = FavoritesService();
  final SocialInteractionService _socialService = SocialInteractionService();

  List<SavedDream> _userDreams = [];
  List<SavedDream> _communityDreams = [];
  List<SavedDream> _favoriteDreams = [];
  List<SavedDream> _filteredDreams = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';
  String _sortBy = 'newest';
  String _selectedLanguage = 'all';

  // Mappe per i contatori sociali
  Map<String, int> _dreamLikeCounts = {};
  Map<String, int> _dreamCommentCounts = {};
  Map<String, bool> _userLikedDreams = {};
  Map<String, bool> _userFavoriteDreams = {};

  // Mappe per i like dei commenti
  Map<String, int> _commentLikeCounts = {};
  Map<String, bool> _userLikedComments = {};

  // Variabile rimossa: non utilizzata direttamente per l'UI corrente

  // Etichette multilingue per categorie
  List<String> get _categories {
    return ['all', 'nightmare', 'adventure', 'romance', 'fantasy', 'recurring'];
  }

  // Etichette multilingue per ordinamento
  List<String> get _sortOptions {
    return ['newest', 'alphabetical', 'popular'];
  }

  // Opzioni per filtro lingua
  List<String> get _languageOptions {
    return ['all', 'italian', 'english'];
  }

  String _getCategoryDisplayName(String categoryKey) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    switch (categoryKey) {
      case 'all':
        return isEnglish ? 'All' : 'Tutti';
      case 'nightmare':
        return isEnglish ? 'Nightmare' : 'Incubo';
      case 'adventure':
        return isEnglish ? 'Adventure' : 'Avventura';
      case 'romance':
        return isEnglish ? 'Romance' : 'Romantico';
      case 'fantasy':
        return isEnglish ? 'Fantasy' : 'Fantasy';
      case 'recurring':
        return isEnglish ? 'Recurring' : 'Ricorrente';
      default:
        return categoryKey;
    }
  }

  String _getSortDisplayName(String sortKey) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    switch (sortKey) {
      case 'newest':
        return isEnglish ? 'Newest' : 'Più recenti';
      case 'alphabetical':
        return isEnglish ? 'Alphabetical' : 'Alfabetico';
      case 'popular':
        return isEnglish ? 'Popular' : 'Popolari';
      default:
        return sortKey;
    }
  }

  String _getLanguageDisplayName(String languageKey) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    switch (languageKey) {
      case 'all':
        return isEnglish ? 'All' : 'Tutte';
      case 'italian':
        return isEnglish ? 'Italian' : 'Italiano';
      case 'english':
        return isEnglish ? 'English' : 'Inglese';
      default:
        return languageKey;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDreams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDreams() async {
    setState(() => _isLoading = true);
    try {
      // Prima rimuovi eventuali duplicati esistenti
      await _dreamStorage.removeDuplicates();

      final dreams = await _dreamStorage.getSavedDreams();
      setState(() {
        _userDreams = dreams;

        // Inizializza community dreams con i sogni di esempio
        _communityDreams = _generateSampleCommunityDreams();

        // Aggiungi i sogni dell'utente che sono condivisi con la community
        // ma solo se non sono già presenti (evita duplicazioni)
        for (final userDream in dreams) {
          if (userDream.isSharedWithCommunity) {
            final existingIndex = _communityDreams.indexWhere(
              (d) => d.id == userDream.id,
            );
            if (existingIndex == -1) {
              _communityDreams.add(userDream);
            } else {
              _communityDreams[existingIndex] = userDream;
            }
          }
        }

        // Rimuovi eventuali duplicati che potrebbero essersi formati
        _removeDuplicatesFromCommunity();

        _filteredDreams = _communityDreams;
        _isLoading = false;
      });

      // Carica i sogni preferiti separatamente
      _loadFavoriteDreams();

      // Carica i dati sociali (like e commenti) per tutti i sogni
      _loadSocialData();
    } catch (e) {
      debugPrint('Errore caricamento sogni: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFavoriteDreams() async {
    try {
      final favorites = await _favoritesService.getFavoriteDreams();
      setState(() {
        _favoriteDreams = favorites;
      });
    } catch (e) {
      debugPrint('Errore caricamento preferiti: $e');
    }
  }

  Future<void> _loadSocialData() async {
    // Carica i dati sociali per tutti i sogni della community
    for (final dream in _communityDreams) {
      try {
        final likeCount = await _socialService.getDreamLikes(dream.id);
        final comments = await _socialService.getDreamComments(dream.id);
        final isLiked = await _socialService.hasUserLikedDream(dream.id);
        final isFavorite = await _favoritesService.isFavorite(dream.id);

        setState(() {
          _dreamLikeCounts[dream.id] = likeCount;
          _dreamCommentCounts[dream.id] = comments.length;
          _userLikedDreams[dream.id] = isLiked;
          _userFavoriteDreams[dream.id] = isFavorite;
        });

        // Carica i dati dei like per i commenti di questo sogno
        await _loadCommentLikesData(comments);
      } catch (e) {
        debugPrint('Errore caricamento dati sociali per sogno ${dream.id}: $e');
      }
    }
  }

  Future<void> _loadCommentLikesData(
    List<Map<String, dynamic>> comments,
  ) async {
    // Carica i dati dei like per ogni commento
    for (final comment in comments) {
      try {
        final commentId = comment['id'];
        if (commentId != null) {
          final likeCount = await _socialService.getCommentLikes(commentId);
          final isLiked = await _socialService.hasUserLikedComment(commentId);

          setState(() {
            _commentLikeCounts[commentId] = likeCount;
            _userLikedComments[commentId] = isLiked;
          });
        }
      } catch (e) {
        debugPrint('Errore caricamento like commento ${comment['id']}: $e');
      }
    }
  }

  List<SavedDream> _generateSampleCommunityDreams() {
    return [
      SavedDream(
        id: 'community_1',
        title: 'Volo sopra la città',
        dreamText:
            'Ho sognato di volare sopra la mia città natale, tutto sembrava così reale...',
        interpretation: 'Un sogno di libertà e controllo sulla propria vita',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        tags: ['volo', 'libertà', 'città'],
        isSharedWithCommunity: true,
        language: 'italian',
      ),
      SavedDream(
        id: 'community_2',
        title: 'L\'oceano infinito',
        dreamText:
            'Camminavo su una spiaggia infinita con onde che sussurravano segreti...',
        interpretation: 'Rappresenta il subconscio e le emozioni profonde',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        tags: ['oceano', 'pace', 'infinito'],
        isSharedWithCommunity: true,
        language: 'italian',
      ),
      SavedDream(
        id: 'community_3',
        title: 'Il labirinto dei ricordi',
        dreamText:
            'Ero intrappolato in un labirinto fatto di ricordi del passato...',
        interpretation: 'Difficoltà nel lasciare andare il passato',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        tags: ['labirinto', 'ricordi', 'passato'],
        isSharedWithCommunity: true,
        language: 'italian',
      ),
      SavedDream(
        id: 'community_4',
        title: 'Flying Through the Stars',
        dreamText:
            'I was soaring through a vast cosmic landscape, stars twinkling all around me...',
        interpretation:
            'A dream representing aspirations and limitless potential',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        tags: ['flying', 'stars', 'cosmic'],
        isSharedWithCommunity: true,
        language: 'english',
      ),
      SavedDream(
        id: 'community_5',
        title: 'The Ancient Forest',
        dreamText:
            'I walked through an ancient forest where trees whispered forgotten secrets...',
        interpretation: 'Connection with nature and ancestral wisdom',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        tags: ['forest', 'nature', 'ancient'],
        isSharedWithCommunity: true,
        language: 'english',
      ),
      SavedDream(
        id: 'community_6',
        title: 'The Mirror World',
        dreamText:
            'Everything was reversed in this strange mirror world where I lived...',
        interpretation: 'Self-reflection and examining different perspectives',
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
        tags: ['mirror', 'reflection', 'perspective'],
        isSharedWithCommunity: true,
        language: 'english',
      ),
    ];
  }

  Widget _buildWelcomeWidget() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer.withOpacity(0.95),
            scheme.secondaryContainer.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEnglish ? 'Welcome to Community' : 'Benvenuto nella Community',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEnglish
                ? 'Explore other people\'s dreams, share yours and discover new interpretations!'
                : 'Esplora i sogni degli altri, condividi i tuoi e scopri nuove interpretazioni!',
            style: TextStyle(
              fontSize: 14,
              color: scheme.onPrimaryContainer.withOpacity(0.92),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barra di ricerca
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: Localizations.localeOf(context).languageCode == 'en'
                  ? 'Search dreams...'
                  : 'Cerca sogni...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant,
            ),
            onChanged: _filterDreams,
          ),
          const SizedBox(height: 12),

          // Filtri
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText:
                        Localizations.localeOf(context).languageCode == 'en'
                        ? 'Cat.'
                        : 'Cat.',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant,
                    labelStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.95),
                      fontWeight: FontWeight.w600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    isDense: true,
                  ),
                  isExpanded: true,
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(
                        _getCategoryDisplayName(category),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                      _filterDreams(_searchController.text);
                    });
                  },
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  decoration: InputDecoration(
                    labelText:
                        Localizations.localeOf(context).languageCode == 'en'
                        ? 'Lang.'
                        : 'Lingua',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant,
                    labelStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.95),
                      fontWeight: FontWeight.w600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    isDense: true,
                  ),
                  isExpanded: true,
                  items: _languageOptions.map((language) {
                    return DropdownMenuItem(
                      value: language,
                      child: Text(
                        _getLanguageDisplayName(language),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLanguage = value!;
                      _filterDreams(_searchController.text);
                    });
                  },
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: InputDecoration(
                    labelText:
                        Localizations.localeOf(context).languageCode == 'en'
                        ? 'Sort'
                        : 'Ordina',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant,
                    labelStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.95),
                      fontWeight: FontWeight.w600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    isDense: true,
                  ),
                  isExpanded: true,
                  items: _sortOptions.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(
                        _getSortDisplayName(option),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                      _sortDreams();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _filterDreams(String query) {
    setState(() {
      _filteredDreams = _communityDreams.where((dream) {
        final matchesQuery =
            dream.title.toLowerCase().contains(query.toLowerCase()) ||
            dream.dreamText.toLowerCase().contains(query.toLowerCase());
        final matchesCategory =
            _selectedCategory == 'all' ||
            dream.tags.any(
              (tag) =>
                  tag.toLowerCase().contains(_selectedCategory.toLowerCase()),
            );

        // Filtro per lingua (per ora basato sul contenuto del testo)
        final matchesLanguage =
            _selectedLanguage == 'all' ||
            _dreamMatchesLanguage(dream, _selectedLanguage);

        return matchesQuery && matchesCategory && matchesLanguage;
      }).toList();
      _sortDreams();
    });
  }

  // Metodo per determinare se un sogno corrisponde alla lingua selezionata
  bool _dreamMatchesLanguage(SavedDream dream, String language) {
    if (language == 'all') return true;

    // Se il sogno ha il campo language, usalo direttamente
    if (dream.language.isNotEmpty) {
      return dream.language == language;
    }

    // Fallback: usa il metodo di rilevamento automatico per sogni esistenti senza campo language
    final detectedLanguage = SavedDream.detectLanguage(
      '${dream.title} ${dream.dreamText} ${dream.interpretation}',
    );
    return detectedLanguage == language;
  }

  void _sortDreams() {
    setState(() {
      switch (_sortBy) {
        case 'newest':
          _filteredDreams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'alphabetical':
          _filteredDreams.sort((a, b) => a.title.compareTo(b.title));
          break;
        case 'popular':
        default:
          // Per 'popular' manteniamo l'ordine attuale
          break;
      }
    });
  }

  Widget _buildDreamCard(SavedDream dream) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DreamDetailPage(dream: dream),
            ),
          );
          // Ricarica i dati sociali quando si torna dalla pagina del sogno
          _loadSocialData();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      dream.title.isNotEmpty
                          ? dream.title[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dream.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${dream.createdAt.day}/${dream.createdAt.month}/${dream.createdAt.year}',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                dream.dreamText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (dream.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: dream.tags.take(3).map((tag) {
                    return Chip(
                      label: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceVariant.withOpacity(0.7),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  // Pulsante Like
                  GestureDetector(
                    onTap: () => _toggleLikeFromCommunity(dream),
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: (_userLikedDreams[dream.id] ?? false)
                              ? Colors.red
                              : Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_dreamLikeCounts[dream.id] ?? 0}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Pulsante Commenti
                  GestureDetector(
                    onTap: () => _showCommentsDialog(dream),
                    child: Row(
                      children: [
                        const Icon(Icons.comment, color: Colors.blue, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${_dreamCommentCounts[dream.id] ?? 0}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Pulsante Preferiti
                  GestureDetector(
                    onTap: () => _toggleFavoriteFromCommunity(dream),
                    child: Icon(
                      (_userFavoriteDreams[dream.id] ?? false)
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: (_userFavoriteDreams[dream.id] ?? false)
                          ? Colors.orange
                          : Colors.grey,
                      size: 18,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _shareOtherUserDream(dream),
                    icon: const Icon(Icons.share),
                    iconSize: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyDreamCard(SavedDream dream) {
    // Match visual style from Dream History page
    final theme = Theme.of(context);

    return Card(
      // add horizontal margin so cards don't touch the screen edges
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DreamDetailPage(dream: dream),
            ),
          );
          _loadSocialData();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dream.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dream.createdAt.day}/${dream.createdAt.month}/${dream.createdAt.year}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (dream.isSharedWithCommunity) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'en'
                            ? 'Shared'
                            : 'Condiviso',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Image if present
              if ((dream.localImagePath?.isNotEmpty ?? false) ||
                  (dream.imageUrl?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth.isFinite
                          ? constraints.maxWidth
                          : MediaQuery.of(context).size.width;
                      final mq = MediaQuery.of(context);
                      final isSmallPhone = mq.size.width <= 360;
                      final maxHeight = isSmallPhone
                          ? (maxWidth * 0.6).clamp(140.0, 360.0)
                          : (maxWidth * 0.6);
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: double.infinity,
                          maxHeight: maxHeight,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: maxHeight,
                          child:
                              dream.localImagePath != null &&
                                  dream.localImagePath!.isNotEmpty
                              ? Image.file(
                                  File(dream.localImagePath!),
                                  fit: MediaQuery.of(context).size.width <= 360
                                      ? BoxFit.contain
                                      : BoxFit.cover,
                                  width: double.infinity,
                                  height: maxHeight,
                                )
                              : dream.imageUrl != null &&
                                    dream.imageUrl!.isNotEmpty
                              ? Image.network(
                                  dream.imageUrl!,
                                  fit: MediaQuery.of(context).size.width <= 360
                                      ? BoxFit.contain
                                      : BoxFit.cover,
                                  width: double.infinity,
                                  height: maxHeight,
                                )
                              : const SizedBox.shrink(),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Tags
              if (dream.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: dream.tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          labelStyle: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],

              const SizedBox(height: 12),

              // Interpretation (if present)
              if (dream.interpretation.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.interpretationTitle,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dream.interpretation.length > 100
                            ? '${dream.interpretation.substring(0, 100)}...'
                            : dream.interpretation,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer
                              .withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Actions
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => dream.isSharedWithCommunity
                        ? _showUnshareDreamDialog(dream)
                        : _showShareDreamDialog(dream),
                    icon: Icon(
                      dream.isSharedWithCommunity
                          ? Icons.remove_circle
                          : Icons.share,
                      size: 16,
                    ),
                    label: Text(
                      dream.isSharedWithCommunity
                          ? AppLocalizations.of(context)!.unshare
                          : AppLocalizations.of(context)!.share,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dream.isSharedWithCommunity
                          ? Colors.green.withOpacity(0.2)
                          : null,
                    ),
                  ),
                  // edit button removed as it's not needed
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareDreamDialog([SavedDream? dream]) {
    debugPrint('Debug: _showShareDreamDialog chiamata con dream: ${dream?.id}');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            Localizations.localeOf(context).languageCode == 'en'
                ? 'Share Dream'
                : 'Condividi Sogno',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dream != null) ...[
                Text(
                  AppLocalizations.of(
                    context,
                  )!.confirmShareMessage.replaceAll('{title}', dream.title),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Text(AppLocalizations.of(context)!.sharedDreamsVisibleInfo),
                const SizedBox(height: 16),
              ],
              Text(
                AppLocalizations.of(context)!.sharedDreamsVisibleInfo,
                style: const TextStyle(fontSize: 12),
              ),
            ],
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
            if (dream != null)
              ElevatedButton(
                onPressed: () {
                  _shareDreamWithCommunity(dream);
                  Navigator.of(context).pop();
                },
                child: Text(
                  Localizations.localeOf(context).languageCode == 'en'
                      ? 'Share'
                      : 'Condividi',
                ),
              ),
          ],
        );
      },
    );
  }

  void _showUnshareDreamDialog(SavedDream dream) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            Localizations.localeOf(context).languageCode == 'en'
                ? 'Unshare Dream'
                : 'Rimuovi Condivisione',
          ),
          content: Text(
            AppLocalizations.of(
              context,
            )!.confirmUnshareMessage.replaceAll('{title}', dream.title),
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
              onPressed: () {
                _unshareDreamFromCommunity(dream);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.2),
              ),
              child: Text(
                Localizations.localeOf(context).languageCode == 'en'
                    ? 'Remove'
                    : 'Rimuovi',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareDreamWithCommunity(SavedDream dream) async {
    try {
      debugPrint('Debug: Condivisione sogno ${dream.title}');

      // Usa il metodo specifico per aggiornare solo lo stato di condivisione
      await _dreamStorage.updateDreamSharingStatus(dream.id, true);

      // Crea la versione aggiornata del sogno per l'UI
      final updatedDream = SavedDream(
        id: dream.id,
        title: dream.title,
        dreamText: dream.dreamText,
        interpretation: dream.interpretation,
        createdAt: dream.createdAt,
        imageUrl: dream.imageUrl,
        localImagePath: dream.localImagePath,
        tags: dream.tags,
        isSharedWithCommunity: true,
      );

      setState(() {
        // Aggiorna il sogno nella lista dei sogni utente
        final userIndex = _userDreams.indexWhere((d) => d.id == dream.id);
        if (userIndex != -1) {
          _userDreams[userIndex] = updatedDream;
        }

        // Aggiungi alla community solo se non è già presente
        final communityIndex = _communityDreams.indexWhere(
          (d) => d.id == dream.id,
        );
        if (communityIndex == -1) {
          _communityDreams.add(updatedDream);
          debugPrint('Debug: Sogno ${dream.title} aggiunto alla community');
        } else {
          _communityDreams[communityIndex] = updatedDream;
          debugPrint('Debug: Sogno ${dream.title} aggiornato nella community');
        }

        // Riapplica i filtri per aggiornare la lista visualizzata
        _filterDreams(_searchController.text);
      });

      if (mounted) {
        // Success feedback suppressed per UX request (no banner on share)
      }
    } catch (e) {
      debugPrint('Errore condivisione sogno: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'en'
                  ? 'Error sharing dream'
                  : 'Errore nella condivisione del sogno',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _unshareDreamFromCommunity(SavedDream dream) async {
    try {
      debugPrint('Debug: Rimozione condivisione sogno ${dream.title}');

      // Usa il metodo specifico per aggiornare solo lo stato di condivisione
      await _dreamStorage.updateDreamSharingStatus(dream.id, false);

      // Crea la versione aggiornata del sogno per l'UI
      final updatedDream = SavedDream(
        id: dream.id,
        title: dream.title,
        dreamText: dream.dreamText,
        interpretation: dream.interpretation,
        createdAt: dream.createdAt,
        imageUrl: dream.imageUrl,
        localImagePath: dream.localImagePath,
        tags: dream.tags,
        isSharedWithCommunity: false,
      );

      setState(() {
        // Aggiorna il sogno nella lista dei sogni utente
        final userIndex = _userDreams.indexWhere((d) => d.id == dream.id);
        if (userIndex != -1) {
          _userDreams[userIndex] = updatedDream;
          debugPrint(
            'Debug: Sogno ${dream.title} rimosso dalla condivisione nei sogni utente',
          );
        }

        // Rimuovi dalla lista dei sogni della community
        final removedCount = _communityDreams.length;
        _communityDreams.removeWhere((d) => d.id == dream.id);
        debugPrint(
          'Debug: Rimossi ${removedCount - _communityDreams.length} sogni dalla community con ID ${dream.id}',
        );

        // Riapplica i filtri per aggiornare la lista visualizzata
        _filterDreams(_searchController.text);
      });

      if (mounted) {
        // Success feedback suppressed per UX request (no banner on unshare)
      }
    } catch (e) {
      debugPrint('Errore rimozione condivisione sogno: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'en'
                  ? 'Error removing dream from community'
                  : 'Errore nella rimozione del sogno dalla community',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCommentsDialog(SavedDream dream) async {
    final TextEditingController commentController = TextEditingController();

    // Preload comments & likes
    try {
      final comments = await _socialService.getDreamComments(dream.id);
      await _loadCommentLikesData(comments);
      setState(() {
        // trigger UI update after loading comment likes
      });
    } catch (e) {
      debugPrint('Errore caricamento dati commenti: $e');
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        // Remove the bottom view inset so the keyboard overlays the sheet.
        // We manage input placement below using padding and a FractionallySizedBox.
        final double originalBottomInset = MediaQuery.of(
          context,
        ).viewInsets.bottom;

        return MediaQuery.removeViewInsets(
          context: context,
          removeBottom: true,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: originalBottomInset > 0 ? originalBottomInset : 6,
            ),
            child: FractionallySizedBox(
              heightFactor: 0.8,
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              Localizations.localeOf(context).languageCode ==
                                      'en'
                                  ? 'Comments'
                                  : 'Commenti',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Comments list
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _socialService.getDreamComments(dream.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                Localizations.localeOf(context).languageCode ==
                                        'en'
                                    ? 'Error loading comments'
                                    : 'Errore caricamento commenti',
                              ),
                            );
                          }

                          final comments = snapshot.data ?? [];
                          if (comments.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                Localizations.localeOf(context).languageCode ==
                                        'en'
                                    ? 'No comments yet. Be the first to comment!'
                                    : 'Nessun commento ancora. Sii il primo a commentare!',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              return GestureDetector(
                                onLongPress: comment['author'] == 'Tu'
                                    ? () => _showCommentContextMenu(
                                        context,
                                        dream,
                                        comment,
                                      )
                                    : null,
                                child: Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 12,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.1),
                                              child: Text(
                                                (comment['author'] ?? 'A')[0],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                comment['author'] ??
                                                    (Localizations.localeOf(
                                                              context,
                                                            ).languageCode ==
                                                            'en'
                                                        ? 'Anonymous'
                                                        : 'Anonimo'),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              _formatCommentDate(
                                                comment['timestamp'],
                                              ),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          comment['content'] ?? '',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () => _toggleCommentLike(
                                                comment['id'],
                                                dream,
                                                (fn) => fn(),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    (_userLikedComments[comment['id']] ??
                                                            false)
                                                        ? Icons.favorite
                                                        : Icons.favorite_border,
                                                    size: 14,
                                                    color:
                                                        (_userLikedComments[comment['id']] ??
                                                            false)
                                                        ? Colors.red
                                                        : Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${_commentLikeCounts[comment['id']] ?? 0}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const Divider(height: 1),

                    // Input: remains above the keyboard via AnimatedPadding
                    AnimatedPadding(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentController,
                              decoration: InputDecoration(
                                hintText:
                                    Localizations.localeOf(
                                          context,
                                        ).languageCode ==
                                        'en'
                                    ? 'Write a comment...'
                                    : 'Scrivi un commento...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              maxLines: null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              if (commentController.text.trim().isNotEmpty) {
                                _addComment(
                                  dream,
                                  commentController.text.trim(),
                                );
                                commentController.clear();
                              }
                            },
                            icon: const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _addComment(SavedDream dream, String commentText) async {
    try {
      await _socialService.addComment(dream.id, 'Tu', commentText);

      // Aggiorna il conteggio dei commenti e incrementa il counter
      final comments = await _socialService.getDreamComments(dream.id);
      setState(() {
        _dreamCommentCounts[dream.id] = comments.length;
      });

      // Carica i dati dei like per i commenti aggiornati
      await _loadCommentLikesData(comments);

      // Success feedback suppressed per UX request (no banner on add comment)
      Navigator.of(context).pop();
      _showCommentsDialog(dream);
    } catch (e) {
      debugPrint('Errore aggiunta commento: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'en'
                ? 'Error adding comment'
                : 'Errore nell\'aggiungere il commento',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeDuplicatesFromCommunity() {
    // Rimuove eventuali duplicati basandosi sull'ID del sogno
    final Map<String, SavedDream> uniqueDreams = {};
    for (final dream in _communityDreams) {
      uniqueDreams[dream.id] = dream;
    }
    _communityDreams = uniqueDreams.values.toList();
    debugPrint(
      'Debug: Community dreams dopo rimozione duplicati: ${_communityDreams.length}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          Localizations.localeOf(context).languageCode == 'en'
              ? 'Community'
              : 'Community',
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: Localizations.localeOf(context).languageCode == 'en'
                  ? 'Explore'
                  : 'Esplora',
              icon: const Icon(Icons.explore),
            ),
            Tab(
              text: Localizations.localeOf(context).languageCode == 'en'
                  ? 'My Dreams'
                  : 'I Miei Sogni',
              icon: const Icon(Icons.person),
            ),
            Tab(
              text: Localizations.localeOf(context).languageCode == 'en'
                  ? 'Favorites'
                  : 'Preferiti',
              icon: const Icon(Icons.favorite),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab Esplora
          Column(
            children: [
              _buildWelcomeWidget(),
              _buildSearchAndFilters(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredDreams.isEmpty
                    ? const Center(child: Text('Nessun sogno trovato'))
                    : ListView.builder(
                        itemCount: _filteredDreams.length,
                        itemBuilder: (context, index) {
                          return _buildDreamCard(_filteredDreams[index]);
                        },
                      ),
              ),
            ],
          ),

          // Tab I Miei Sogni
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _userDreams.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bedtime, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Non hai ancora salvato sogni',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Inizia a registrare i tuoi sogni per condividerli!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  // add top padding so the first card doesn't touch the tab title area
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
                  itemCount: _userDreams.length,
                  itemBuilder: (context, index) {
                    return _buildMyDreamCard(_userDreams[index]);
                  },
                ),

          // Tab Preferiti
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _favoriteDreams.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Nessun sogno nei preferiti',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Aggiungi sogni ai preferiti per trovarli qui!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _favoriteDreams.length,
                  itemBuilder: (context, index) {
                    return _buildDreamCard(_favoriteDreams[index]);
                  },
                ),
        ],
      ),
    );
  }

  // Metodo per condividere sogni di altri utenti tramite link
  void _shareOtherUserDream(SavedDream dream) {
    final dreamUrl = 'https://dreamvisualizer.app/dream/${dream.id}';
    final shareText = Localizations.localeOf(context).languageCode == 'en'
        ? 'Check out this interesting dream: "${dream.title}"\n\n'
              '${dream.dreamText}\n\n'
              'View on DreamVisualizer: $dreamUrl'
        : 'Guarda questo sogno interessante: "${dream.title}"\n\n'
              '${dream.dreamText}\n\n'
              'Visualizza su DreamVisualizer: $dreamUrl';

    Share.share(
      shareText,
      subject: Localizations.localeOf(context).languageCode == 'en'
          ? 'Dream shared from DreamVisualizer'
          : 'Sogno condiviso da DreamVisualizer',
    );

    // Success feedback suppressed per UX request (no banner on external share)
  }

  // Metodo per gestire i like direttamente dalla community
  void _toggleLikeFromCommunity(SavedDream dream) async {
    try {
      final result = await _socialService.toggleDreamLike(dream.id);

      setState(() {
        _userLikedDreams[dream.id] = result['isLiked'];
        _dreamLikeCounts[dream.id] = result['likeCount'];
      });

      // Success feedback suppressed per UX request (no banner on like)
    } catch (e) {
      debugPrint('Errore toggle like: $e');
    }
  }

  // Metodo per gestire i preferiti direttamente dalla community
  void _toggleFavoriteFromCommunity(SavedDream dream) async {
    try {
      final isFavorite = await _favoritesService.toggleFavorite(dream);

      setState(() {
        _userFavoriteDreams[dream.id] = isFavorite;
      });

      // Ricarica anche la lista dei preferiti
      _loadFavoriteDreams();

      // Success feedback suppressed per UX request (no banner on favorite)
    } catch (e) {
      debugPrint('Errore toggle preferiti: $e');
    }
  }

  // Metodo per gestire i like dei commenti
  void _toggleCommentLike(
    String? commentId,
    SavedDream dream, [
    StateSetter? setDialogState,
  ]) async {
    if (commentId == null) return;

    try {
      debugPrint('Debug: Toggling like for comment $commentId');
      debugPrint(
        'Debug: Current state - liked: ${_userLikedComments[commentId]}, count: ${_commentLikeCounts[commentId]}',
      );

      final result = await _socialService.toggleCommentLike(commentId);

      debugPrint(
        'Debug: Service result - isLiked: ${result['isLiked']}, likeCount: ${result['likeCount']}',
      );

      setState(() {
        _userLikedComments[commentId] = result['isLiked'];
        _commentLikeCounts[commentId] = result['likeCount'];
      });

      // Se siamo nel dialogo, aggiorna anche l'UI del dialogo
      if (setDialogState != null) {
        setDialogState(() {
          // Le mappe sono già aggiornate sopra, questo ricostruisce solo l'UI del dialogo
        });
      }

      debugPrint(
        'Debug: New state - liked: ${_userLikedComments[commentId]}, count: ${_commentLikeCounts[commentId]}',
      );

      // Success feedback suppressed per UX request (no banner on comment-like)

      // Verifica dopo un breve delay che i valori siano ancora corretti
      Future.delayed(Duration(milliseconds: 100), () {
        debugPrint(
          'Debug: Verification - liked: ${_userLikedComments[commentId]}, count: ${_commentLikeCounts[commentId]}',
        );
      });
    } catch (e) {
      debugPrint('Errore toggle like commento: $e');
    }
  }

  // Mostra il menu contestuale per i commenti dell'utente
  void _showCommentContextMenu(
    BuildContext context,
    SavedDream dream,
    Map<String, dynamic> comment,
  ) {
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
                  _editComment(dream, comment);
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
                  _deleteComment(dream, comment['id'], context);
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
  void _editComment(SavedDream dream, Map<String, dynamic> comment) {
    final TextEditingController editController = TextEditingController(
      text: comment['content'],
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
                if (newContent.isNotEmpty && newContent != comment['content']) {
                  final success = await _socialService.editComment(
                    dream.id,
                    comment['id'],
                    newContent,
                  );

                  if (success) {
                    Navigator.of(context).pop();

                    // Ricarica i commenti e i loro like
                    final comments = await _socialService.getDreamComments(
                      dream.id,
                    );
                    await _loadCommentLikesData(comments);

                    // Incrementa il counter per forzare l'aggiornamento
                    setState(() {
                      // trigger UI update after editing comment
                    });

                    // Chiudi il dialog dei commenti e riaprilo per mostrare la lista aggiornata
                    Navigator.of(context).pop();
                    _showCommentsDialog(dream);

                    // Success feedback suppressed per UX request (no banner on edit comment)
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

  // Metodo per eliminare un commento
  void _deleteComment(
    SavedDream dream,
    String commentId,
    BuildContext dialogContext,
  ) async {
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
        final success = await _socialService.deleteComment(dream.id, commentId);

        if (success) {
          // Aggiorna il conteggio dei commenti e incrementa il counter
          final comments = await _socialService.getDreamComments(dream.id);
          setState(() {
            _dreamCommentCounts[dream.id] = comments.length;
            // Rimuovi i dati del like per il commento eliminato
            _commentLikeCounts.remove(commentId);
            _userLikedComments.remove(commentId);
          });

          // Carica i dati dei like per i commenti rimanenti
          await _loadCommentLikesData(comments);

          // Chiudi il dialog dei commenti e riaprilo per mostrare la lista aggiornata
          Navigator.of(dialogContext).pop();
          _showCommentsDialog(dream);

          // Success feedback suppressed per UX request (no banner on delete comment)
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
        debugPrint('Errore eliminazione commento: $e');
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

  // Metodo per formattare la data dei commenti
  String _formatCommentDate(String? timestampString) {
    if (timestampString == null) return '';

    try {
      final timestamp = DateTime.parse(timestampString);
      final now = DateTime.now();
      final difference = now.difference(timestamp);

      if (difference.inDays > 0) {
        return '${difference.inDays}g fa';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h fa';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m fa';
      } else {
        return 'Ora';
      }
    } catch (e) {
      return '';
    }
  }
}

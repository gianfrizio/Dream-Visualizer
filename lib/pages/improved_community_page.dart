import 'package:flutter/material.dart';
import '../models/saved_dream.dart';
import '../services/dream_storage_service.dart';
import 'dream_detail_page.dart';

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

  List<SavedDream> _userDreams = [];
  List<SavedDream> _communityDreams = [];
  List<SavedDream> _favoriteDreams = [];
  List<SavedDream> _filteredDreams = [];
  bool _isLoading = true;
  String _selectedCategory = 'Tutti';
  String _sortBy = 'Più recenti';

  final List<String> _categories = [
    'Tutti',
    'Incubi',
    'Sogni lucidi',
    'Sogni ricorrenti',
    'Sogni profetici',
    'Altri',
  ];

  final List<String> _sortOptions = [
    'Più recenti',
    'Più popolari',
    'Più commentati',
    'Alfabetico',
  ];

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
      final dreams = await _dreamStorage.getSavedDreams();
      setState(() {
        _userDreams = dreams;
        _communityDreams = _generateSampleCommunityDreams();
        _favoriteDreams = []; // Per ora vuota, da implementare in futuro
        _filteredDreams = _communityDreams;
        _isLoading = false;
      });
    } catch (e) {
      print('Errore caricamento sogni: $e');
      setState(() => _isLoading = false);
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
      ),
    ];
  }

  Widget _buildWelcomeWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white.withOpacity(0.9) : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.purple.withOpacity(0.3), Colors.blue.withOpacity(0.3)]
              : [Colors.purple.withOpacity(0.1), Colors.blue.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Benvenuto nella Community',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Esplora i sogni degli altri, condividi i tuoi e scopri nuove interpretazioni!',
            style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.8)),
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
              hintText: 'Cerca sogni...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
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
                    labelText: 'Categoria',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
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
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: InputDecoration(
                    labelText: 'Ordina per',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _sortOptions.map((option) {
                    return DropdownMenuItem(value: option, child: Text(option));
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
            _selectedCategory == 'Tutti' ||
            dream.tags.any(
              (tag) =>
                  tag.toLowerCase().contains(_selectedCategory.toLowerCase()),
            );
        return matchesQuery && matchesCategory;
      }).toList();
      _sortDreams();
    });
  }

  void _sortDreams() {
    setState(() {
      switch (_sortBy) {
        case 'Più recenti':
          _filteredDreams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'Alfabetico':
          _filteredDreams.sort((a, b) => a.title.compareTo(b.title));
          break;
        default:
          // Per 'Più popolari' e 'Più commentati' manteniamo l'ordine attuale
          break;
      }
    });
  }

  Widget _buildDreamCard(SavedDream dream) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DreamDetailPage(dream: dream),
            ),
          );
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                style: const TextStyle(fontSize: 14),
              ),
              if (dream.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: dream.tags.take(3).map((tag) {
                    return Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 10)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.red, size: 16),
                      SizedBox(width: 4),
                      Text('0'),
                    ],
                  ),
                  const SizedBox(width: 16),
                  const Row(
                    children: [
                      Icon(Icons.comment, color: Colors.blue, size: 16),
                      SizedBox(width: 4),
                      Text('0'),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _showShareDreamDialog(),
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DreamDetailPage(dream: dream),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dream.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (dream.isSharedWithCommunity)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Condiviso',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                dream.dreamText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                '${dream.createdAt.day}/${dream.createdAt.month}/${dream.createdAt.year}',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showShareDreamDialog(dream),
                    icon: const Icon(Icons.share, size: 16),
                    label: Text(
                      dream.isSharedWithCommunity ? 'Condiviso' : 'Condividi',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dream.isSharedWithCommunity
                          ? Colors.green.withOpacity(0.2)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      // Logica per modificare
                    },
                    icon: const Icon(Icons.edit, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareDreamDialog([SavedDream? dream]) {
    print('Debug: _showShareDreamDialog chiamata con dream: ${dream?.id}');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Condividi Sogno'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dream != null) ...[
                Text('Vuoi condividere "${dream.title}" con la community?'),
                const SizedBox(height: 16),
              ] else ...[
                const Text(
                  'Per condividere un sogno, selezionane uno dalla lista "I Miei Sogni".',
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'I sogni condivisi saranno visibili a tutti gli utenti della community.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
            if (dream != null)
              ElevatedButton(
                onPressed: () {
                  _shareDreamWithCommunity(dream);
                  Navigator.of(context).pop();
                },
                child: const Text('Condividi'),
              ),
          ],
        );
      },
    );
  }

  Future<void> _shareDreamWithCommunity(SavedDream dream) async {
    try {
      print('Debug: Condivisione sogno ${dream.title}');

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

      await _dreamStorage.saveDream(updatedDream);

      setState(() {
        final index = _userDreams.indexWhere((d) => d.id == dream.id);
        if (index != -1) {
          _userDreams[index] = updatedDream;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sogno condiviso con successo!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Errore condivisione sogno: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore nella condivisione del sogno'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Esplora', icon: Icon(Icons.explore)),
            Tab(text: 'I Miei Sogni', icon: Icon(Icons.person)),
            Tab(text: 'Preferiti', icon: Icon(Icons.favorite)),
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
}

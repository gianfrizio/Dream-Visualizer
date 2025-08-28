import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../models/saved_dream.dart';
import '../services/dream_storage_service.dart';
import '../services/favorites_service.dart';
import '../l10n/app_localizations.dart';
import 'dream_details_page.dart';

class DreamHistoryPage extends StatefulWidget {
  const DreamHistoryPage({super.key});

  @override
  State<DreamHistoryPage> createState() => _DreamHistoryPageState();
}

class _DreamHistoryPageState extends State<DreamHistoryPage> {
  final DreamStorageService _storageService = DreamStorageService();
  final FavoritesService _favoritesService = FavoritesService();
  List<SavedDream> _dreams = [];
  List<SavedDream> _favoriteDreams = [];
  final Set<String> _favoriteIds = {};
  bool _showFavorites = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDreams();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favs = await _favoritesService.getFavoriteDreams();
      setState(() {
        _favoriteDreams = favs;
        _favoriteIds.clear();
        _favoriteIds.addAll(favs.map((d) => d.id));
      });
    } catch (e) {
      // ignore errors
    }
  }

  Future<void> _loadDreams() async {
    try {
      setState(() => _isLoading = true);
      debugPrint('Iniziando caricamento sogni...');
      final dreams = await _storageService.getSavedDreams();
      debugPrint('Sogni caricati: ${dreams.length}');
      setState(() {
        _dreams = dreams;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() => _isLoading = false);
      debugPrint('Errore dettagliato nel caricamento sogni:');
      debugPrint('Tipo errore: ${e.runtimeType}');
      debugPrint('Messaggio: $e');
      debugPrint('$stackTrace');

      if (mounted) {
        // Mostra un dialog con opzioni per gestire l'errore
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Errore nel caricamento'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.errorLoadingDreams),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Tipo: ${e.runtimeType}\nErrore: $e',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Cosa vuoi fare?'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadDreams(); // Riprova
                },
                child: const Text('Riprova'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    debugPrint('Pulizia dati corrotti...');
                    await _storageService.clearCorruptedData();
                    debugPrint('Dati puliti, ricaricamento...');
                    _loadDreams();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Dati corrotti puliti. I sogni precedenti sono stati rimossi.',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (clearError) {
                    debugPrint('Errore durante la pulizia: $clearError');
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Errore durante la pulizia: $clearError'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                child: const Text('Pulisci dati'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Bypass: carica una lista vuota
                  setState(() {
                    _dreams = [];
                    _isLoading = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Caricamento bypassato. Puoi creare nuovi sogni.',
                      ),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
                child: const Text('Salta caricamento'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _deleteDream(
    SavedDream dream,
    AppLocalizations localizations,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.deleteDream),
        content: Text(localizations.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(localizations.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.deleteDream(dream.id);
      _loadDreams();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(localizations.dreamDeleted)));
      }
    }
  }

  Future<void> _deleteAllDreams(AppLocalizations localizations) async {
    if (_dreams.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.deleteAllDreams),
        content: Text(localizations.confirmDeleteAll),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(localizations.deleteAll),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.deleteAllDreams();
      _loadDreams();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(localizations.allDreamsDeleted)));
      }
    }
  }

  Future<void> _toggleCommunitySharing(SavedDream dream) async {
    try {
      await _storageService.updateDreamSharingStatus(
        dream.id,
        !dream.isSharedWithCommunity,
      );
      _loadDreams(); // Refresh the list to show updated status

      final message = dream.isSharedWithCommunity
          ? 'Sogno rimosso dalla community'
          : 'Sogno condiviso con la community';

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Errore nell\'aggiornamento dello stato di condivisione',
            ),
          ),
        );
      }
    }
  }

  void _showDreamDetails(SavedDream dream) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => DreamDetailsPage(dream: dream)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.myDreams),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_dreams.isNotEmpty)
            IconButton(
              onPressed: () => _deleteAllDreams(localizations),
              icon: const Icon(Icons.delete_sweep),
              tooltip: localizations.deleteAll,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.light
                ? [
                    const Color(0xFFFCFCFD),
                    const Color(0xFFF7F8FC),
                    const Color(0xFFF0F4FF),
                  ]
                : [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                    const Color(0xFF334155),
                  ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ((_dreams.isEmpty && !_showFavorites) ||
                  (_favoriteDreams.isEmpty && _showFavorites))
            ? _buildEmptyState(localizations, theme)
            : Column(
                children: [
                  // Toggle between All / Favorites
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => setState(() {
                              _showFavorites = false;
                            }),
                            style: TextButton.styleFrom(
                              foregroundColor: _showFavorites
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.primary,
                            ),
                            child: Text('Tutti'),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              await _loadFavorites();
                              setState(() {
                                _showFavorites = true;
                              });
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: _showFavorites
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                            child: Text('Preferiti'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _buildDreamsList(localizations, theme)),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations localizations, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.nights_stay,
            size: 80,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.noDreamsYet,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.yourInterpretedDreamsWillAppearHere,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDreamsList(AppLocalizations localizations, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: (_showFavorites ? _favoriteDreams : _dreams).length,
      itemBuilder: (context, index) {
        final dream = (_showFavorites ? _favoriteDreams : _dreams)[index];
        return _buildDreamCard(dream, localizations, theme);
      },
    );
  }

  Widget _buildDreamCard(
    SavedDream dream,
    AppLocalizations localizations,
    ThemeData theme,
  ) {
    final dateFormatter = DateFormat('dd/MM/yyyy - HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDreamDetails(dream),
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
                          dateFormatter.format(dream.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pulsante preferito
                      IconButton(
                        onPressed: () async {
                          try {
                            final added = await _favoritesService
                                .toggleFavorite(dream);
                            await _loadFavorites();
                            if (mounted) {
                              setState(() {
                                if (added) {
                                  _favoriteIds.add(dream.id);
                                } else {
                                  _favoriteIds.remove(dream.id);
                                }
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    added
                                        ? 'Aggiunto ai preferiti'
                                        : 'Rimosso dai preferiti',
                                  ),
                                ),
                              );
                            }
                          } catch (_) {}
                        },
                        icon: Icon(
                          _favoriteIds.contains(dream.id)
                              ? Icons.star
                              : Icons.star_border,
                          color: _favoriteIds.contains(dream.id)
                              ? Colors.amber
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                        ),
                        tooltip: _favoriteIds.contains(dream.id)
                            ? 'Rimosso dai preferiti'
                            : 'Aggiungi ai preferiti',
                      ),
                      // Pulsante condivisione community
                      IconButton(
                        onPressed: () => _toggleCommunitySharing(dream),
                        icon: Icon(
                          dream.isSharedWithCommunity
                              ? Icons.people
                              : Icons.people_outline,
                          color: dream.isSharedWithCommunity
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                        ),
                        tooltip: dream.isSharedWithCommunity
                            ? 'Rimuovi dalla community'
                            : 'Condividi con la community',
                      ),
                      // Pulsante elimina
                      IconButton(
                        onPressed: () => _deleteDream(dream, localizations),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: localizations.delete,
                        iconSize: 20,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dream.dreamText.length > 150
                      ? '${dream.dreamText.substring(0, 150)}...'
                      : dream.dreamText,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (dream.interpretation.isNotEmpty) ...[
                const SizedBox(height: 12),
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
                        localizations.interpretationTitle,
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
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (dream.isSharedWithCommunity) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Condiviso con la community',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

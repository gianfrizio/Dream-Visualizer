import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/saved_dream.dart';
import '../l10n/app_localizations.dart';

class DreamDetailsPage extends StatelessWidget {
  final SavedDream dream;

  const DreamDetailsPage({super.key, required this.dream});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final dateFormatter = DateFormat('dd/MM/yyyy - HH:mm');

    return Scaffold(
      // Use a transparent container so the global animated background is visible
      body: Container(
        color: Colors.transparent,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  dream.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.8),
                        theme.colorScheme.primary.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.nights_stay,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Data e ora
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        dateFormatter.format(dream.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Testo del sogno
                    Text(
                      localizations.yourDream,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        dream.dreamText,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                      ),
                    ),

                    // Interpretazione (se presente)
                    if (dream.interpretation.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Text(
                        localizations.interpretationTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          dream.interpretation,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],

                    // Immagine (se presente)
                    if (dream.hasImage) ...[
                      const SizedBox(height: 32),
                      Text(
                        localizations.visualization,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDreamImage(theme, localizations),
                    ],

                    // Tags (se presenti)
                    if (dream.tags.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Text(
                        'Tag',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: dream.tags
                            .map(
                              (tag) => Chip(
                                label: Text(tag),
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                labelStyle: TextStyle(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],

                    // Stato di condivisione
                    if (dream.isSharedWithCommunity) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.people,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Questo sogno è condiviso con la community',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDreamImage(ThemeData theme, AppLocalizations localizations) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: _buildImageWidget(theme, localizations),
      ),
    );
  }

  Widget _buildImageWidget(ThemeData theme, AppLocalizations localizations) {
    // Prova prima l'immagine locale
    if (dream.localImagePath != null && dream.localImagePath!.isNotEmpty) {
      final file = File(dream.localImagePath!);
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : MediaQuery.of(context).size.width;
                final maxHeight = (maxWidth * 0.7).clamp(200.0, 600.0);
                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: Image.file(
                    file,
                    width: double.infinity,
                    height: maxHeight,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Se l'immagine locale fallisce, prova quella remota
                      return _buildNetworkImage(theme, localizations);
                    },
                  ),
                );
              },
            );
          } else {
            // Se il file locale non esiste, prova quello remoto
            return _buildNetworkImage(theme, localizations);
          }
        },
      );
    } else {
      // Se non c'è percorso locale, prova quello remoto
      return _buildNetworkImage(theme, localizations);
    }
  }

  Widget _buildNetworkImage(ThemeData theme, AppLocalizations localizations) {
    if (dream.imageUrl != null && dream.imageUrl!.isNotEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width;
          final maxHeight = (maxWidth * 0.7).clamp(200.0, 600.0);
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Image.network(
              dream.imageUrl!,
              width: double.infinity,
              height: maxHeight,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: maxHeight,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildImageErrorWidget(theme, localizations);
              },
            ),
          );
        },
      );
    } else {
      return _buildImageErrorWidget(theme, localizations);
    }
  }

  Widget _buildImageErrorWidget(
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Immagine non disponibile',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

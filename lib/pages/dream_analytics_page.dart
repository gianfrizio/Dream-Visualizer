import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/dream_analytics_service.dart';
import '../models/saved_dream.dart';
import '../l10n/app_localizations.dart';

class DreamAnalyticsPage extends StatefulWidget {
  const DreamAnalyticsPage({super.key});

  @override
  _DreamAnalyticsPageState createState() => _DreamAnalyticsPageState();
}

class _DreamAnalyticsPageState extends State<DreamAnalyticsPage> {
  final DreamAnalyticsService _analyticsService = DreamAnalyticsService();
  bool _isLoading = true;

  Map<String, dynamic> _generalStats = {};
  Map<String, int> _emotionAnalysis = {};
  Map<String, int> _timeAnalysis = {};
  Map<String, int> _keywordAnalysis = {};
  List<String> _patterns = [];
  List<SavedDream> _recentDreams = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalytics();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ricarica i dati quando cambiano le dipendenze (come la localizzazione)
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final localizations = AppLocalizations.of(context)!;
      final results = await Future.wait([
        _analyticsService.getGeneralStats(localizations),
        _analyticsService.getEmotionAnalysis(localizations),
        _analyticsService.getDreamsByTimeOfDay(localizations),
        _analyticsService.getKeywordAnalysis(),
        _analyticsService.findDreamPatterns(localizations),
        _analyticsService.getRecentDreams(),
      ]);

      setState(() {
        _generalStats = results[0] as Map<String, dynamic>;
        _emotionAnalysis = results[1] as Map<String, int>;
        _timeAnalysis = results[2] as Map<String, int>;
        _keywordAnalysis = results[3] as Map<String, int>;
        _patterns = results[4] as List<String>;
        _recentDreams = results[5] as List<SavedDream>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations.errorLoadingAnalytics}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.analytics),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // Transparent body so global background is visible behind analytics
      body: Container(
        color: Colors.transparent,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _generalStats['totalDreams'] == 0
            ? _buildEmptyState(localizations, theme)
            : _buildAnalyticsContent(localizations, theme),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations localizations, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withOpacity(0.1),
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            localizations.noDataAvailable,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            localizations.recordSomeDreams,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent(
    AppLocalizations localizations,
    ThemeData theme,
  ) {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Statistiche generali
          _buildGeneralStatsSection(localizations, theme),
          const SizedBox(height: 24),

          // Grafici
          if (_emotionAnalysis.isNotEmpty) ...[
            _buildEmotionAnalysisSection(localizations, theme),
            const SizedBox(height: 24),
          ],

          if (_timeAnalysis.values.any((value) => value > 0)) ...[
            _buildTimeAnalysisSection(localizations, theme),
            const SizedBox(height: 24),
          ],

          // Pattern e insights
          if (_patterns.isNotEmpty) ...[
            _buildPatternsSection(localizations, theme),
            const SizedBox(height: 24),
          ],

          // Parole chiave
          if (_keywordAnalysis.isNotEmpty) ...[
            _buildKeywordsSection(localizations, theme),
            const SizedBox(height: 24),
          ],

          // Sogni recenti
          if (_recentDreams.isNotEmpty) ...[
            _buildRecentActivitySection(localizations, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildGeneralStatsSection(
    AppLocalizations localizations,
    ThemeData theme,
  ) {
    return Card(
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.purple.shade600],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  localizations.generalStatistics,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.0,
              crossAxisSpacing: 12,
              mainAxisSpacing: 24,
              children: [
                _buildStatCardWithLabel(
                  localizations.totalDreams,
                  '${_generalStats['totalDreams']}',
                  Icons.bedtime,
                  Colors.purple,
                ),
                _buildStatCardWithLabel(
                  localizations.averageWords,
                  '${_generalStats['averageLength']}',
                  Icons.text_fields,
                  Colors.blue,
                ),
                _buildStatCardWithLabel(
                  localizations.withImages,
                  '${_generalStats['dreamsWithImagesPercentage']}%',
                  Icons.image,
                  Colors.green,
                ),
                _buildStatCardWithLabel(
                  localizations.activePeriod,
                  _generalStats['mostActivePeriod'].toString().split(' ')[0],
                  Icons.access_time,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCardWithLabel(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmotionAnalysisSection(
    AppLocalizations localizations,
    ThemeData theme,
  ) {
    final emotionColors = [
      Colors.yellow,
      Colors.red,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.green,
      Colors.teal,
    ];

    return Card(
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.pink.shade600, Colors.purple.shade600],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.mood, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  localizations.emotionAnalysis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _emotionAnalysis.entries
                      .take(8)
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        final percentage =
                            (data.value /
                            _emotionAnalysis.values.fold(0, (a, b) => a + b) *
                            100);

                        return PieChartSectionData(
                          color: emotionColors[index % emotionColors.length],
                          value: data.value.toDouble(),
                          title: '${percentage.toStringAsFixed(1)}%',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      })
                      .toList(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emotionAnalysis.entries
                  .take(8)
                  .toList()
                  .asMap()
                  .entries
                  .map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: emotionColors[index % emotionColors.length]
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color:
                                  emotionColors[index % emotionColors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${data.key} (${data.value})',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  })
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeAnalysisSection(
    AppLocalizations localizations,
    ThemeData theme,
  ) {
    return Card(
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade600, Colors.red.shade600],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.schedule,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  localizations.dreamsByTimeOfDay,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: _timeAnalysis.entries.toList().asMap().entries.map(
                    (entry) {
                      final index = entry.key;
                      final data = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: data.value.toDouble(),
                            color: Colors.orange.shade600,
                            width: 30,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    },
                  ).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final labels = _timeAnalysis.keys.toList();
                          if (value.toInt() < labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                labels[value.toInt()].split(' ')[0],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternsSection(
    AppLocalizations localizations,
    ThemeData theme,
  ) {
    return Card(
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade600, Colors.cyan.shade600],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  localizations.patternsAndInsights,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ..._patterns.map(
              (pattern) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.teal.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pattern,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeywordsSection(
    AppLocalizations localizations,
    ThemeData theme,
  ) {
    return Card(
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade600, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.tag, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  localizations.recurringKeywords,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _keywordAnalysis.entries.take(10).map((entry) {
                final opacity =
                    (entry.value / _keywordAnalysis.values.first * 0.8) + 0.2;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(opacity),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${entry.key} (${entry.value})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(
    AppLocalizations localizations,
    ThemeData theme,
  ) {
    return Card(
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade600, Colors.teal.shade600],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.timeline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.recentActivity,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_recentDreams.length} ${localizations.dreamsInLast7Days}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.trending_up,
                    color: Colors.green.shade600,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _recentDreams.length >= 5
                        ? localizations.veryActivePeriod
                        : localizations.goodActivity,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _recentDreams.length >= 5
                        ? localizations.recordingManyDreams
                        : localizations.keepRecordingDreams,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

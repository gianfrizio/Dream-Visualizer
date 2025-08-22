import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/dream_storage_service.dart';
import '../services/theme_service.dart';
import '../services/biometric_auth_service.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  final ThemeService themeService;

  const SettingsPage({super.key, required this.themeService});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final DreamStorageService _storageService = DreamStorageService();
  int _dreamsCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDreamsCount();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ricarica i dati quando cambiano le dipendenze (come la localizzazione)
    _loadDreamsCount();
  }

  Future<void> _loadDreamsCount() async {
    final count = await _storageService.getDreamsCount();
    setState(() => _dreamsCount = count);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.settings),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.light
                ? [
                    const Color(0xFFFCFCFD), // Bianco purissimo con sfumatura
                    const Color(0xFFF7F8FC), // Bianco con hint di viola
                    const Color(
                      0xFFF0F4FF,
                    ), // Bianco con tocco di blu molto tenue
                  ]
                : [
                    const Color(0xFF0F172A), // Blu scuro profondo
                    const Color(0xFF1E293B), // Blu scuro medio
                    const Color(0xFF334155), // Grigio-blu
                  ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sezione lingua
            _buildSection(
              title: localizations.language,
              children: [
                _buildSettingsTile(
                  icon: Icons.language_rounded,
                  title: localizations.changeLanguage,
                  subtitle: 'Italiano / English',
                  onTap: () => _showLanguageDialog(localizations),
                  color: const Color(0xFF6366F1),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sezione tema
            _buildSection(
              title: localizations.themeSettings,
              children: [_buildThemeSelector(localizations)],
            ),

            const SizedBox(height: 24),

            // Sezione dati
            _buildSection(
              title: localizations.dataManagement,
              children: [
                _buildSettingsTile(
                  icon: Icons.delete_sweep,
                  title: localizations.deleteAllDreamsSettings,
                  subtitle: localizations.removeAllSavedDreams,
                  onTap: () => _showDeleteAllDialog(localizations),
                  color: Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sezione Sicurezza
            _buildSection(
              title: localizations.security,
              children: [
                Consumer<BiometricAuthService>(
                  builder: (context, biometricService, child) {
                    return FutureBuilder<bool>(
                      future: biometricService.checkBiometricSupport(),
                      builder: (context, snapshot) {
                        final isSupported = snapshot.data ?? false;
                        return _buildSwitchTile(
                          icon: Icons.fingerprint,
                          title: localizations.biometricLock,
                          subtitle: localizations.biometricDescription,
                          value: biometricService.isBiometricEnabled,
                          onChanged: isSupported
                              ? (value) async {
                                  if (value) {
                                    await biometricService.enableBiometric();
                                  } else {
                                    await biometricService.disableBiometric();
                                  }
                                }
                              : null,
                        );
                      },
                    );
                  },
                ),
                _buildInfoCard(
                  icon: Icons.security,
                  title: localizations.dataEncryption,
                  description: localizations.encryptionDescription,
                  color: Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sezione app
            _buildSection(
              title: localizations.appInfo,
              children: [
                _buildSettingsTile(
                  icon: Icons.info_outline,
                  title: localizations.version,
                  subtitle: '0.1.0',
                  onTap: null,
                ),
                _buildSettingsTile(
                  icon: Icons.developer_mode,
                  title: localizations.developedBy,
                  subtitle: localizations.dreamVisualizerTeam,
                  onTap: null,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sezione AI
            _buildSection(
              title: localizations.aiFunctionality,
              children: [
                _buildInfoCard(
                  icon: Icons.psychology,
                  title: localizations.dreamInterpretationFeature,
                  description: localizations.poweredByGPT4,
                  color: Colors.green,
                ),
                _buildInfoCard(
                  icon: Icons.image,
                  title: localizations.imageGeneration,
                  description: localizations.poweredByDalle,
                  color: Colors.blue,
                ),
                _buildInfoCard(
                  icon: Icons.mic,
                  title: localizations.speechRecognition,
                  description: localizations.speechToTextIntegrated,
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? theme.colorScheme.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color ?? theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTap,
        enabled: onTap != null,
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteAllDialog(AppLocalizations localizations) async {
    if (_dreamsCount == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(localizations.noDreamsToDelete)));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.warning),
        content: Text(
          localizations.deleteAllConfirmation.replaceAll(
            '{count}',
            '$_dreamsCount',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(localizations.deleteEverything),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.deleteAllDreams();
      setState(() => _dreamsCount = 0);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(localizations.allDreamsDeleted)));
      }
    }
  }

  Widget _buildThemeSelector(AppLocalizations localizations) {
    return ListenableBuilder(
      listenable: widget.themeService,
      builder: (context, child) {
        return _buildSettingsTile(
          icon: Icons.palette,
          title: localizations.themeSettings,
          subtitle: _getThemeDisplayName(
            widget.themeService.themeMode,
            localizations,
          ),
          onTap: () => _showThemeDialog(localizations),
          color: Colors.indigo,
        );
      },
    );
  }

  String _getThemeDisplayName(ThemeMode mode, AppLocalizations localizations) {
    switch (mode) {
      case ThemeMode.system:
        return localizations.systemTheme;
      case ThemeMode.light:
        return localizations.lightTheme;
      case ThemeMode.dark:
        return localizations.darkTheme;
    }
  }

  Future<void> _showThemeDialog(AppLocalizations localizations) async {
    final ThemeMode? selectedTheme = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.selectTheme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              ThemeMode.system,
              localizations.systemTheme,
              Icons.settings_suggest,
              localizations,
            ),
            _buildThemeOption(
              ThemeMode.light,
              localizations.lightTheme,
              Icons.light_mode,
              localizations,
            ),
            _buildThemeOption(
              ThemeMode.dark,
              localizations.darkTheme,
              Icons.dark_mode,
              localizations,
            ),
          ],
        ),
      ),
    );

    if (selectedTheme != null) {
      await widget.themeService.setThemeMode(selectedTheme);
    }
  }

  Widget _buildThemeOption(
    ThemeMode mode,
    String title,
    IconData icon,
    AppLocalizations localizations,
  ) {
    final isSelected = widget.themeService.themeMode == mode;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(title),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () => Navigator.of(context).pop(mode),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool)? onChanged,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: Switch(value: value, onChanged: onChanged),
      ),
    );
  }

  void _showLanguageDialog(AppLocalizations localizations) {
    final languageService = Provider.of<LanguageService>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.languageSelection),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(
                '🇮🇹',
                'Italiano',
                'it',
                languageService.currentLanguageCode == 'it',
                languageService,
                localizations,
              ),
              const SizedBox(height: 8),
              _buildLanguageOption(
                '🇺🇸',
                'English',
                'en',
                languageService.currentLanguageCode == 'en',
                languageService,
                localizations,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.close),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption(
    String flag,
    String name,
    String code,
    bool isSelected,
    LanguageService languageService,
    AppLocalizations localizations,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Center(child: Text(flag, style: const TextStyle(fontSize: 20))),
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () async {
        if (!isSelected) {
          await languageService.changeLanguage(code);

          if (context.mounted) {
            Navigator.of(context).pop();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(localizations.languageChanged),
                          Text(
                            localizations.restartForFullEffect,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );

            // Ricarica la pagina per aggiornare la lingua
            setState(() {});
          }
        }
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/theme_service.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_page.dart';

class ProfilePage extends StatelessWidget {
  final ThemeService? themeService;

  const ProfilePage({super.key, this.themeService});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.profile),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              // Use the ThemeService provided by the app (via Provider)
              final themeSvc = Provider.of<ThemeService>(
                context,
                listen: false,
              );
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (c) => SettingsPage(themeService: themeSvc),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        // The gradient paints the page background.
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con avatar e info utente
              _buildUserHeader(theme, localizations),

              const SizedBox(height: 20),

              // Sezioni del profilo
              _buildProfileSection(
                icon: Icons.person_outline_rounded,
                title: localizations.personalInfo,
                subtitle: localizations.editNameEmailDetails,
                color: const Color(0xFF10B981),
                onTap: () {
                  _showPersonalInfoDialog(context, theme, localizations);
                },
                theme: theme,
              ),

              const SizedBox(height: 16),

              _buildProfileSection(
                icon: Icons.security_rounded,
                title: localizations.privacySecurity,
                subtitle: localizations.managePrivacySettings,
                color: const Color(0xFFF59E0B),
                onTap: () {
                  _showPrivacySettings(context, theme, localizations);
                },
                theme: theme,
              ),

              const SizedBox(height: 16),

              _buildProfileSection(
                icon: Icons.notifications_rounded,
                title: localizations.notifications,
                subtitle: localizations.manageNotificationSettings,
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  _showNotificationSettings(context, theme, localizations);
                },
                theme: theme,
              ),

              const SizedBox(height: 20),

              // About
              _buildAboutSection(theme, localizations),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader(ThemeData theme, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.dreamVisualizerUser,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  localizations.memberSince,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPersonalInfoDialog(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.personalInfo),
        content: Text(localizations.personalInfoDialog),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.ok),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettings(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.privacySecurity),
        content: Text(localizations.privacySettingsDialog),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.ok),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (c) {
        return FutureBuilder<bool>(
          future: _loadNotificationPreference(),
          builder: (context, snap) {
            final enabled = snap.data ?? false;
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.notificationSettingsTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(localizations.manageNotificationSettings),
                      ),
                      Switch(
                        value: enabled,
                        onChanged: (v) async {
                          await _saveNotificationPreference(v);
                          Navigator.of(context).pop();
                          _showNotificationSettings(
                            context,
                            theme,
                            localizations,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      final granted = await NotificationService()
                          .requestPermissions();
                      if (granted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              localizations.dreamSavedAutomatically,
                            ),
                          ),
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              localizations.notificationSettingsDialog,
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(localizations.ok),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notified_prompt_shown_v1') ?? false;
  }

  Future<void> _saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notified_prompt_shown_v1', value);
  }

  Widget _buildAboutSection(ThemeData theme, AppLocalizations localizations) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.about,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${localizations.appVersion}: 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.aboutAppDescription,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../pages/profile_page.dart';
import '../pages/dream_history_page.dart';
import '../pages/improved_community_page.dart';
import '../pages/dream_analytics_page.dart';

// Global key to locate the history button for flying-star animations.
final GlobalKey historyButtonKey = GlobalKey();

// Public constant representing the visual height of the global bottom menu.
// The real rendered menu is slightly taller than 48 due to internal
// paddings and the central pill button. Bump this value so app content
// is consistently padded above the menu and doesn't brush the system
// navigation bar on devices with different insets.
const double kGlobalBottomMenuHeight = 64.0;

class GlobalBottomMenu extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final RouteObserver<ModalRoute<void>>? routeObserver;
  const GlobalBottomMenu({
    super.key,
    required this.navigatorKey,
    this.routeObserver,
  });

  @override
  _GlobalBottomMenuState createState() => _GlobalBottomMenuState();
}

class _GlobalBottomMenuState extends State<GlobalBottomMenu> {
  int _activeIndex = 2; // default center (home)
  RouteAware? _routeAware;

  @override
  void initState() {
    super.initState();
    // initState
    final obs = widget.routeObserver;
    if (obs != null) {
      _routeAware = _RouteListener(onRouteChanged: _onRouteChanged);
      final route = ModalRoute.of(context);
      if (route != null) obs.subscribe(_routeAware!, route);
    }
  }

  @override
  void dispose() {
    if (_routeAware != null && widget.routeObserver != null) {
      widget.routeObserver!.unsubscribe(_routeAware!);
    }
    super.dispose();
  }

  void _onRouteChanged(String? routeName) {
    if (routeName == null || routeName == '/') {
      setState(() => _activeIndex = 2);
      return;
    }
    if (routeName.contains('History')) {
      setState(() => _activeIndex = 0);
      return;
    }
    if (routeName.contains('Community')) {
      setState(() => _activeIndex = 1);
      return;
    }
    if (routeName.contains('Analytics')) {
      setState(() => _activeIndex = 3);
      return;
    }
    if (routeName.contains('Profile')) {
      setState(() => _activeIndex = 4);
      return;
    }
  }

  void _navigateTo(int index) {
    setState(() => _activeIndex = index);
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
    final nav = widget.navigatorKey.currentState;
    if (nav == null) return;

    switch (index) {
      case 0:
        nav.push(MaterialPageRoute(builder: (c) => const DreamHistoryPage()));
        break;
      case 1:
        nav.push(
          MaterialPageRoute(builder: (c) => const ImprovedCommunityPage()),
        );
        break;
      case 2:
        nav.popUntil((r) => r.isFirst);
        break;
      case 3:
        nav.push(MaterialPageRoute(builder: (c) => const DreamAnalyticsPage()));
        break;
      case 4:
        nav.push(MaterialPageRoute(builder: (c) => const ProfilePage()));
        break;
    }
  }

  Widget _buildItem({
    required IconData icon,
    required String label,
    required int index,
    required Color color,
    required ThemeData theme,
    Key? buttonKey,
  }) {
    final bool active = _activeIndex == index;
    return Expanded(
      child: InkWell(
        key: buttonKey,
        onTap: () => _navigateTo(index),
        borderRadius: BorderRadius.circular(12),
        overlayColor: MaterialStateProperty.resolveWith(
          (states) => color.withOpacity(0.12),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: active ? color : color.withOpacity(0.72),
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: active ? color : color.withOpacity(0.72),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // build
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    // Center the menu inside a rounded box so it appears as a single
    // floating panel (matches the provided mock image).
    final main = Center(
      child: ConstrainedBox(
        // Allow full-width on all devices so the box touches screen edges
        constraints: const BoxConstraints(maxWidth: double.infinity),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.zero,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildItem(
                  icon: Icons.history_rounded,
                  label: localizations?.history ?? 'History',
                  index: 0,
                  color: const Color(0xFF8B5CF6),
                  theme: theme,
                  buttonKey: historyButtonKey,
                ),
                _buildItem(
                  icon: Icons.people_rounded,
                  label: localizations?.community ?? 'Community',
                  index: 1,
                  color: const Color(0xFF10B981),
                  theme: theme,
                ),

                // Central action: prominent pill button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _navigateTo(2),
                    borderRadius: BorderRadius.circular(18),
                    overlayColor: MaterialStateProperty.resolveWith(
                      (states) => Colors.white.withOpacity(0.12),
                    ),
                    child: Container(
                      width: 84,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            localizations?.sogna ?? 'Sogna',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                _buildItem(
                  icon: Icons.analytics_rounded,
                  label: localizations?.analytics ?? 'Analytics',
                  index: 3,
                  color: const Color(0xFF0EA5E9),
                  theme: theme,
                ),
                _buildItem(
                  icon: Icons.person_rounded,
                  label: localizations?.profile ?? 'Profile',
                  index: 4,
                  color: const Color(0xFFF59E0B),
                  theme: theme,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Stack(alignment: Alignment.center, children: [main]);
  }
}

class _RouteListener with RouteAware {
  final void Function(String? route) onRouteChanged;
  _RouteListener({required this.onRouteChanged});

  @override
  void didPush() => onRouteChanged(null);
  @override
  void didPopNext() => onRouteChanged(null);
  @override
  void didPushNext() => onRouteChanged(null);
  @override
  void didPop() => onRouteChanged(null);
}

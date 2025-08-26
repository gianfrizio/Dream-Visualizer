import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../pages/profile_page.dart';
import '../pages/dream_history_page.dart';
import '../pages/improved_community_page.dart';
import '../pages/dream_analytics_page.dart';

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
    print('GlobalBottomMenu: initState');
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
  }) {
    final bool active = _activeIndex == index;
    return Expanded(
      child: InkWell(
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
    print('GlobalBottomMenu: build (active=$_activeIndex)');
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    final main = SafeArea(
      child: Container(
        // Use scaffoldBackgroundColor so the menu visually merges with
        // the app's background and no seam appears between content and the menu.
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildItem(
                icon: Icons.history_rounded,
                label: localizations?.history ?? 'History',
                index: 0,
                color: const Color(0xFF8B5CF6),
                theme: theme,
              ),
              _buildItem(
                icon: Icons.people_rounded,
                label: localizations?.community ?? 'Community',
                index: 1,
                color: const Color(0xFF10B981),
                theme: theme,
              ),
              Expanded(
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _navigateTo(2),
                      borderRadius: BorderRadius.circular(16),
                      overlayColor: MaterialStateProperty.resolveWith(
                        (states) => Colors.white.withOpacity(0.12),
                      ),
                      child: Container(
                        width: 96,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF667EEA),
                              const Color(0xFF764BA2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          // No boxShadow: remove subtle dark band that appeared
                          // above the menu on some devices.
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

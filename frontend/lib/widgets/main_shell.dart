import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authProvider).usuario;
    final location = GoRouterState.of(context).matchedLocation;
    final isWide = MediaQuery.of(context).size.width >= 900;

    final navItems = [
      _NavItem('/dashboard', Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
      _NavItem('/imoveis', Icons.home_outlined, Icons.home, 'Imóveis'),
      _NavItem('/mapa', Icons.map_outlined, Icons.map, 'Mapa'),
      _NavItem('/alertas', Icons.notifications_outlined, Icons.notifications, 'Alertas'),
      _NavItem('/simulador', Icons.calculate_outlined, Icons.calculate, 'Simulador'),
    ];

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex(location, navItems),
              onDestinationSelected: (i) => context.go(navItems[i].path),
              extended: true,
              minExtendedWidth: 220,
              leading: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.gavel, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text('Leilão\nInteligente',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, height: 1.2)),
                    ]),
                  ],
                ),
              ),
              trailing: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(children: [
                  Text(usuario?.nome ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(usuario?.plano.toUpperCase() ?? '',
                      style: const TextStyle(fontSize: 11, color: AppTheme.primary)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => ref.read(authProvider.notifier).logout(),
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('Sair'),
                  ),
                ]),
              ),
              destinations: navItems
                  .map((n) => NavigationRailDestination(
                        icon: Icon(n.icon),
                        selectedIcon: Icon(n.selectedIcon),
                        label: Text(n.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Mobile: bottom nav
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(location, navItems),
        onDestinationSelected: (i) => context.go(navItems[i].path),
        destinations: navItems
            .map((n) => NavigationDestination(icon: Icon(n.icon), label: n.label))
            .toList(),
      ),
    );
  }

  int _selectedIndex(String location, List<_NavItem> items) {
    for (int i = 0; i < items.length; i++) {
      if (location.startsWith(items[i].path)) return i;
    }
    return 0;
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem(this.path, this.icon, this.selectedIcon, this.label);
}

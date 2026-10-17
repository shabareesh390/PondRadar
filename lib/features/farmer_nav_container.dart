import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/translations.dart';
import '../models/pond.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_banners.dart';
import 'alerts/alerts_screen.dart';
import 'ponds/farmer_home_screen.dart';

class FarmerNavContainer extends StatefulWidget {
  final AuthService authService;
  final FirestoreService firestoreService;
  final LanguageNotifier languageNotifier;

  const FarmerNavContainer({
    super.key,
    required this.authService,
    required this.firestoreService,
    required this.languageNotifier,
  });

  @override
  State<FarmerNavContainer> createState() => _FarmerNavContainerState();
}

class _FarmerNavContainerState extends State<FarmerNavContainer> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final lang = widget.languageNotifier.currentLanguage;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;

        return StreamBuilder<List<Pond>>(
          stream: widget.firestoreService.getPondsStream(widget.authService.userId),
          builder: (context, pondSnapshot) {
            final ponds = pondSnapshot.data ?? [];

            return StreamBuilder<bool>(
              stream: widget.firestoreService.hasSimulatedDataStream(),
              builder: (context, simSnapshot) {
                final hasSimulated = simSnapshot.data ?? false;

                final mainContent = IndexedStack(
                  index: _currentIndex,
                  children: [
                    FarmerHomeScreen(
                      userId: widget.authService.userId,
                      ponds: ponds,
                      firestoreService: widget.firestoreService,
                      languageNotifier: widget.languageNotifier,
                    ),
                    AlertsScreen(
                      ponds: ponds,
                      firestoreService: widget.firestoreService,
                      languageNotifier: widget.languageNotifier,
                    ),
                    _buildSettingsTab(context, lang),
                  ],
                );

                if (isDesktop) {
                  return Scaffold(
                    body: Column(
                      children: [
                        if (hasSimulated) SimulatedDataBanner(language: lang),
                        Expanded(
                          child: Row(
                            children: [
                              NavigationRail(
                                minWidth: 80,
                                selectedIndex: _currentIndex,
                                onDestinationSelected: (idx) =>
                                    setState(() => _currentIndex = idx),
                                labelType: NavigationRailLabelType.all,
                                leading: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: AppTokens.space16),
                                  child: Icon(
                                    Icons.water_drop_outlined,
                                    color: AppTokens.primary,
                                    size: 32,
                                  ),
                                ),
                                destinations: [
                                  NavigationRailDestination(
                                    icon: const Icon(Icons.home_outlined),
                                    selectedIcon: const Icon(Icons.home),
                                    label: Text(AppStrings.get('navHome', lang)),
                                  ),
                                  NavigationRailDestination(
                                    icon: const Icon(Icons.radar_outlined),
                                    selectedIcon: const Icon(Icons.radar),
                                    label: Text(AppStrings.get('navAlerts', lang)),
                                  ),
                                  NavigationRailDestination(
                                    icon: const Icon(Icons.settings_outlined),
                                    selectedIcon: const Icon(Icons.settings),
                                    label: Text(AppStrings.get('navSettings', lang)),
                                  ),
                                ],
                              ),
                              const VerticalDivider(width: 1),
                              Expanded(child: mainContent),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Scaffold(
                  body: Column(
                    children: [
                      if (hasSimulated) SimulatedDataBanner(language: lang),
                      Expanded(child: mainContent),
                    ],
                  ),
                  bottomNavigationBar: NavigationBar(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (idx) =>
                        setState(() => _currentIndex = idx),
                    destinations: [
                      NavigationDestination(
                        icon: const Icon(Icons.home_outlined),
                        selectedIcon: const Icon(Icons.home),
                        label: AppStrings.get('navHome', lang),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.radar_outlined),
                        selectedIcon: const Icon(Icons.radar),
                        label: AppStrings.get('navAlerts', lang),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.settings_outlined),
                        selectedIcon: const Icon(Icons.settings),
                        label: AppStrings.get('navSettings', lang),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsTab(BuildContext context, AppLanguage lang) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('navSettings', lang)),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(AppTokens.space16),
              children: [
                Card(
                  child: ListTile(
                    title: Text(
                      lang == AppLanguage.kn ? 'ಭಾಷೆ' : 'Language',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      widget.languageNotifier.isKannada ? 'ಕನ್ನಡ' : 'English',
                    ),
                    trailing: TextButton(
                      onPressed: () => widget.languageNotifier.toggleLanguage(),
                      child: Text(
                        widget.languageNotifier.isKannada ? 'Switch to English' : 'ಕನ್ನಡಕ್ಕೆ ಬದಲಿಸಿ',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.space12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.swap_horiz, color: AppTokens.primary),
                    title: Text(
                      AppStrings.get('switchRole', lang),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text('Current role: Farmer (${widget.authService.userId})'),
                    onTap: () => widget.authService.switchRole(),
                  ),
                ),
                const SizedBox(height: AppTokens.space24),
                DisclaimerText(language: lang),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

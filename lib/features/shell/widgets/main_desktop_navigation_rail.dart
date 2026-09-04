// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gscanner/core/theme/app_theme.dart';

/// Layout desktop per schermi ampi (>960px) con NavigationRail laterale.
class MainDesktopNavigationRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final GlobalKey<NavigatorState> contentNavigatorKey;
  final Widget child;

  const MainDesktopNavigationRail({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.contentNavigatorKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (contentNavigatorKey.currentState?.canPop() == true) {
            contentNavigatorKey.currentState?.maybePop();
          }
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 900),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (currentIndex != 4)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 24,
                      bottom: 24,
                      left: 24,
                      right: 12,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.cardBackground,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: context.isDarkMode ? 0.2 : 0.06,
                            ),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(23),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                          ),
                          child: NavigationRail(
                            backgroundColor: Colors.transparent,
                            groupAlignment: 0.0,
                            selectedIndex: currentIndex < 4 ? currentIndex : 0,
                            onDestinationSelected: (int index) {
                              contentNavigatorKey.currentState?.popUntil(
                                (route) => route.isFirst,
                              );
                              onDestinationSelected(index);
                            },
                            selectedLabelTextStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSecondaryContainer,
                            ),
                            unselectedLabelTextStyle: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            selectedIconTheme: IconThemeData(
                              color: colorScheme.onSecondaryContainer,
                            ),
                            unselectedIconTheme: IconThemeData(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            indicatorColor: colorScheme.secondaryContainer
                                .withValues(alpha: 0.3),
                            labelType: NavigationRailLabelType.all,
                            destinations: [
                              NavigationRailDestination(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
                                icon: const Icon(Icons.qr_code_scanner),
                                selectedIcon: const Icon(
                                  Icons.qr_code_scanner,
                                ),
                                label: Text(
                                  "common.navigation.scanner".tr(),
                                ),
                              ),
                              NavigationRailDestination(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
                                icon: const Icon(Icons.history),
                                selectedIcon: const Icon(Icons.history),
                                label: Text(
                                  "common.navigation.history".tr(),
                                ),
                              ),
                              NavigationRailDestination(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
                                icon: const Icon(
                                  Icons.report_problem_outlined,
                                ),
                                selectedIcon: const Icon(Icons.report_problem),
                                label: Text(
                                  "common.navigation.reports".tr(),
                                ),
                              ),
                              NavigationRailDestination(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
                                icon: const Icon(Icons.settings_outlined),
                                selectedIcon: const Icon(Icons.settings),
                                label: Text(
                                  "common.navigation.settings".tr(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 24,
                        bottom: 24,
                        left: 12,
                        right: 24,
                      ),
                      child: Container(
                        width: 500,
                        decoration: BoxDecoration(
                          color: context.cardBackground,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: context.isDarkMode ? 0.2 : 0.06,
                              ),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(23),
                          child: Navigator(
                            key: contentNavigatorKey,
                            pages: [
                              MaterialPage(
                                key: const ValueKey('main_scaffold_page'),
                                child: child,
                              ),
                            ],
                            onDidRemovePage: (page) {
                              return;
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

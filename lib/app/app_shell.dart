import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingo_core/app/shell_tab.dart';
import 'package:lingo_core/app/tab_navigator.dart';
import 'package:lingo_core/core/l10n/ui_strings.dart';
import 'package:lingo_core/core/theme/app_theme.dart';
import 'package:lingo_core/core/widgets/lingo_widgets.dart';
import 'package:lingo_core/features/favorites/favorites_screen.dart';
import 'package:lingo_core/features/home/home_screen.dart';
import 'package:lingo_core/features/learn/phrase_categories_screen.dart';
import 'package:lingo_core/features/learn/word_categories_screen.dart';
import 'package:lingo_core/features/settings/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const List<ShellTab> _tabs = ShellTab.values;

  late final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List<GlobalKey<NavigatorState>>.generate(
        _tabs.length,
        (int index) => GlobalKey<NavigatorState>(),
      );

  final LingoChromeVisibilityController _chrome =
      LingoChromeVisibilityController();

  final Set<int> _activated = <int>{0};
  int _index = 0;

  NavigatorState? get _currentNavigator {
    return _navigatorKeys[_index].currentState;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _chrome.startIdleClock();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chrome.setLocked(MediaQuery.of(context).accessibleNavigation);
  }

  @override
  void dispose() {
    _chrome.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    _chrome.onTabSelected();
    if (index == _index) {
      _currentNavigator?.popUntil((Route<dynamic> route) => route.isFirst);
      return;
    }
    setState(() {
      _index = index;
      _activated.add(index);
    });
  }

  void _handlePop(bool didPop, Object? result) {
    if (didPop) {
      return;
    }
    final NavigatorState? navigator = _currentNavigator;
    if (navigator != null && navigator.canPop()) {
      navigator.pop(result);
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        backgroundColor: LingoTheme.of(context).colors.canvas,
        extendBody: true,
        resizeToAvoidBottomInset: false,
        body: LingoChromeInteractionListener(
          controller: _chrome,
          child: IndexedStack(
            index: _index,
            children: <Widget>[
              for (int index = 0; index < _tabs.length; index++)
                _activated.contains(index)
                    ? TabNavigator(
                        navigatorKey: _navigatorKeys[index],
                        root: _rootFor(_tabs[index]),
                      )
                    : const SizedBox.shrink(),
            ],
          ),
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: _chrome,
          builder: (BuildContext context, Widget? child) {
            return LingoFloatingBottomNav(
              visible: _chrome.visible && !keyboardOpen,
              selectedIndex: _index,
              onSelected: _selectTab,
              destinations: <LingoNavDestination>[
                for (final ShellTab tab in _tabs)
                  LingoNavDestination(
                    glyph: tab.glyph,
                    label: UiStrings.of(context, tab.labelKey),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _rootFor(ShellTab tab) {
    return switch (tab) {
      ShellTab.home => const HomeScreen(key: HomeScreen.screenKey),
      ShellTab.words => const WordCategoriesScreen(),
      ShellTab.phrases => const PhraseCategoriesScreen(),
      ShellTab.favorites => const FavoritesScreen(),
      ShellTab.settings => const SettingsScreen(),
    };
  }
}

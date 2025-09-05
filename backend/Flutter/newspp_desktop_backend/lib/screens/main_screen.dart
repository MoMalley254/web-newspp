import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:newspp_desktop_backend/models/screens.dart';
import 'package:newspp_desktop_backend/screens/article_info.dart';
import 'package:newspp_desktop_backend/screens/homescreen.dart';
import 'package:newspp_desktop_backend/screens/new_article_screen.dart';
import 'package:newspp_desktop_backend/screens/settings_screen.dart';
import 'package:newspp_desktop_backend/screens/statistics_screen.dart';
import 'package:newspp_desktop_backend/widgets/side_menu_widget.dart';
import 'package:newspp_desktop_backend/widgets/top_bar_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late List<ScreenItem> _screens;
  int _currentScreenIndex = 0;
  late Widget
  _currentScreenWidget; // Mutable widget that changes with navigation
  Map<String, dynamic>? _currentArguments;

  @override
  void initState() {
    super.initState();

    // Initialize screens
    _screens = [
      ScreenItem(
        title: 'Dashboard',
        icon: Icons.dashboard,
        screenBuilder:
            (navigateTo, [args]) => HomeScreen(navigateTo: navigateTo),
        navigateFunc: (menu) {
          _navigateTo(menu);
        },
      ),
      ScreenItem(
        title: 'New Article',
        icon: Icons.add,
        screenBuilder:
            (navigateTo, [args]) => NewArticleScreen(navigateTo: navigateTo),
        navigateFunc: (menu) {
          _navigateTo(menu);
        },
      ),
      // ScreenItem(
      //   title: 'Statistics',
      //   icon: Icons.auto_graph,
      //   screenBuilder: (navigateTo, [args]) => StatisticsScreen(),
      //   navigateFunc: (menu) {
      //     _navigateTo(menu);
      //   },
      // ),
      ScreenItem(
        title: 'Settings',
        icon: Icons.settings,
        screenBuilder: (navigateTo, [args]) => SettingsScreen(),
        navigateFunc: _navigateTo,
      ),
      ScreenItem(
        title: 'Article',
        icon: Icons.article,
        screenBuilder: (navigateTo, [args]) {
          return ArticleInfo(
            articleInfo: _currentArguments!,
            navigateTo: _navigateTo,
          );
        },
      ),
    ];

    // Set initial screen widget
    _currentScreenWidget = _screens[_currentScreenIndex].createScreen(
      _navigateTo,
      _currentArguments,
    );
  }

  // Reusable navigation method
  void _navigateTo(String menu, [dynamic arguments]) {
    final index = _screens.indexWhere((screen) => screen.title == menu);
    if (index != -1) {
      setState(() {
        _currentScreenIndex = index;
        _currentArguments = arguments;
        // _currentScreenWidget = _screens[index].createScreen(
        //   _navigateTo,
        //   arguments,
        // );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      //   // title: Text(widget.title, style: GoogleFonts.crimsonPro()),
      // ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF232370), Color(0xFF4F0A8C)],
          ),
        ),
        child: Center(
          child: Row(
            children: [
              // Side Menu
              Container(
                width: MediaQuery.of(context).size.width * .2,
                color: const Color(0xFF1E1F25),
                child: SideMenuWidget(
                  screens: _screens,
                  onMenuSelected: (title) {
                    final screen = _screens.firstWhere(
                      (s) => s.title == title,
                      orElse: () => _screens[_currentScreenIndex],
                    );

                    // Use custom navigateFunc if available, else default
                    final navigate = screen.navigateFunc ?? _navigateTo;
                    navigate(title); // This calls setState inside
                  },
                ),
              ),

              // Main Content
              Expanded(child: mainContent(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget mainContent(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * .8,
      padding: const EdgeInsets.all(24),
      color: const Color(0xFF2F3338),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TopBarWidget(screenTitle: _screens[_currentScreenIndex].title),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: _screens[_currentScreenIndex].createScreen(_navigateTo),
            ),
          ),
        ],
      ),
    );
  }
}

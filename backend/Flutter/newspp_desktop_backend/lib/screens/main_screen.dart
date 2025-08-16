import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:newspp_desktop_backend/models/screens.dart';
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
  ScreenItem get _currentScreen => _screens[_currentScreenIndex];

  @override
  void initState() {
    super.initState();
    // Initialize screens with optional navigateFunc
    _screens = [
      ScreenItem(
        title: 'Dashboard',
        icon: Icons.dashboard,
        screenBuilder: (navigateTo) => HomeScreen(),
      ),
      ScreenItem(
        title: 'New Article',
        screenBuilder: (navigateTo) => NewArticleScreen(navigateTo: navigateTo),
        icon: Icons.add,
        navigateFunc: (menu) {
          // Custom logic before navigation (e.g., reset form, analytics, etc.)
          print('Preparing to navigate to: $menu');
          _navigateTo(menu);
        },
      ),
      ScreenItem(
        title: 'Statistics',
        screenBuilder: (navigateTo) => StatisticsScreen(),
        icon: Icons.auto_graph,
        navigateFunc: (menu) {
          // Maybe log analytics
          // await Analytics.logEvent('navigate_to_statistics');
          _navigateTo(menu);
        },
      ),
      ScreenItem(
        title: 'Settings',
        screenBuilder: (navigateTo) => SettingsScreen(),
        icon: Icons.settings,
        navigateFunc: _navigateTo,
      ),
    ];
  }

  // Reusable navigation method
  void _navigateTo(String menu) {
    final index = _screens.indexWhere((screen) => screen.title == menu);
    if (index != -1 && index != _currentScreenIndex) {
      setState(() {
        _currentScreenIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // title: Text(widget.title, style: GoogleFonts.crimsonPro()),
      ),
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
          TopBarWidget(screenTitle: _currentScreen.title),
          const SizedBox(height: 20),
          Expanded(child: Center(child: _currentScreen.createScreen(_navigateTo))),
        ],
      ),
    );
  }
}

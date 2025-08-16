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
  final List<ScreenItem> _screens = [
    ScreenItem(title: 'Dashboard', screen: HomeScreen(), icon: Icons.dashboard),
    ScreenItem(
      title: 'New Article',
      screen: NewArticleScreen(),
      icon: Icons.add,
    ),
    ScreenItem(
      title: 'Statistics',
      screen: StatisticsScreen(),
      icon: Icons.auto_graph,
    ),
    ScreenItem(
      title: 'Settings',
      screen: SettingsScreen(),
      icon: Icons.settings,
    ),
  ];

  int _currentScreenIndex = 0;
  ScreenItem get _currentScreen => _screens[_currentScreenIndex];

  @override
  void initState() {
    super.initState();
    // _currentScreen = _screens["Dashboard"];
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
                  onMenuSelected: (menu) {
                    setState(() {
                      print('New menu $menu');
                      _currentScreenIndex = _screens.indexWhere(
                        (screen) => screen.title == menu,
                      );
                    });
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
          Expanded(child: Center(child: _currentScreen.screen)),
        ],
      ),
    );
  }
}

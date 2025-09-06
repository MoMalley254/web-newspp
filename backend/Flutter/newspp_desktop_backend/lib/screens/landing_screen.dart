import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import your actual screens
import 'main_screen.dart';
import 'login_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // await prefs.clear();
    final loggedIn = prefs.getBool('loggedIn') ?? false;

    // Give time for build() to complete (optional, but safe)
    await Future.delayed(Duration.zero);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (context) => loggedIn ? const MainScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Temporary loading UI
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

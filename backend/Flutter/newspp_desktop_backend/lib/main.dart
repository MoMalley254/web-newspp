import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:newspp_desktop_backend/screens/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Newspp Backend',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF232370)),
        textTheme: GoogleFonts.cormorantGaramondTextTheme(),
      ),
      home: MainScreen(),
    );
  }
}

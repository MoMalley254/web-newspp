import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:newspp_desktop_backend/screens/main_screen.dart';
import 'package:toastification/toastification.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    windowButtonVisibility: true,
    // fullScreen: true,
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.maximize();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp(
        title: 'Newspp Backend',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF232370)),
          textTheme: GoogleFonts.cormorantGaramondTextTheme(),
        ),
        home: MainScreen(),
      ),
    );
  }
}

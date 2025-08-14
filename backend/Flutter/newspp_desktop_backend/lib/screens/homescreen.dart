import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:newspp_desktop_backend/widgets/search_bar_widget.dart';
import 'package:newspp_desktop_backend/widgets/side_menu_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: LayoutBuilder(
        builder: (context, constraints) {
          double totalWidth = constraints.maxWidth;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Left section - 60%
              Container(
                width: totalWidth * 0.6,
                color: Colors.blue,
                child: Center(child: currentArticles(context)),
              ),

              // Right section - 20%
              Container(
                width: totalWidth * 0.35,
                color: Colors.red,
                child: Center(child: articlesBeingProcessed(context)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget currentArticles(BuildContext context) {
    return Container(child: Text('Current articles'));
  }

  Widget articlesBeingProcessed(BuildContext context) {
    return Container(child: Text('Processing articles'));
  }
}

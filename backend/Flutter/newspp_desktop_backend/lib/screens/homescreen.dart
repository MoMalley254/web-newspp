import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:newspp_desktop_backend/widgets/dashboard/articles_section.dart';
import 'package:newspp_desktop_backend/widgets/search_bar_widget.dart';
import 'package:newspp_desktop_backend/widgets/side_menu_widget.dart';

class HomeScreen extends StatefulWidget {
  final Function(String) navigateTo;
  const HomeScreen({super.key, required this.navigateTo});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double totalWidth = constraints.maxWidth;
    
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Left section - 60%
            SizedBox(
              width: totalWidth * 0.9,
              // color: Colors.blue,
              child: Center(child: ArticlesSection(navigateTo: widget.navigateTo)),
            ),
    
            // Right section - 20%
            // Container(
            //   width: totalWidth * 0.35,
            //   color: Colors.red,
            //   child: Center(child: articlesBeingProcessed(context)),
            // ),
          ],
        );
      },
    );
  }
}

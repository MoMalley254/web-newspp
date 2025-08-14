import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:newspp_desktop_backend/widgets/search_bar_widget.dart';

class TopBarWidget extends StatefulWidget {
  final String screenTitle;
  const TopBarWidget({
    super.key,
    required this.screenTitle
    });

  @override
  State<TopBarWidget> createState() => _TopBarWidgetState();
}

class _TopBarWidgetState extends State<TopBarWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          widget.screenTitle,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        SearchBarWidget(onChanged: getSearchInput),
      ],
    );
  }

  void getSearchInput(String userInput) {
    print('User input = $userInput');
  }
}

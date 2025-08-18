import 'package:flutter/material.dart';

class ScreenItem {
  final String title;
  final Widget Function(Function(String menu, [dynamic args]), [dynamic arguments]) screenBuilder;
  final IconData icon;
  final void Function(String menu)? navigateFunc;

  ScreenItem({
    required this.title,
    required this.screenBuilder,
    required this.icon,
    this.navigateFunc,
  });

  /// Helper to get screen with navigation injected and optional arguments
  Widget createScreen(Function(String menu, [dynamic arguments]) navigateTo, [dynamic arguments]) {
    return screenBuilder(navigateTo, arguments);
  }
}

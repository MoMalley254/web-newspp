import 'package:flutter/material.dart';

class ScreenItem {
  final String title;
  final Widget Function(Function(String)) screenBuilder;
  final IconData icon;
  final void Function(String menu)? navigateFunc;

  ScreenItem({
    required this.title,
    required this.screenBuilder,
    required this.icon,
    this.navigateFunc,
  });

  // Helper to get screen with navigation injected
  Widget createScreen(Function(String) navigateTo) {
    return screenBuilder(navigateTo);
  }
}
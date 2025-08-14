import 'package:flutter/material.dart';

class NewArticleScreen extends StatefulWidget {
  const NewArticleScreen({super.key});

  @override
  State<NewArticleScreen> createState() => _NewArticleScreenState();
}

class _NewArticleScreenState extends State<NewArticleScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('This is a new article screen'),
    );
  }
}
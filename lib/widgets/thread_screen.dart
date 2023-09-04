import 'package:flutter/material.dart';

import '../models/comment.dart';

class ThreadScreen extends StatefulWidget {
  final Comment comment;
  const ThreadScreen({
    super.key,
    required this.comment,
  });

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

import 'package:flutter/material.dart';

import '../../core/commentable.dart';
import 'commentable_item_screen.dart';

class FutureScreen extends StatefulWidget {
  final Future<CommentableItem> item;
  const FutureScreen({super.key, required this.item});

  @override
  State<FutureScreen> createState() => _FutureScreenState();
}

class _FutureScreenState extends State<FutureScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CommentableItem>(
      future: widget.item,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return CommentableItemScreen(item: snapshot.data!);
        } else if (snapshot.hasError) {
          return Center(
            child: Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 64.0,
            ),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}

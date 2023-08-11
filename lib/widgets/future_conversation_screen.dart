import 'package:flutter/material.dart';
import 'package:lfgss_mobile/widgets/conversation_screen.dart';

import '../models/conversation.dart';

class FutureConversationScreen extends StatefulWidget {
  final Future<Conversation> conversation;
  const FutureConversationScreen({super.key, required this.conversation});

  @override
  State<FutureConversationScreen> createState() =>
      _FutureConversationScreenState();
}

class _FutureConversationScreenState extends State<FutureConversationScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Conversation>(
      future: widget.conversation,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ConversationScreen(conversation: snapshot.data!);
        } else if (snapshot.hasError) {
          return const Center(
            child: Icon(
              Icons.error_outline,
              color: Colors.red,
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

import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../api/microcosm_client.dart';
import '../constants.dart';

class NewConversation extends StatefulWidget {
  final int microcosmId;

  const NewConversation({
    super.key,
    required this.microcosmId,
  });

  @override
  State<NewConversation> createState() => _NewConversationState();
}

class _NewConversationState extends State<NewConversation> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0.0, 4.0, 4.0),
                child: TextField(
                  controller: _titleController,
                  autofocus: false,
                  maxLines: 1,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  enabled: !_sending,
                  decoration: const InputDecoration(
                    labelText: 'Title...',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0.0, 4.0, 4.0),
                child: TextField(
                  controller: _bodyController,
                  autofocus: false,
                  maxLines: 5,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  enabled: !_sending,
                  decoration: const InputDecoration(
                    labelText: 'Body...',
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            _sending ? Icons.timer : Icons.send,
          ),
          onPressed: _sending ? null : postConversation,
        )
      ],
    );
  }

  Future<void> postConversation() async {
    if (_titleController.text == "" || _bodyController.text == "") {
      return;
    }

    setState(() {
      _sending = true;
    });
    developer.log("Creating conversation...");

    try {
      var url = Uri.https(
        HOST,
        "/api/v1/conversations",
      );
      Map<String, dynamic> payload = {
        "microcosmId": widget.microcosmId,
        "title": _titleController.text,
      };

      developer.log("Posting new conversation...");
      Json comment = await MicrocosmClient().postJson(url, payload);
      developer.log("Posting new conversation: success");
      // if (_attachments.isNotEmpty) {
      //   await _linkAttachments(comment["id"], fileHashes);
      // }

      setState(() {
        _sending = false;
        _titleController.text = "";
        _bodyController.text = "";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You started a conversation!'),
          duration: TOAST_DURATION,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Navigator.of(context).pop();
    } catch (error) {
      setState(
        () {
          _sending = false;
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to create conversation'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }
}

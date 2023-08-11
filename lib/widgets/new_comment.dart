import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:developer' as developer;

import '../constants.dart';

class NewComment extends StatefulWidget {
  final int itemId;
  final String itemType;
  final String initialState;
  final int? inReplyTo;

  const NewComment({
    super.key,
    required this.itemId,
    required this.itemType,
    this.initialState = "",
    this.inReplyTo,
  });

  @override
  State<NewComment> createState() => _NewCommentState();
}

class _NewCommentState extends State<NewComment> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialState;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 0.0, 4.0, 4.0),
            child: TextField(
              controller: _controller,
              autofocus: false,
              maxLines: 5,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              enabled: !_sending,
              decoration: const InputDecoration(
                labelText: 'New comment...',
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.attach_file),
          onPressed: () async {
            final ImagePicker picker = ImagePicker();
            final List<XFile> images = await picker.pickMultiImage();
          },
        ),
        IconButton(
          icon: const Icon(Icons.camera_alt),
          onPressed: () async {
            final ImagePicker picker = ImagePicker();
            // Capture a photo.
            final XFile? photo = await picker.pickImage(
              source: ImageSource.camera,
            );
          },
        ),
        IconButton(
          icon: Icon(
            _sending ? Icons.timer : Icons.send,
          ),
          onPressed: _sending ? null : postComment,
        ),
      ],
    );
  }

  void postComment() {
    if (_controller.text == "") {
      return;
    }

    setState(() {
      _sending = true;
    });
    developer.log("Sending message...");
    http
        .post(
      Uri.https(
        HOST,
        "/api/v1/comments",
      ),
      headers: <String, String>{
        'Authorization': BEARER_TOKEN,
        "Content-Type": "application/json"
      },
      body: json.encode(
        <String, dynamic>{
          "itemType": widget.itemType,
          "itemId": widget.itemId,
          "markdown": _controller.text,
          if (widget.inReplyTo != null) "inReplyTo": widget.inReplyTo
        },
      ),
    )
        .then((response) {
      developer.log("Got response: ${response.body}");
      setState(() {
        _sending = false;
        _controller.text = "";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent successfully!'),
          duration: Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Navigator.of(context).pop();
    }).onError((error, stackTrace) {
      setState(() {
        _sending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to send message'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    });
  }
}

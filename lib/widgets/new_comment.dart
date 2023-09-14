import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants.dart';
import '../services/microcosm_client.dart';
import 'attachment_thumbnail.dart';

class NewComment extends StatefulWidget {
  final int itemId;
  final String itemType;
  final String initialState;
  final int? inReplyTo;
  final Function onPostSuccess;

  const NewComment({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.onPostSuccess,
    this.initialState = "",
    this.inReplyTo,
  });

  @override
  State<NewComment> createState() => _NewCommentState();
}

class _NewCommentState extends State<NewComment> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;
  List<XFile> _attachments = [];

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
    return Column(
      children: [
        if (_attachments.isNotEmpty)
          SizedBox(
            height: 80.0,
            width: double.infinity,
            child: ListView.builder(
              itemCount: _attachments.length,
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemBuilder: (context, index) => AttachmentThumbnail(
                key: ObjectKey(_attachments[index]),
                image: _attachments[index],
                onRemoveItem: (XFile image) {
                  setState(() {
                    _attachments.remove(image);
                  });
                },
              ),
            ),
          ),
        Row(
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
                if (images.isNotEmpty) {
                  setState(() {
                    _attachments.addAll(images);
                  });
                }
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
                if (photo != null) {
                  setState(() {
                    _attachments.add(photo);
                  });
                }
              },
            ),
            IconButton(
              icon: Icon(
                _sending ? Icons.timer : Icons.send,
              ),
              onPressed: _sending ? null : _postComment,
            ),
          ],
        ),
      ],
    );
  }

  Future<Map<String, String>> _uploadAttachments() async {
    if (_attachments.isEmpty) return {};

    List<File> files = _attachments
        .map<File>(
          (attachment) => File(attachment.path),
        )
        .toList();

    var uri = Uri.https(
      HOST,
      "/api/v1/files",
    );

    List<dynamic> response = await MicrocosmClient().upload(uri, files);
    return {
      for (var file in response)
        file["fileHash"] as String: file["fileName"] as String,
    };
  }

  Future<void> _linkAttachments(
    int commentId,
    Map<String, String> fileHashes,
  ) async {
    developer.log("Linking ${fileHashes.length} attachments to $commentId");

    for (var entry in fileHashes.entries) {
      var uri = Uri.https(
        HOST,
        "/api/v1/comments/$commentId/attachments",
      );

      await MicrocosmClient().postJson(
        uri,
        {"FileHash": entry.key, "FileName": entry.value},
        followRedirects: false,
      );
    }
  }

  Future<void> _postComment() async {
    if (_controller.text == "") {
      return;
    }

    setState(() {
      _sending = true;
    });
    developer.log("Sending message...");

    try {
      Map<String, String> fileHashes = await _uploadAttachments();

      Uri url = Uri.https(
        HOST,
        "/api/v1/comments",
      );
      Map<String, dynamic> payload = {
        "itemType": widget.itemType,
        "itemId": widget.itemId,
        "markdown": _controller.text,
        if (widget.inReplyTo != null) "inReplyTo": widget.inReplyTo
      };
      developer.log("Posting new comment...");
      Json comment = await MicrocosmClient().postJson(url, payload);
      developer.log("Posting new comment: success");
      if (_attachments.isNotEmpty) {
        await _linkAttachments(comment["id"], fileHashes);
      }

      setState(() {
        _sending = false;
        _controller.text = "";
        _attachments.clear();
        widget.onPostSuccess();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent successfully!'),
          duration: TOAST_DURATION,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      setState(
        () {
          _sending = false;
        },
      );

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
    }

    // Navigator.of(context).pop();
  }
}

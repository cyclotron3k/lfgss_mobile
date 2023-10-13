import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/comment.dart';
import '../models/reply_notifier.dart';
import '../services/microcosm_client.dart';
import 'attachment_thumbnail.dart';

enum CommentableType {
  conversation,
  huddle,
  event,
}

class NewComment extends StatefulWidget {
  final int itemId;
  final CommentableType itemType;
  final String initialState;
  // final int? inReplyTo;
  final Function onPostSuccess;

  const NewComment({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.onPostSuccess,
    this.initialState = "",
    // this.inReplyTo,
  });

  @override
  State<NewComment> createState() => _NewCommentState();
}

class _NewCommentState extends State<NewComment> {
  final _controller = TextEditingController();
  final List<XFile> _attachments = [];
  Comment? _inReplyTo;
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
    _inReplyTo = context.watch<ReplyNotifier>().replyTarget;

    return Column(
      children: [
        if (_inReplyTo != null) ...[
          const Divider(thickness: 1.0, height: 0.0),
          Row(
            children: [
              const SizedBox(width: 8.0),
              const Icon(Icons.reply),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  "${_inReplyTo!.createdBy.profileName}: ${_inReplyTo!.markdown}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8.0),
              IconButton(
                icon: const Icon(Icons.close),
                visualDensity: VisualDensity.compact,
                onPressed: () => context.read<ReplyNotifier>().clear(),
              ),
            ],
          ),
        ],
        if (_attachments.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Wrap(
              runSpacing: 8.0,
              spacing: 8.0,
              children: [
                for (final attachment in _attachments)
                  AttachmentThumbnail(
                    key: ObjectKey(attachment),
                    image: attachment,
                    onRemoveItem: (XFile image) {
                      setState(() => _attachments.remove(image));
                    },
                  ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 6.0, 0.0, 6.0),
                child: TextField(
                  controller: _controller,
                  autofocus: false,
                  maxLines: 5,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  enabled: !_sending,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32.0),
                      borderSide: const BorderSide(
                        width: 0,
                        style: BorderStyle.none,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 12.0,
                    ),
                    labelText: 'New comment...',
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.attach_file),
              visualDensity: VisualDensity.compact,
              onPressed: _sending ? null : _pickMultiImage,
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt),
              visualDensity: VisualDensity.compact,
              onPressed: _sending ? null : _pickImage,
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: _sending
                  ? const SizedBox.square(
                      dimension: 18.0,
                      child: CircularProgressIndicator(),
                    )
                  : const Icon(Icons.send),
              onPressed: _sending ? null : _postComment,
            ),
          ],
        ),
      ],
    );
  }

  void _pickMultiImage() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() => _attachments.addAll(images));
    }
  }

  void _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Capture a photo.
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
    );
    if (photo != null) {
      setState(() => _attachments.add(photo));
    }
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

    List<dynamic> response = await MicrocosmClient().uploadImages(uri, files);
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

    setState(() => _sending = true);
    developer.log("Sending message...");

    try {
      Map<String, String> fileHashes = await _uploadAttachments();

      Uri url = Uri.https(
        HOST,
        "/api/v1/comments",
      );

      Map<String, dynamic> payload = {
        "itemType": widget.itemType.name,
        "itemId": widget.itemId,
        "markdown": _controller.text,
        if (_inReplyTo != null) "inReplyTo": _inReplyTo!.id,
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
        _inReplyTo = null;
        if (context.mounted) {
          context.read<ReplyNotifier>().clear();
        }
        widget.onPostSuccess();
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent successfully!'),
          duration: TOAST_DURATION,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      setState(() => _sending = false);

      if (!context.mounted) return;
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

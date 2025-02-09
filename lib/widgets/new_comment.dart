import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/comment.dart';
import '../models/comment_shuttle.dart';
import '../services/microcosm_client.dart';
import '../services/profile_aware_input_controller.dart';
import 'attachment_thumbnail.dart';
import 'profile_picker_popup.dart';

enum CommentableType {
  conversation,
  huddle,
  event,
}

class NewComment extends StatefulWidget {
  final int itemId;
  final CommentableType itemType;
  final String initialState;
  final Function onPostSuccess;

  const NewComment({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.onPostSuccess,
    this.initialState = "",
  });

  @override
  State<NewComment> createState() => _NewCommentState();
}

class _NewCommentState extends State<NewComment> {
  final _controller = ProfileAwareInputController();
  final List<XFile> _attachments = [];
  Comment? _inReplyTo;
  Comment? _editing;
  bool _sending = false;
  CommentShuttle? _commentShuttle;
  final _commentInputKey = GlobalKey();

  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialState;
    _commentShuttle = context.read<CommentShuttle?>();
    _commentShuttle?.addListener(_handleReplyUpdate);
    _controller.addListener(_handleTypingEvent);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        // _showOverlay();
      } else {
        _hideOverlay();
      }
    });
  }

  @override
  void dispose() {
    _commentShuttle?.removeListener(_handleReplyUpdate);
    _controller.removeListener(_handleTypingEvent);
    _controller.dispose();
    _hideOverlay();
    super.dispose();
  }

  OverlayEntry _createOverlay() {
    // RenderBox renderBox = context.findRenderObject() as RenderBox;

    RenderBox renderBox =
        _commentInputKey.currentContext!.findRenderObject() as RenderBox;

    return OverlayEntry(
      builder: (context) => CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.topLeft,
        followerAnchor: Alignment.bottomLeft,
        offset: const Offset(0.0, -8.0),
        child: Material(
          type: MaterialType.transparency,
          elevation: 5.0,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32.0),
                color: Theme.of(context).colorScheme.onSecondary.withAlpha(220),
              ),
              width: renderBox.size.width,
              height: renderBox.localToGlobal(Offset.zero).dy - 100,
              child: ProfilePickerPopup(
                controller: _controller,
                onSelected: (selectedProfile) => _replaceWord(
                  selectedProfile.profileName,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _replaceWord(String profileName) {
    TextSelection ts = _controller.selection;
    int startIndex = ts.baseOffset;
    int endIndex = ts.baseOffset;
    final String text = _controller.text;
    final nonSpace = RegExp(r'[^\s]');

    if (text.isEmpty) return;
    while (startIndex > 0 && nonSpace.hasMatch(text[startIndex - 1])) {
      startIndex--;
    }
    if (startIndex >= text.length || text[startIndex] != "@") return;
    while (endIndex < text.length && nonSpace.hasMatch(text[endIndex])) {
      endIndex++;
    }
    if (startIndex == endIndex) return;
    _controller.text = text.replaceRange(
      startIndex + 1,
      endIndex,
      profileName,
    );
  }

  void _handleTypingEvent() {
    TextSelection ts = _controller.selection;

    int startIndex = ts.baseOffset;
    int endIndex = ts.baseOffset;
    final text = _controller.text;
    final nonSpace = RegExp(r'[^\s]');

    if (startIndex < 0 || startIndex != ts.extentOffset || text.isEmpty) {
      _hideOverlay();
      return;
    }

    while (startIndex > 0 && nonSpace.hasMatch(text[startIndex - 1])) {
      startIndex--;
    }

    if (startIndex >= text.length || text[startIndex] != "@") {
      _hideOverlay();
      return;
    }

    while (endIndex < text.length && nonSpace.hasMatch(text[endIndex])) {
      endIndex++;
    }

    if (startIndex == endIndex) {
      _hideOverlay();
      return;
    }

    _showOverlay();
  }

  void _showOverlay() {
    if (_overlayEntry == null) {
      OverlayState overlayState = Overlay.of(context);
      // log("showing overlay");
      _overlayEntry = _createOverlay();
      overlayState.insert(_overlayEntry!);
    } else {
      // log("overlay already showing");
    }
  }

  void _hideOverlay() {
    if (_overlayEntry != null) {
      // log("hiding overlay");
      _overlayEntry?.remove();
      _overlayEntry?.dispose();
      _overlayEntry = null;
    }
  }

  void _handleReplyUpdate() {
    if (_commentShuttle!.editTarget != null) {
      _controller.text = _commentShuttle!.editTarget!.markdown;
    } else if (_commentShuttle!.replyText != null &&
        _commentShuttle!.replyText != "") {
      _controller.text += "> ${_commentShuttle!.replyText}";
    } else {
      _controller.text = "";
    }
  }

  @override
  Widget build(BuildContext context) {
    _inReplyTo = context.watch<CommentShuttle>().replyTarget;
    _editing = context.watch<CommentShuttle>().editTarget;

    return SafeArea(
      child: Material(
        elevation: 2.0,
        child: Column(
          children: [
            if (_editing != null) ...[
              const Divider(thickness: 1.0, height: 0.0),
              Row(
                children: [
                  const SizedBox(width: 8.0),
                  const Icon(Icons.edit_note),
                  const SizedBox(width: 8.0),
                  const Expanded(
                    child: Text(
                      "Editing...",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  IconButton(
                    icon: const Icon(Icons.close),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => context.read<CommentShuttle>().clear(),
                  ),
                ],
              ),
            ],
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
                    onPressed: () => context.read<CommentShuttle>().clear(),
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
                    child: CompositedTransformTarget(
                      link: _layerLink,
                      child: TextField(
                        key: _commentInputKey,
                        focusNode: _focusNode,
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
                      : Icon(_editing == null ? Icons.send : Icons.save),
                  onPressed: _sending ? null : _postComment,
                ),
              ],
            ),
          ],
        ),
      ),
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
      API_HOST,
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
    log("Linking ${fileHashes.length} attachments to $commentId");

    for (var entry in fileHashes.entries) {
      var uri = Uri.https(
        API_HOST,
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

    try {
      Map<String, String> fileHashes = await _uploadAttachments();

      Map<String, dynamic> payload = {
        "itemType": widget.itemType.name,
        "itemId": widget.itemId,
        "markdown": _controller.text,
        if (_inReplyTo != null) "inReplyTo": _inReplyTo!.id,
      };
      log(_editing == null ? "Posting new comment..." : "Updating comment...");

      Json? comment;
      if (_editing == null) {
        Uri url = Uri.https(
          API_HOST,
          "/api/v1/comments",
        );
        comment = await MicrocosmClient().postJson(url, payload);
      } else {
        Uri url = Uri.https(
          API_HOST,
          "/api/v1/comments/${_editing!.id}",
        );
        comment = await MicrocosmClient().putJson(url, payload);
      }

      if (_attachments.isNotEmpty) {
        await _linkAttachments(comment!["id"], fileHashes);
      }

      setState(() {
        int? id = _editing?.id;
        _sending = false;
        _controller.text = "";
        _attachments.clear();
        _inReplyTo = null;
        _editing = null;
        if (context.mounted) {
          context.read<CommentShuttle>().clear();
        }
        widget.onPostSuccess(id);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent successfully!'),
          duration: TOAST_DURATION,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      setState(() => _sending = false);

      if (!mounted) return;
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
  }
}

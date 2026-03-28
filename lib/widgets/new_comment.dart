import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/comment.dart';
import '../models/comment_shuttle.dart';
import '../services/comment_draft_service.dart';
import '../services/microcosm_client.dart';
import '../services/profile_aware_input_controller.dart';
import 'attachment_thumbnail.dart';
import 'profile_picker_popup.dart';

enum CommentableType {
  conversation,
  huddle,
  event,
}

enum _CommentFormatAction {
  bold,
  italic,
  spoiler,
  quote,
  link,
  image,
  code,
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
  final Map<String, double> _uploadProgressByPath = {};
  Comment? _inReplyTo;
  Comment? _editing;
  bool _sending = false;
  CommentShuttle? _commentShuttle;
  CommentDraftService? _draftService;
  final _commentInputKey = GlobalKey();
  String? _lastDraftText;

  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  String get _draftItemType => widget.itemType.name;
  int get _draftItemId => widget.itemId;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialState;
    _commentShuttle = context.read<CommentShuttle?>();
    _draftService = context.read<CommentDraftService?>();

    // Restore draft BEFORE adding the shuttle listener so that
    // _handleReplyUpdate doesn't fire and overwrite the restored text.
    _restoreDraft();
    _lastDraftText = _controller.text;

    _commentShuttle?.addListener(_handleReplyUpdate);
    _controller.addListener(_handleTypingEvent);
    _controller.addListener(_saveDraftIfTextChanged);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        // _showOverlay();
      } else {
        _hideOverlay();
      }
    });
  }

  void _restoreDraft() {
    final draft = _draftService?.load(_draftItemType, _draftItemId);
    if (draft == null || draft.isEmpty) return;

    _controller.text = draft.text;

    if (draft.attachmentPaths.isNotEmpty) {
      _attachments.addAll(draft.attachmentPaths.map(XFile.new));
    }

    if (draft.editId != null) {
      final stub = Comment.stub(
        id: draft.editId!,
        markdown: draft.editMarkdown ?? '',
        authorName: '',
        itemType: _draftItemType,
        itemId: _draftItemId,
      );
      // setEditTarget calls notifyListeners() but our listener isn't
      // registered yet, so _handleReplyUpdate won't fire here.
      _commentShuttle?.setEditTarget(stub);
    } else if (draft.replyToId != null) {
      final stub = Comment.stub(
        id: draft.replyToId!,
        markdown: draft.replyToMarkdown ?? '',
        authorName: draft.replyToAuthor ?? '',
        itemType: _draftItemType,
        itemId: _draftItemId,
      );
      _commentShuttle?.setReplyTarget(stub);
    }
  }

  // TextEditingController fires on both text and selection changes.
  // We only want to persist when the text content itself changes, not when
  // the cursor moves or focus is lost (which would fire notifyListeners on
  // CommentDraftService and trigger spurious rebuilds across the app).
  void _saveDraftIfTextChanged() {
    if (_controller.text == _lastDraftText) return;
    _lastDraftText = _controller.text;
    _saveDraft();
  }

  void _saveDraft() {
    _lastDraftText = _controller.text;

    final replyTarget = _commentShuttle?.replyTarget;
    final editTarget = _commentShuttle?.editTarget;

    final draft = CommentDraft(
      text: _controller.text,
      attachmentPaths: _attachments.map((f) => f.path).toList(),
      replyToId: replyTarget?.id,
      replyToAuthor: replyTarget?.createdBy.profileName,
      replyToMarkdown: replyTarget?.markdown,
      editId: editTarget?.id,
      editMarkdown: editTarget?.markdown,
    );

    _draftService?.save(_draftItemType, _draftItemId, draft);
  }

  void _setAttachmentUploadProgress(
    List<XFile> attachments,
    List<int> fileLengths,
    int sentBytes,
    int totalBytes,
  ) {
    if (!mounted || totalBytes <= 0) return;

    final totalFileBytes =
        fileLengths.fold<int>(0, (sum, length) => sum + length);
    if (totalFileBytes <= 0) return;

    final uploadedFileBytes = (sentBytes / totalBytes) * totalFileBytes;
    var cumulativeBytes = 0.0;
    final nextProgress = <String, double>{};

    for (var i = 0; i < attachments.length; i++) {
      final fileLength = fileLengths[i].toDouble();
      final localProgress = fileLength <= 0
          ? 1.0
          : ((uploadedFileBytes - cumulativeBytes) / fileLength)
              .clamp(0.0, 1.0)
              .toDouble();
      nextProgress[attachments[i].path] = localProgress;
      cumulativeBytes += fileLength;
    }

    var changed = nextProgress.length != _uploadProgressByPath.length;
    if (!changed) {
      for (final entry in nextProgress.entries) {
        final existing = _uploadProgressByPath[entry.key];
        if (existing == null || (existing - entry.value).abs() >= 0.02) {
          changed = true;
          break;
        }
      }
    }

    if (!changed) return;

    setState(() {
      _uploadProgressByPath
        ..clear()
        ..addAll(nextProgress);
    });
  }

  @override
  void dispose() {
    _commentShuttle?.removeListener(_handleReplyUpdate);
    _controller.removeListener(_handleTypingEvent);
    _controller.removeListener(_saveDraftIfTextChanged);
    _controller.dispose();
    _focusNode.dispose();
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
    _saveDraft();
  }

  Widget _buildContextMenu(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    final buttonItems = [
      ...editableTextState.contextMenuButtonItems,
      _buildFormatMenuButton(
        label: 'Bold',
        action: _CommentFormatAction.bold,
      ),
      _buildFormatMenuButton(
        label: 'Italic',
        action: _CommentFormatAction.italic,
      ),
      _buildFormatMenuButton(
        label: 'URL',
        action: _CommentFormatAction.link,
      ),
      _buildFormatMenuButton(
        label: 'IMG',
        action: _CommentFormatAction.image,
      ),
      _buildFormatMenuButton(
        label: 'Spoiler',
        action: _CommentFormatAction.spoiler,
      ),
      _buildFormatMenuButton(
        label: 'Quote',
        action: _CommentFormatAction.quote,
      ),
    ];

    return AdaptiveTextSelectionToolbar(
      anchors: editableTextState.contextMenuAnchors,
      children:
          AdaptiveTextSelectionToolbar.getAdaptiveButtons(context, buttonItems)
              .toList(),
    );
  }

  ContextMenuButtonItem _buildFormatMenuButton({
    required String label,
    required _CommentFormatAction action,
  }) =>
      ContextMenuButtonItem(
        label: label,
        onPressed: () {
          ContextMenuController.removeAny();
          _applyFormatAction(action);
        },
      );

  void _applyFormatAction(_CommentFormatAction action) {
    switch (action) {
      case _CommentFormatAction.bold:
        _wrapSelection(
          prefix: '**',
          suffix: '**',
          placeholder: 'bold text',
        );
      case _CommentFormatAction.italic:
        _wrapSelection(
          prefix: '*',
          suffix: '*',
          placeholder: 'italic text',
        );
      case _CommentFormatAction.spoiler:
        _insertSpoilerTemplate();
      case _CommentFormatAction.quote:
        _prefixSelectedLines('> ');
      case _CommentFormatAction.link:
        _insertLinkTemplate();
      case _CommentFormatAction.image:
        _insertImageTemplate();
      case _CommentFormatAction.code:
        _insertCodeTemplate();
    }
  }

  void _wrapSelection({
    required String prefix,
    required String suffix,
    required String placeholder,
  }) {
    final value = _controller.value;
    final selection = _normalizedSelection(value);
    final selectedText = selection.textInside(value.text);
    final replacement = selectedText.isEmpty ? placeholder : selectedText;
    final newText = selection.textBefore(value.text) +
        prefix +
        replacement +
        suffix +
        selection.textAfter(value.text);

    final selectionStart = selection.start + prefix.length;
    final selectionEnd = selectionStart + replacement.length;

    _controller.value = value.copyWith(
      text: newText,
      selection: TextSelection(
        baseOffset: selectionStart,
        extentOffset: selectionEnd,
      ),
      composing: TextRange.empty,
    );
    _focusNode.requestFocus();
  }

  void _prefixSelectedLines(String prefix) {
    final value = _controller.value;
    final selection = _normalizedSelection(value);
    final text = value.text;
    final lineStart = text.lastIndexOf('\n', selection.start - 1) + 1;
    final lineEndIndex = text.indexOf('\n', selection.end);
    final lineEnd = lineEndIndex == -1 ? text.length : lineEndIndex;
    final target = text.substring(lineStart, lineEnd);
    final lines = target.split('\n');
    final formatted = lines.map((line) => '$prefix$line').join('\n');
    final newText = text.replaceRange(
        lineStart, lineEnd, formatted.isEmpty ? prefix : formatted);

    _controller.value = value.copyWith(
      text: newText,
      selection: TextSelection(
        baseOffset: lineStart,
        extentOffset: lineStart + formatted.length,
      ),
      composing: TextRange.empty,
    );
    _focusNode.requestFocus();
  }

  void _insertLinkTemplate() {
    final value = _controller.value;
    final selection = _normalizedSelection(value);
    final selectedText = selection.textInside(value.text);
    const defaultLabel = 'link text';
    const defaultUrl = 'https://example.com';

    late final String replacement;
    late final TextSelection nextSelection;

    if (selectedText.isEmpty) {
      replacement = '[$defaultLabel]($defaultUrl)';
      final labelStart = selection.start + 1;
      nextSelection = TextSelection(
        baseOffset: labelStart,
        extentOffset: labelStart + defaultLabel.length,
      );
    } else if (_looksLikeUrl(selectedText)) {
      replacement = '[$defaultLabel](${selectedText.trim()})';
      final labelStart = selection.start + 1;
      nextSelection = TextSelection(
        baseOffset: labelStart,
        extentOffset: labelStart + defaultLabel.length,
      );
    } else {
      replacement = '[$selectedText]($defaultUrl)';
      final urlStart = selection.start + selectedText.length + 3;
      nextSelection = TextSelection(
        baseOffset: urlStart,
        extentOffset: urlStart + defaultUrl.length,
      );
    }

    _replaceSelection(
      replacement,
      selection: nextSelection,
    );
  }

  void _insertImageTemplate() {
    final value = _controller.value;
    final selection = _normalizedSelection(value);
    final selectedText = selection.textInside(value.text);
    const defaultAltText = 'alt text';
    const defaultUrl = 'https://example.com/image.jpg';

    late final String replacement;
    late final TextSelection nextSelection;

    if (selectedText.isEmpty) {
      replacement = '![$defaultAltText]($defaultUrl)';
      final altStart = selection.start + 2;
      nextSelection = TextSelection(
        baseOffset: altStart,
        extentOffset: altStart + defaultAltText.length,
      );
    } else if (_looksLikeUrl(selectedText)) {
      replacement = '![$defaultAltText](${selectedText.trim()})';
      final altStart = selection.start + 2;
      nextSelection = TextSelection(
        baseOffset: altStart,
        extentOffset: altStart + defaultAltText.length,
      );
    } else {
      replacement = '![$selectedText]($defaultUrl)';
      final urlStart = selection.start + selectedText.length + 4;
      nextSelection = TextSelection(
        baseOffset: urlStart,
        extentOffset: urlStart + defaultUrl.length,
      );
    }

    _replaceSelection(
      replacement,
      selection: nextSelection,
    );
  }

  void _insertCodeTemplate() {
    final value = _controller.value;
    final selection = _normalizedSelection(value);
    final selectedText = selection.textInside(value.text);

    if (selectedText.contains('\n')) {
      _wrapSelection(
        prefix: '```\n',
        suffix: '\n```',
        placeholder: 'code',
      );
      return;
    }

    _wrapSelection(
      prefix: '`',
      suffix: '`',
      placeholder: 'code',
    );
  }

  void _insertSpoilerTemplate() {
    final value = _controller.value;
    final selection = _normalizedSelection(value);
    final selectedText = selection.textInside(value.text);
    const placeholder = 'spoiler text';
    final body = selectedText.isEmpty ? placeholder : selectedText;
    final replacement =
        '<details>\n<summary>Click to reveal ...</summary>\n$body\n</details>';
    final bodyStart =
        selection.start + '<details>\n<summary>Click to reveal ...</summary>\n'.length;

    _replaceSelection(
      replacement,
      selection: TextSelection(
        baseOffset: bodyStart,
        extentOffset: bodyStart + body.length,
      ),
    );
  }

  void _replaceSelection(String replacement,
      {required TextSelection selection}) {
    final value = _controller.value;
    final normalized = _normalizedSelection(value);
    final newText = normalized.textBefore(value.text) +
        replacement +
        normalized.textAfter(value.text);

    _controller.value = value.copyWith(
      text: newText,
      selection: selection,
      composing: TextRange.empty,
    );
    _focusNode.requestFocus();
  }

  TextSelection _normalizedSelection(TextEditingValue value) {
    final selection = value.selection;
    if (!selection.isValid) {
      return TextSelection.collapsed(offset: value.text.length);
    }
    final start = selection.start.clamp(0, value.text.length);
    final end = selection.end.clamp(0, value.text.length);
    return TextSelection(baseOffset: start, extentOffset: end);
  }

  bool _looksLikeUrl(String text) {
    final trimmed = text.trim();
    final uri = Uri.tryParse(trimmed);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    _inReplyTo = context.watch<CommentShuttle>().replyTarget;
    _editing = context.watch<CommentShuttle>().editTarget;

    return SafeArea(
      top: false,
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
                        uploadProgress: _uploadProgressByPath[attachment.path],
                        onRemoveItem: (XFile image) {
                          setState(() {
                            _attachments.remove(image);
                            _uploadProgressByPath.remove(image.path);
                          });
                          _saveDraft();
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
                        contextMenuBuilder: _buildContextMenu,
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
      _saveDraft();
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
      _saveDraft();
    }
  }

  Future<Map<String, String>> _uploadAttachments() async {
    if (_attachments.isEmpty) return {};

    final attachments = List<XFile>.from(_attachments);
    List<File> files = attachments
        .map<File>(
          (attachment) => File(attachment.path),
        )
        .toList();
    final fileLengths = await Future.wait(files.map((file) => file.length()));

    var uri = Uri.https(
      API_HOST,
      "/api/v1/files",
    );

    setState(() {
      _uploadProgressByPath
        ..clear()
        ..addEntries(
          attachments.map((attachment) => MapEntry(attachment.path, 0.0)),
        );
    });
    List<dynamic> response = await MicrocosmClient().uploadImages(
      uri,
      files,
      onProgress: (sentBytes, totalBytes) {
        _setAttachmentUploadProgress(
          attachments,
          fileLengths,
          sentBytes,
          totalBytes,
        );
      },
    );
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

      await _draftService?.clear(_draftItemType, _draftItemId);

      setState(() {
        int? id = _editing?.id;
        _sending = false;
        _controller.text = "";
        _attachments.clear();
        _uploadProgressByPath.clear();
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
      setState(() {
        _sending = false;
        _uploadProgressByPath.clear();
      });

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

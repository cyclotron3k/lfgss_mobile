import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../constants.dart';
import '../models/conversation.dart';
import '../models/huddle.dart';
import '../models/microcosm.dart';
import '../models/partial_profile.dart';
import '../services/microcosm_client.dart';
import 'attachment_thumbnail.dart';
import 'selectors/conversation_selector.dart';
import 'selectors/huddle_selector.dart';
import 'selectors/microcosm_selector.dart';
import 'selectors/profile_selector.dart';

enum ItemType {
  newConversation,
  conversationComment,
  newHuddle,
  huddleComment,
}

class AdaptableForm extends StatefulWidget {
  final bool showTypeSelector;
  final ItemType defaultItemType;
  final List<SharedMediaFile> initialAttachments;

  // TODO
  final int itemId = 0;
  final String itemType = 'coversation';
  final String initialState = '';
  final int? inReplyTo = 0;
  final Function onPostSuccess;

  const AdaptableForm({
    super.key,
    this.initialAttachments = const [],
    this.showTypeSelector = true,
    this.defaultItemType = ItemType.conversationComment,
    required this.onPostSuccess,
  });

  @override
  State<AdaptableForm> createState() => _AdaptableFormState();
}

class _AdaptableFormState extends State<AdaptableForm> {
  final TextEditingController _comment = TextEditingController();
  final TextEditingController _subject = TextEditingController();
  late ItemType _itemTypeSelector;

  Microcosm? _selectedMicrocosm;
  Conversation? _selectedConversation;
  Huddle? _selectedHuddle;
  Set<PartialProfile> _selectedParticipants = {};

  List<XFile> _attachments = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _itemTypeSelector = widget.defaultItemType;
    _attachments = widget.initialAttachments
        .map(
          (e) => XFile(e.path),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownMenu(
                initialSelection: _itemTypeSelector,
                inputDecorationTheme: const InputDecorationTheme(
                  filled: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                ),
                onSelected: (value) => setState(() {
                  if (value != null) {
                    _itemTypeSelector = value;
                  }
                }),
                dropdownMenuEntries: const [
                  DropdownMenuEntry(
                    value: ItemType.newConversation,
                    label: "Start a new Conversation",
                  ),
                  DropdownMenuEntry(
                    value: ItemType.conversationComment,
                    label: "Add a Comment to a Conversation",
                  ),
                  DropdownMenuEntry(
                    value: ItemType.newHuddle,
                    label: "Start a new Huddle",
                  ),
                  DropdownMenuEntry(
                    value: ItemType.huddleComment,
                    label: "Add a Comment to a Huddle",
                  ),
                ],
              ),
              IndexedStack(
                index: _itemTypeSelector.index,
                children: [
                  _newConversation(), // Start a new Conversation...
                  _appendConversation(), // Add a Comment to a Conversation...
                  _newHuddle(), // Start a new Huddle
                  _appendHuddle(), // Add comment to Huddle
                ],
              ),
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
                        controller: _comment,
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
          ),
        ),
      ),
    );
  }

  Widget _newConversation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MicrocosmSelector(
          onSelected: (m) => setState(() {
            _selectedMicrocosm = m;
          }),
        ),
        Text(_selectedMicrocosm?.title ?? "Nothing selected"),
        TextField(
          controller: _subject,
          autofocus: false,
          maxLines: 5,
          minLines: 1,
          keyboardType: TextInputType.multiline,
          // enabled: !_sending,

          decoration: const InputDecoration(
            filled: true,
            labelText: 'New conversation subject...',
          ),
        ),
      ],
    );
  }

  Widget _appendConversation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConversationSelector(
          onSelected: (c) => setState(() {
            _selectedConversation = c;
          }),
        ),
        Text(_selectedConversation?.title ?? "Nothing selected"),
      ],
    );
  }

  Widget _newHuddle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _subject,
          autofocus: false,
          maxLines: 5,
          minLines: 1,
          keyboardType: TextInputType.multiline,
          // enabled: !_sending,
          decoration: const InputDecoration(
            labelText: 'New Huddle subject...',
          ),
        ),
        const Text('Participants'),
        const SizedBox(height: 8.0),
        Wrap(
          children: [
            ..._selectedParticipants.map((participant) {
              return Padding(
                key: ValueKey(participant.id),
                padding: const EdgeInsets.only(right: 8.0),
                child: Chip(
                  avatar: CachedNetworkImage(
                    imageUrl: participant.avatar,
                    imageBuilder: (
                      context,
                      imageProvider,
                    ) =>
                        ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: Image(image: imageProvider),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.person_outline,
                    ),
                  ),
                  label: Text(participant.profileName),
                  onDeleted: () {
                    setState(() {
                      _selectedParticipants.remove(participant);
                    });
                  },
                ),
              );
            }).toList(),
            ProfileSelector(
              onSelected: (p) => setState(() {
                _selectedParticipants.add(p);
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _appendHuddle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HuddleSelector(
          onSelected: (h) => setState(() {
            _selectedHuddle = h;
          }),
        ),
        Text(_selectedHuddle?.title ?? "Nothing selected"),
      ],
    );
  }

  Future<Map<String, String>> _uploadAttachments() async {
    if (_attachments.isEmpty) return {};

    List<File> files = _attachments
        .map<File>(
          (attachment) => File(
            attachment.path,
          ),
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
    log("Linking ${fileHashes.length} attachments to $commentId");

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
    if (_comment.text == "") {
      return;
    }

    setState(() {
      _sending = true;
    });
    log("Sending message...");

    try {
      Map<String, String> fileHashes = await _uploadAttachments();

      Uri url = Uri.https(
        HOST,
        "/api/v1/comments",
      );
      Map<String, dynamic> payload = {
        "itemType": widget.itemType,
        "itemId": widget.itemId,
        "markdown": _comment.text,
        if (widget.inReplyTo != null) "inReplyTo": widget.inReplyTo
      };
      log("Posting new comment...");
      Json comment = await MicrocosmClient().postJson(url, payload);
      log("Posting new comment: success");
      if (_attachments.isNotEmpty) {
        await _linkAttachments(comment["id"], fileHashes);
      }

      setState(() {
        _sending = false;
        _comment.text = "";
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

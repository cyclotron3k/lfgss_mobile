import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../constants.dart';
import '../models/comment.dart';
import '../models/conversation.dart';
import '../models/huddle.dart';
import '../models/microcosm.dart';
import '../models/partial_profile.dart';
import '../services/microcosm_client.dart';
import 'attachment_thumbnail.dart';
import 'selectors/conversation_selector.dart';
import 'selectors/huddle_selector.dart';
import 'selectors/microcosm_selector.dart';
import 'selectors/participant_selector.dart';

enum OperationType {
  newConversation,
  conversationComment,
  newHuddle,
  huddleComment,
}

enum ItemType {
  conversation,
  event,
  huddle,
  poll,
}

class AdaptableForm extends StatefulWidget {
  final bool showTypeSelector;
  final OperationType defaultOperationType;
  final List<SharedMediaFile> initialAttachments;

  // final ItemType itemType = ItemType.conversation;
  final Function onPostSuccess;
  final int? inReplyTo;

  const AdaptableForm({
    super.key,
    this.initialAttachments = const [],
    this.showTypeSelector = true,
    this.defaultOperationType = OperationType.conversationComment,
    this.inReplyTo,
    required this.onPostSuccess,
  });

  @override
  State<AdaptableForm> createState() => _AdaptableFormState();
}

class _AdaptableFormState extends State<AdaptableForm> {
  final TextEditingController _comment = TextEditingController();
  final TextEditingController _subject = TextEditingController();
  late OperationType _itemTypeSelector;
  final _formKey = GlobalKey<FormState>();

  Microcosm? _selectedMicrocosm;
  Conversation? _selectedConversation;
  Huddle? _selectedHuddle;
  Set<PartialProfile> _selectedParticipants = {};

  List<XFile> _attachments = [];
  bool _sending = false;
  Set<int> _area = {0};
  Set<int> _type = {1};

  @override
  void initState() {
    super.initState();
    _itemTypeSelector = widget.defaultOperationType;
    _attachments = widget.initialAttachments.map((e) => XFile(e.path)).toList();
  }

  void _updateItemTypeSelector() {
    if (_area.contains(0)) {
      if (_type.contains(0)) {
        _itemTypeSelector = OperationType.newConversation;
      } else {
        _itemTypeSelector = OperationType.conversationComment;
      }
    } else {
      if (_type.contains(0)) {
        _itemTypeSelector = OperationType.newHuddle;
      } else {
        _itemTypeSelector = OperationType.huddleComment;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListView(
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Create in..."),
                ),
                SegmentedButton<int>(
                  multiSelectionEnabled: false,
                  segments: const <ButtonSegment<int>>[
                    ButtonSegment<int>(
                      value: 0,
                      label: Text('Conversations'),
                      icon: Icon(Icons.forum),
                    ),
                    ButtonSegment<int>(
                      value: 1,
                      label: Text('Huddles'),
                      icon: Icon(Icons.email),
                    ),
                  ],
                  selected: _area,
                  onSelectionChanged: (Set<int> newSelection) => setState(() {
                    _area = newSelection;
                    _updateItemTypeSelector();
                  }),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                  child: Text("Add to..."),
                ),
                SegmentedButton<int>(
                  multiSelectionEnabled: false,
                  segments: <ButtonSegment<int>>[
                    ButtonSegment<int>(
                      value: 1,
                      label: Text(
                        'Existing ${_area.contains(1) ? "Huddle" : "Conversation"}',
                      ),
                      icon: const Icon(Icons.add_comment_outlined),
                    ),
                    ButtonSegment<int>(
                      value: 0,
                      label: Text(
                        'New ${_area.contains(1) ? "Huddle" : "Conversation"}',
                      ),
                      icon: const Icon(Icons.add_comment),
                    ),
                  ],
                  selected: _type,
                  onSelectionChanged: (Set<int> newSelection) => setState(() {
                    _type = newSelection;
                    _updateItemTypeSelector();
                  }),
                ),
                const SizedBox(height: 16.0),
                switch (_itemTypeSelector) {
                  // Start a new Conversation...
                  OperationType.newConversation => _newConversation(),
                  // Add a Comment to a Conversation...
                  OperationType.conversationComment => _appendConversation(),
                  // Start a new Huddle
                  OperationType.newHuddle => _newHuddle(),
                  // Add comment to Huddle
                  OperationType.huddleComment => _appendHuddle(),
                },
                const SizedBox(height: 16.0),
                TextFormField(
                  // controller: _comment,
                  autofocus: false,
                  maxLines: 6,
                  minLines: 3,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Must have at least one character';
                    } else {
                      return null;
                    }
                  },
                  keyboardType: TextInputType.multiline,
                  enabled: !_sending,
                  spellCheckConfiguration:
                      kIsWeb ? null : const SpellCheckConfiguration(),
                  decoration: const InputDecoration(
                    labelText: 'New comment',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_attachments.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                        child: Row(
                          children: [
                            Text("Attachments (${_attachments.length})"),
                            const Text(
                              " • drag to remove",
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        runSpacing: 8.0,
                        spacing: 8.0,
                        children: [
                          for (final attachment in _attachments)
                            AttachmentThumbnail(
                              key: ObjectKey(attachment),
                              image: attachment,
                              onRemoveItem: (XFile image) {
                                setState(() {
                                  _attachments.remove(image);
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final List<XFile> images =
                            await picker.pickMultiImage();
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
                    IconButton.filled(
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
      ),
    );
  }

  Widget _newConversation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MicrocosmSelector(
          validator: (val) {
            if (val == null) {
              return 'Must select a Microcosm';
            } else {
              return null;
            }
          },
          onSelected: (m) => setState(() {
            _selectedMicrocosm = m;
          }),
        ),
        Text(_selectedMicrocosm?.title ?? "Nothing selected"),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: _subject,
          autofocus: false,
          maxLines: 4,
          minLines: 1,
          maxLength: 150,
          keyboardType: TextInputType.multiline,
          enabled: !_sending,
          validator: (val) {
            if (val == null || val.isEmpty) {
              return 'Must have at least one character';
            } else {
              return null;
            }
          },
          spellCheckConfiguration:
              kIsWeb ? null : const SpellCheckConfiguration(),
          decoration: const InputDecoration(
            // filled: false,
            border: OutlineInputBorder(),
            labelText: 'Subject',
          ),
        ),
      ],
    );
  }

  Widget _appendConversation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConversationSelector(
          validator: (val) {
            if (val == null) {
              return 'Must select a Conversation';
            } else {
              return null;
            }
          },
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
        ParticipantSelector(
          validator: (val) {
            if (val == null || val.isEmpty) {
              return "Must select at least one participant";
            } else {
              return null;
            }
          },
          onChanged: (val) => _selectedParticipants = val,
        ),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: _subject,
          autofocus: false,
          maxLines: 4,
          minLines: 1,
          maxLength: 150,
          keyboardType: TextInputType.multiline,
          enabled: !_sending,
          validator: (val) {
            if (val == null || val.isEmpty) {
              return 'Must have at least one character';
            } else {
              return null;
            }
          },
          spellCheckConfiguration:
              kIsWeb ? null : const SpellCheckConfiguration(),
          decoration: const InputDecoration(
            labelText: 'Subject',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _appendHuddle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HuddleSelector(
          validator: (val) {
            if (val == null) {
              return 'Must select a Huddle';
            } else {
              return null;
            }
          },
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

  Future<Huddle> _createHuddle() async {
    Uri url = Uri.https(
      HOST,
      "/api/v1/huddles",
    );
    Map<String, dynamic> payload = {
      "title": _subject.text,
      "is_confidential": false,
    };
    log("Posting new Huddle...");
    Json huddle = await MicrocosmClient().postJson(url, payload);
    log("Posting new Huddle: success");
    return Huddle.fromJson(json: huddle);
  }

  Future<void> _inviteParticipants() async {
    List<Map<String, int>> invitePayload = _selectedParticipants.map(
      (p) {
        return <String, int>{"id": p.id};
      },
    ).toList();

    Uri url = Uri.https(
      HOST,
      "/api/v1/huddles/${_selectedHuddle!.id}/participants",
    );

    log("Inviting participants...");
    Json _ = await MicrocosmClient().postJson(url, invitePayload);
    log("Inviting participants: success");
  }

  Future<Conversation> _createConversation() async {
    Uri url = Uri.https(
      HOST,
      "/api/v1/conversations",
    );
    Map<String, dynamic> payload = {
      "microcosmId": _selectedMicrocosm!.id,
      "title": _subject.text,
    };
    log("Posting new Conversation...");
    Json conversation = await MicrocosmClient().postJson(url, payload);
    log("Posting new Conversation: success");
    return Conversation.fromJson(json: conversation);
  }

  Future<Comment> _createComment() async {
    Uri url = Uri.https(
      HOST,
      "/api/v1/comments",
    );

    Map<String, dynamic> payload = {
      "itemType": _area.contains(0) ? "conversation" : "huddle",
      "itemId":
          _area.contains(0) ? _selectedConversation!.id : _selectedHuddle!.id,
      "markdown": _comment.text,
      if (widget.inReplyTo != null) "inReplyTo": widget.inReplyTo
    };
    log("Posting new Comment...");
    Json comment = await MicrocosmClient().postJson(url, payload);
    log("Posting new Comment: success");
    return Comment.fromJson(json: comment);
  }

  Future<void> _postComment() async {
    if (_formKey.currentState!.validate()) {
      log("Form is ok");
    } else {
      log("Form not ok");
      return;
    }

    setState(() {
      _sending = true;
    });
    log("Sending message...");

    try {
      Map<String, String> fileHashes = await _uploadAttachments();

      if (_itemTypeSelector == OperationType.newConversation) {
        _selectedConversation = await _createConversation();
      } else if (_itemTypeSelector == OperationType.newHuddle) {
        _selectedHuddle = await _createHuddle();
        await _inviteParticipants();
      }

      Comment comment = await _createComment();

      if (fileHashes.isNotEmpty) {
        await _linkAttachments(comment.id, fileHashes);
      }

      setState(() {
        _sending = false;
        _subject.text = "";
        _comment.text = "";
        _attachments.clear();
        _selectedParticipants.clear();
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
      setState(
        () {
          _sending = false;
        },
      );

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

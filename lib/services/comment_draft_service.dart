import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommentDraft {
  final String text;
  final List<String> attachmentPaths;
  final int? replyToId;
  final String? replyToAuthor;
  final String? replyToMarkdown;
  final int? editId;
  final String? editMarkdown;

  CommentDraft({
    required this.text,
    required this.attachmentPaths,
    this.replyToId,
    this.replyToAuthor,
    this.replyToMarkdown,
    this.editId,
    this.editMarkdown,
  });

  bool get isEmpty =>
      text.isEmpty &&
      attachmentPaths.isEmpty &&
      replyToId == null &&
      editId == null;

  Map<String, dynamic> toJson() => {
        'text': text,
        'attachmentPaths': attachmentPaths,
        if (replyToId != null) 'replyToId': replyToId,
        if (replyToAuthor != null) 'replyToAuthor': replyToAuthor,
        if (replyToMarkdown != null) 'replyToMarkdown': replyToMarkdown,
        if (editId != null) 'editId': editId,
        if (editMarkdown != null) 'editMarkdown': editMarkdown,
      };

  factory CommentDraft.fromJson(Map<String, dynamic> json) => CommentDraft(
        text: json['text'] as String? ?? '',
        attachmentPaths:
            List<String>.from(json['attachmentPaths'] as List? ?? []),
        replyToId: json['replyToId'] as int?,
        replyToAuthor: json['replyToAuthor'] as String?,
        replyToMarkdown: json['replyToMarkdown'] as String?,
        editId: json['editId'] as int?,
        editMarkdown: json['editMarkdown'] as String?,
      );
}

class CommentDraftService extends ChangeNotifier {
  static const String _keyPrefix = 'draft_comment_';

  final SharedPreferences _prefs;

  CommentDraftService(this._prefs);

  String _key(String itemType, int itemId) => '$_keyPrefix${itemType}_$itemId';

  bool hasDraft(String itemType, int itemId) =>
      _prefs.containsKey(_key(itemType, itemId));

  Future<void> save(String itemType, int itemId, CommentDraft draft) async {
    if (draft.isEmpty) {
      await clear(itemType, itemId);
      return;
    }
    final key = _key(itemType, itemId);
    final encoded = jsonEncode(draft.toJson());
    if (_prefs.getString(key) == encoded) return;
    await _prefs.setString(key, encoded);
    notifyListeners();
  }

  CommentDraft? load(String itemType, int itemId) {
    final raw = _prefs.getString(_key(itemType, itemId));
    if (raw == null) return null;
    try {
      return CommentDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear(String itemType, int itemId) async {
    final key = _key(itemType, itemId);
    if (!_prefs.containsKey(key)) return;
    await _prefs.remove(key);
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';

import 'comment.dart';

class CommentShuttle extends ChangeNotifier {
  Comment? _replyTo;
  Comment? _edit;
  String? _text;

  CommentShuttle([this._replyTo]);

  Comment? get replyTarget => _replyTo;
  String? get replyText => _text;
  Comment? get editTarget => _edit;

  void setReplyTarget(Comment comment, {String? text}) {
    _replyTo = comment;
    _edit = null;
    _text = text?.trim();
    notifyListeners();
  }

  void setEditTarget(Comment comment) {
    _edit = comment;
    _replyTo = null;
    notifyListeners();
  }

  void clear() {
    _replyTo = null;
    _text = null;
    _edit = null;
    notifyListeners();
  }
}

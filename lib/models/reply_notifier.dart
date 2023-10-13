import 'package:flutter/foundation.dart';

import 'comment.dart';

class ReplyNotifier extends ChangeNotifier {
  Comment? _comment;
  String? _text;

  ReplyNotifier([this._comment]);

  Comment? get replyTarget => _comment;
  String? get replyText => _text;

  void setReplyTarget(Comment comment, {String? text}) {
    _comment = comment;
    _text = text?.trim();
    notifyListeners();
  }

  void clear() {
    _comment = null;
    _text = null;
    notifyListeners();
  }
}

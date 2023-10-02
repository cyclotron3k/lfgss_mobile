import 'package:flutter/foundation.dart';

import 'comment.dart';

class ReplyNotifier extends ChangeNotifier {
  /// Internal, private state of the cart.
  Comment? _comment;

  ReplyNotifier([this._comment]);

  Comment? get replyTarget => _comment;

  void setReplyTarget(Comment comment) {
    _comment = comment;
    notifyListeners();
  }

  void clear() {
    _comment = null;
    notifyListeners();
  }
}

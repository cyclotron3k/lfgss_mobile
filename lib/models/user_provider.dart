import 'package:flutter/widgets.dart';

import 'full_profile.dart';

class UserProvider extends ChangeNotifier {
  FullProfile? _user;

  bool get hasUser => _user != null;

  FullProfile? get user => _user;

  set user(FullProfile? newUser) {
    _user = newUser;
    notifyListeners();
  }

  void clear() {
    _user = null;
    notifyListeners();
  }
}

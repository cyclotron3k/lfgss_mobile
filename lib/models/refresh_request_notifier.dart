import 'package:flutter/foundation.dart';

class RefreshRequestNotifier extends ChangeNotifier {
  RefreshRequestNotifier();

  void requestRefresh() {
    notifyListeners();
  }
}

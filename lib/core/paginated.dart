import 'package:flutter/material.dart';

import 'item.dart';

abstract class Paginated<T> {
  Future<void> loadPage(int pageId, {bool force = false});

  int get totalChildren;
  int get startPage;

  void parsePage(Json json);

  Future<T> getChild(int i);

  Widget childTile(int i);

  Future<void> resetChildren({
    bool force = false,
    int? childId,
  });
}

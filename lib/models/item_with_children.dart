import 'package:flutter/material.dart';

import 'item.dart';

abstract class ItemWithChildren implements Item {
  Future<void> getPageOfChildren(int i);

  int get totalChildren;

  Uri get selfUrl;

  Widget childTile(int i);

  Future<Item> getChild(int i);

  void parsePage(Json json);

  Future<void> resetChildren();
}

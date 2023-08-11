import 'package:flutter/material.dart';

import 'item.dart';

typedef Json = Map<String, dynamic>;

abstract class ItemWithChildren implements Item {
  Future<void> getPageOfChildren(int i);

  int get totalChildren;

  Widget childTile(int i);

  Future<Item> getChild(int i);

  void parsePage(Json json);
}

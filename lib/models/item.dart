import 'package:flutter/material.dart';

typedef Json = Map<String, dynamic>;

abstract class Item {
  Widget renderAsTile({bool? overrideUnreadFlag});
}

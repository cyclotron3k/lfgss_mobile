import 'package:flutter/material.dart';

import '../models/flags.dart';

typedef Json = Map<String, dynamic>;

abstract class Item {
  int get id;
  Flags get flags;
  Uri get selfUrl;
  Widget renderAsTile({bool? overrideUnreadFlag});
}

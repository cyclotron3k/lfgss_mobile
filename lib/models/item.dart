import 'package:flutter/material.dart';

abstract class Item {
  Item? context;

  Widget renderAsTile();
}

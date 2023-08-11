import 'package:flutter/material.dart';

import 'item.dart';

class UnknownItem implements Item {
  String type;
  Item? _context;

  UnknownItem({required this.type});

  @override
  set context(Item? tmp) {
    _context = tmp;
  }

  @override
  Item? get context => _context;

  @override
  Widget renderAsTile() {
    return Card(
      surfaceTintColor: Colors.black,
      child: ListTile(
        leading: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.grey,
        ),
        title: Text(type),
        subtitle: const Text("Not implemented yet"),
      ),
    );
  }
}

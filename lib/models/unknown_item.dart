import 'package:flutter/material.dart';

import 'item.dart';

class UnknownItem implements Item {
  String type;

  UnknownItem({required this.type});

  @override
  Widget renderAsTile({bool? overrideUnreadFlag}) {
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

import 'package:flutter/material.dart';

import '../core/item.dart';
import 'flags.dart';

class UnknownItem implements Item {
  @override
  final int id;
  String type;

  UnknownItem({required this.id, required this.type});

  @override
  Widget renderAsTile({
    bool? overrideUnreadFlag,
    bool? isReply,
    bool? mentioned,
  }) {
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

  @override
  Uri get selfUrl => throw UnimplementedError();

  @override
  Flags get flags => throw UnimplementedError();
}

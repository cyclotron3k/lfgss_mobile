import 'package:flutter/material.dart';

import '../models/update.dart';

class UpdateTile extends StatefulWidget {
  final Update update;

  const UpdateTile({
    super.key,
    required this.update,
  });

  @override
  State<UpdateTile> createState() => _UpdateTileState();
}

class _UpdateTileState extends State<UpdateTile> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          alignment: Alignment.bottomLeft,
          height: 28.0,
          padding: const EdgeInsets.only(left: 64.0),
          child: Text(
            widget.update.description,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        widget.update.parent.renderAsTile(
          overrideUnreadFlag: widget.update.flags.unread,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../models/item.dart';

class UpdateTile extends StatefulWidget {
  final Item child;
  final Item parent;
  final String description;

  const UpdateTile({
    super.key,
    required this.child,
    required this.parent,
    required this.description,
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
            widget.description,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        widget.parent.renderAsTile(),
      ],
    );
  }
}

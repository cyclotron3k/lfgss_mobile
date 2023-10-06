import 'package:flutter/material.dart';

import '../../core/item.dart';

class ItemTile extends StatefulWidget {
  final Future<Item> item;
  const ItemTile({super.key, required this.item});

  @override
  State<ItemTile> createState() => _ItemTileState();
}

class _ItemTileState extends State<ItemTile> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

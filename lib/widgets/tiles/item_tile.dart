import 'package:flutter/material.dart';

import '../../core/item.dart';

class ItemTile extends StatelessWidget {
  final Future<Item> item;
  const ItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

import 'package:flutter/material.dart';

import '../../core/item.dart';
import 'item_shimmer.dart';

class FutureItemTile extends StatelessWidget {
  final Future<Item> item;
  const FutureItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Item>(
      future: item,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return snapshot.data!.renderAsTile();
        } else if (snapshot.hasError) {
          return Center(
            child: Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 64.0,
            ),
          );
        } else {
          return const ItemShimmer();
        }
      },
    );
  }
}

import 'dart:math';

import 'package:flutter/material.dart';

class ItemShimmer extends StatelessWidget {
  const ItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final int titleSlugs = 1 + random.nextInt(2);
    final int descriptionSlugs = 6 + random.nextInt(4);

    return Card(
      child: ListTile(
        leading: Container(
          color: Colors.grey,
          width: 22.0,
          height: 22.0,
        ),
        title: Row(
          children: [
            Expanded(
              child: Wrap(
                runAlignment: WrapAlignment.start,
                runSpacing: 4.0,
                spacing: 4.0,
                children: [
                  for (int i = 0; i < titleSlugs; i++)
                    Container(
                        color: Colors.grey,
                        height: 12.0,
                        width: 16.0 + 50.0 * random.nextDouble())
                ],
              ),
            ),
          ],
        ),
        subtitle: Wrap(
          runAlignment: WrapAlignment.start,
          runSpacing: 4.0,
          spacing: 4.0,
          children: [
            for (int i = 0; i < descriptionSlugs; i++)
              Container(
                  color: Colors.grey,
                  height: 12.0,
                  width: 16.0 + 50.0 * random.nextDouble())
          ],
        ),
      ),
    );
  }
}

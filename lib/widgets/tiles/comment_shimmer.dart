import 'dart:math';

import 'package:flutter/material.dart';

class CommmentShimmer extends StatelessWidget {
  const CommmentShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final int slugs = 10 + random.nextInt(40);

    return Material(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 22.0,
                height: 22.0,
                color: Colors.grey,
              ),
            ),
            Container(
              color: Colors.grey,
              child: const Text(
                "                        ",
              ),
            ),
            const Expanded(
              child: Text(""),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  color: Colors.grey,
                  child: const Text(
                    "            ",
                  ),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            runAlignment: WrapAlignment.start,
            runSpacing: 4.0,
            spacing: 4.0,
            children: [
              for (int i = 0; i < slugs; i++)
                Container(
                    color: Colors.grey,
                    height: 12.0,
                    width: 16.0 + 50.0 * random.nextDouble())
            ],
          ),
        ),
      ],
    ));
  }
}

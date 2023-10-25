import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/microcosm.dart';

class MicrocosmLogo extends StatefulWidget {
  final Microcosm microcosm;
  const MicrocosmLogo({
    super.key,
    required this.microcosm,
  });

  @override
  State<MicrocosmLogo> createState() => _MicrocosmLogoState();
}

class _MicrocosmLogoState extends State<MicrocosmLogo> {
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    return (widget.microcosm.logoUrl.isEmpty
        ? const Icon(
            Icons.forum,
            color: Colors.grey,
          )
        : (widget.microcosm.logoUrl.endsWith('.svg')
            ? Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(6.0),
                child: ColorFiltered(
                  colorFilter: isDarkMode
                      ? const ColorFilter.matrix(<double>[
                          -1.0, 0.0, 0.0, 0.0, 255.0, //
                          0.0, -1.0, 0.0, 0.0, 255.0, //
                          0.0, 0.0, -1.0, 0.0, 255.0, //
                          0.0, 0.0, 0.0, 1.0, 0.0, //
                        ])
                      : const ColorFilter.matrix(<double>[
                          1.0, 0.0, 0.0, 0.0, 0.0, //
                          0.0, 1.0, 0.0, 0.0, 0.0, //
                          0.0, 0.0, 1.0, 0.0, 0.0, //
                          0.0, 0.0, 0.0, 1.0, 0.0, //
                        ]),
                  child: CachedNetworkImage(
                    imageUrl: widget.microcosm.logoUrl,
                    width: 28,
                    height: 28,
                    errorWidget: (context, url, error) => const Icon(
                      Icons.error_outline,
                    ),
                  ),
                ),
              )));
  }
}

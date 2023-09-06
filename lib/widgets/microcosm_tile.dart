import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'dart:developer' show log;

import '../models/microcosm.dart';
import 'future_microcosm_screen.dart';

class MicrocosmTile extends StatefulWidget {
  final Microcosm microcosm;
  const MicrocosmTile({super.key, required this.microcosm});

  @override
  State<MicrocosmTile> createState() => _MicrocosmTileState();
}

class _MicrocosmTileState extends State<MicrocosmTile> {
  final unescape = HtmlUnescape();

  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;
    return Card(
      key: ValueKey(widget.microcosm.id),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              fullscreenDialog: true,
              maintainState: true,
              builder: (context) => FutureMicrocosmScreen(
                microcosm: Microcosm.getById(widget.microcosm.id),
              ),
            ),
          );
        },
        child: ListTile(
          leading: (widget.microcosm.logoUrl.isEmpty
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
                            Icons.error,
                          ),
                        ),
                      ),
                    ))),
          title: Row(
            children: [
              // if (unread)
              //   Row(
              //     children: [
              //       Icon(Icons.circle, size: 10.0, color: Theme.of(context).colorScheme.primary),
              //       SizedBox(width: 5.0, height: 5.0),
              //     ],
              //   ),
              Expanded(
                child: Text(
                  unescape.convert(widget.microcosm.title),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          subtitle: Text(
            unescape.convert(widget.microcosm.description),
          ),
        ),
      ),
    );
  }
}

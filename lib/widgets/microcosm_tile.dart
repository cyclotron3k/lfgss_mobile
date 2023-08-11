import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';

import '../models/microcosm.dart';
import 'future_microcosm_screen.dart';

class MicrocosmTile extends StatefulWidget {
  final Microcosm microcosm;
  const MicrocosmTile({super.key, required this.microcosm});

  @override
  State<MicrocosmTile> createState() => _MicrocosmTileState();
}

class _MicrocosmTileState extends State<MicrocosmTile> {
  @override
  Widget build(BuildContext context) {
    final unescape = HtmlUnescape();
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
                  ? const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(6.0),
                      child: Container(
                        color: const Color.fromARGB(127, 255, 255, 255),
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
              //   const Row(
              //     children: [
              //       Icon(Icons.circle, size: 10.0, color: Colors.blue),
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

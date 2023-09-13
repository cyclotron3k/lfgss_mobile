import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';

import '../../models/microcosm.dart';
import '../screens/future_microcosm_screen.dart';
import '../microcosm_logo.dart';

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
          leading: MicrocosmLogo(microcosm: widget.microcosm),
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

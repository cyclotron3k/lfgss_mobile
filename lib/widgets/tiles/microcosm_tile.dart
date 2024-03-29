import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';

import '../../models/microcosm.dart';
import '../screens/future_microcosm_screen.dart';
import '../microcosm_logo.dart';

class MicrocosmTile extends StatelessWidget {
  final Microcosm microcosm;
  const MicrocosmTile({super.key, required this.microcosm});

  @override
  Widget build(BuildContext context) {
    final unescape = HtmlUnescape();
    return Card(
      key: ValueKey(microcosm.id),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              fullscreenDialog: true,
              maintainState: true,
              builder: (context) => FutureMicrocosmScreen(
                microcosm: Microcosm.getById(microcosm.id),
              ),
            ),
          );
        },
        child: ListTile(
          leading: MicrocosmLogo(microcosm: microcosm),
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
                  unescape.convert(microcosm.title),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          subtitle: Text(
            unescape.convert(microcosm.description),
          ),
        ),
      ),
    );
  }
}

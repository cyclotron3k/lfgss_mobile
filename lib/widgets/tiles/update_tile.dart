import 'package:flutter/material.dart';
import 'package:lfgss_mobile/models/update_type.dart';

import '../../models/update.dart';

class UpdateTile extends StatelessWidget {
  final Update update;

  const UpdateTile({
    super.key,
    required this.update,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          alignment: Alignment.bottomLeft,
          height: 28.0,
          padding: const EdgeInsets.only(left: 64.0),
          child: Text(
            update.description,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        update.parent.renderAsTile(
          overrideUnreadFlag: update.flags.unread,
          isReply: update.updateType == UpdateType.reply_to_comment,
          mentioned: update.updateType == UpdateType.mentioned,
        ),
      ],
    );
  }
}

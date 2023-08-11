import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../widgets/update_tile.dart';
import 'flags.dart';
import 'item.dart';

// enum UpdateTypes {
//   event_reminder,
//   mentioned,
//   new_comment,
//   new_comment_in_huddle,
//   new_attendee,
//   new_item,
//   new_vote,
//   new_user,
//   reply_to_comment,
// }

class Update extends Item {
  final String updateType;
  final Item parent;
  final Item child;
  final Flags flags;

  Update({
    required this.updateType,
    required this.parent,
    required this.child,
    required this.flags,
  });

  String get description {
    switch (updateType) {
      case 'event_reminder':
        {
          return "Upcoming event";
        }
      case 'mentioned':
        {
          return "You were mentioned in a thread";
        }
      case 'new_comment':
        {
          return "New comment in a thread you watch";
        }
      case 'new_comment_in_huddle':
        {
          return "You received a DM";
        }
      case 'new_attendee':
        {
          return "New attendee";
        }
      case 'new_item':
        {
          return "New item";
        }
      case 'new_vote':
        {
          return "Received a vote";
        }
      case 'new_user':
        {
          return "New user";
        }
      case 'reply_to_comment':
        {
          return "A reply to your comment";
        }
      default:
        {
          developer.log("Can't handle updateType of: $updateType");
          return "";
        }
    }
  }

  @override
  Widget renderAsTile() {
    return UpdateTile(child: child, parent: parent, description: description);
  }
}

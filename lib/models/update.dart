import 'dart:convert';
import 'dart:developer' show log;

import 'package:flutter/material.dart';

import '../widgets/tiles/update_tile.dart';
import 'comment.dart';
import 'conversation.dart';
import 'event.dart';
import 'flags.dart';
import 'huddle.dart';
import 'item.dart';
import 'item_parser.dart' hide Json;
import 'update_type.dart';

class Update extends Item {
  final int id;
  final UpdateType updateType;
  final Item parent;
  final Item child;
  final Flags flags;

  Update({
    required this.id,
    required this.updateType,
    required this.parent,
    required this.child,
    required this.flags,
  });

  Update.fromJson(Json json)
      : id = json["id"],
        updateType = UpdateType.values.byName(json["updateType"]),
        flags = Flags.fromJson(json: json["meta"]["flags"]),
        child = ItemParser.parseItemJson(
          json["itemType"],
          json["item"],
        ),
        parent = json["parentItemType"] == null
            ? ItemParser.parseItemJson(
                json["itemType"],
                json["item"],
              )
            : ItemParser.parseItemJson(
                json["parentItemType"],
                json["parentItem"],
              );

  String get title {
    if (parent is Conversation) {
      return (parent as Conversation).title;
    } else if (parent is Huddle) {
      return (parent as Huddle).title;
    } else {
      return description;
    }
  }

  String get payload {
    var payload = <String, dynamic>{};

    if (parent is Conversation) {
      payload["goto"] = "conversation";
      payload["id"] = (parent as Conversation).id;
      payload["commentId"] = (child as Comment).id;
    } else if (parent is Event) {
      payload["goto"] = "event";
      payload["id"] = (parent as Event).id;
      payload["commentId"] = (child as Comment).id;
    } else if (child is Conversation) {
      payload["goto"] = "conversation";
      payload["id"] = (child as Conversation).id;
    } else if (parent is Huddle) {
      payload["goto"] = "huddle";
      payload["id"] = (parent as Huddle).id;
      payload["commentId"] = (child as Comment).id;
    } else {
      log("Don't know how to handle ${updateType.name}");
      return "";
    }

    return jsonEncode(payload);
  }

  String get body {
    if (child is Comment) {
      return "${(child as Comment).createdBy.profileName}: ${(child as Comment).markdown}";
    } else {
      return description;
    }
  }

  int get topicId {
    if (parent is Conversation) {
      return (parent as Conversation).id;
    } else {
      return id;
    }
  }

  String get conversationId {
    if (parent is Conversation) {
      return (parent as Conversation).id.toString();
    } else {
      return "";
    }
  } // TODO: promote id?

  String get description {
    switch (updateType) {
      case UpdateType.event_reminder:
        return "Upcoming event";
      case UpdateType.mentioned:
        return "You were mentioned in a thread";
      case UpdateType.new_comment:
        return "New comment in a thread you watch";
      case UpdateType.new_comment_in_huddle:
        return "You received a DM";
      case UpdateType.new_attendee:
        return "New attendee";
      case UpdateType.new_item:
        return "New item";
      case UpdateType.new_vote:
        return "Received a vote";
      case UpdateType.new_user:
        return "New user";
      case UpdateType.reply_to_comment:
        return "A reply to your comment";
      default:
        {
          log("Can't handle updateType of: $updateType");
          return "";
        }
    }
  }

  @override
  Widget renderAsTile({bool? overrideUnreadFlag}) {
    return UpdateTile(update: this);
  }
}

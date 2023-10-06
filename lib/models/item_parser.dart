import 'comment.dart';
import 'conversation.dart';
import 'event.dart';
import 'huddle.dart';
import 'microcosm.dart';
import 'profile.dart';
import 'unknown_item.dart';

typedef Json = Map<String, dynamic>;

class ItemParser {
  static parseItemJson(String itemType, Json json) {
    switch (itemType) {
      case "comment":
        return Comment.fromJson(json: json);

      case "microcosm":
        return Microcosm.fromJson(json: json);

      case "conversation":
        return Conversation.fromJson(json: json);

      case "event":
        return Event.fromJson(json: json);

      case "poll":
        return UnknownItem(id: json["id"], type: itemType);

      case "huddle":
        return Huddle.fromJson(json: json);

      case "profile":
        return Profile.fromJson(json: json);

      default:
        throw "Don't know how to handle itemType of $itemType";
    }
  }
}

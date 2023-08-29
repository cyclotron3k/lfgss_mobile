import 'comment.dart';
import 'conversation.dart';
import 'huddle.dart';
import 'microcosm.dart';
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
        return UnknownItem(type: itemType);

      case "poll":
        return UnknownItem(type: itemType);

      case "huddle":
        return Huddle.fromJson(json: json);

      default:
        throw "Don't know how to handle itemType of $itemType";
    }
  }
}

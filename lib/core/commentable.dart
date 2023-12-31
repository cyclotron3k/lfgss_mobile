import '../models/comment.dart';
import 'authored.dart';
import 'item.dart';
import 'paginated_item.dart';

abstract class CommentableItem
    implements PaginatedItem<Comment>, Item, Authored {
  Future<bool> subscribe();
  Future<bool> unsubscribe();
  bool get canComment;
  String get title;

  // `pageNo` is the "public" page number, not our page number
  Future<CommentableItem> getByPageNo(int pageNo);
}

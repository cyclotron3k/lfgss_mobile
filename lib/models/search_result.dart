import 'item.dart';

// TODO: Merge this with update.dart? Make parent item an optional property of the child?

class SearchResult {
  final Item child;
  final Item? parent;

  SearchResult({
    required this.child,
    this.parent,
  });
}

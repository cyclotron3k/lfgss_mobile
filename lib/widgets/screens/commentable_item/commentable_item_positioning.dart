import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../constants.dart';
import '../../../core/commentable_item.dart';

int? currentVisibleCommentIndex({
  required Iterable<ItemPosition> itemPositions,
  required int commentListStartIndex,
  required int totalChildren,
  double viewportAnchor = 0.35,
}) {
  int? bestIndex;
  double bestDistance = double.infinity;

  for (final position in itemPositions) {
    final commentIndex = position.index - commentListStartIndex;
    if (commentIndex < 0 || commentIndex >= totalChildren) continue;

    final visibleTop = position.itemLeadingEdge.clamp(0.0, 1.0);
    final visibleBottom = position.itemTrailingEdge.clamp(0.0, 1.0);
    if (visibleBottom <= 0.0 || visibleTop >= 1.0) continue;

    final distance =
        (((visibleTop + visibleBottom) / 2) - viewportAnchor).abs();
    if (distance < bestDistance) {
      bestDistance = distance;
      bestIndex = commentIndex;
    }
  }

  return bestIndex;
}

Uri webUrlForCurrentPosition({
  required CommentableItem item,
  required int? visibleIndex,
  required int? visibleCommentId,
}) {
  final selfUrl = item.selfUrl;
  final pathWithoutNewest = selfUrl.path.replaceFirst(
    RegExp(r'/newest/?$'),
    '',
  );
  final basePath = pathWithoutNewest.endsWith('/')
      ? pathWithoutNewest
      : '$pathWithoutNewest/';

  final fallbackOffset = ((item.startPage * PAGE_SIZE) ~/ 25) * 25;
  final offset =
      visibleIndex == null ? fallbackOffset : (visibleIndex ~/ 25) * 25;

  return Uri(
    scheme: selfUrl.scheme,
    host: selfUrl.host,
    path: basePath,
    queryParameters: {'offset': offset.toString()},
    fragment: visibleCommentId == null ? null : 'comment$visibleCommentId',
  );
}

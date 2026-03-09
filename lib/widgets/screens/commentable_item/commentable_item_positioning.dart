import 'package:flutter/material.dart';

import '../../../constants.dart';
import '../../../core/commentable_item.dart';

GlobalKey commentKeyForIndex(Map<int, GlobalKey> commentKeys, int index) {
  return commentKeys.putIfAbsent(
    index,
    () => GlobalKey(debugLabel: 'comment-$index'),
  );
}

int? currentVisibleCommentIndex({
  required BuildContext context,
  required Map<int, GlobalKey> commentKeys,
}) {
  final mediaQuery = MediaQuery.of(context);
  final topInset = mediaQuery.padding.top + kToolbarHeight;
  final bottomInset = mediaQuery.padding.bottom;
  final viewportHeight = mediaQuery.size.height - topInset - bottomInset;

  if (viewportHeight <= 0) return null;

  final viewportCenterY = topInset + (viewportHeight / 2);
  int? bestIndex;
  double bestDistance = double.infinity;

  for (final entry in commentKeys.entries) {
    final currentContext = entry.value.currentContext;
    if (currentContext == null) continue;

    final renderObject = currentContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) continue;

    final topLeft = renderObject.localToGlobal(Offset.zero);
    final rect = topLeft & renderObject.size;
    final isVisible =
        rect.bottom > topInset && rect.top < topInset + viewportHeight;
    if (!isVisible) continue;

    final distance = (rect.center.dy - viewportCenterY).abs();
    if (distance < bestDistance) {
      bestDistance = distance;
      bestIndex = entry.key;
    }
  }

  return bestIndex;
}

Future<Uri> webUrlForCurrentPosition({
  required BuildContext context,
  required CommentableItem item,
  required Map<int, GlobalKey> commentKeys,
}) async {
  final selfUrl = item.selfUrl;
  final pathWithoutNewest = selfUrl.path.replaceFirst(
    RegExp(r'/newest/?$'),
    '',
  );
  final basePath = pathWithoutNewest.endsWith('/')
      ? pathWithoutNewest
      : '$pathWithoutNewest/';

  final visibleIndex = currentVisibleCommentIndex(
    context: context,
    commentKeys: commentKeys,
  );
  final fallbackOffset = ((item.startPage * PAGE_SIZE) ~/ 25) * 25;
  final offset =
      visibleIndex == null ? fallbackOffset : (visibleIndex ~/ 25) * 25;

  int? visibleCommentId;
  if (visibleIndex != null) {
    try {
      visibleCommentId = await item
          .getChild(visibleIndex)
          .then<int?>((comment) => comment.id)
          .timeout(
            const Duration(milliseconds: 150),
            onTimeout: () => null,
          );
    } catch (_) {
      visibleCommentId = null;
    }
  }

  return Uri(
    scheme: selfUrl.scheme,
    host: selfUrl.host,
    path: basePath,
    queryParameters: {'offset': offset.toString()},
    fragment: visibleCommentId == null ? null : 'comment$visibleCommentId',
  );
}

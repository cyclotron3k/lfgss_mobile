import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class AttachmentThumbnail extends StatefulWidget {
  final XFile image;
  final Function onRemoveItem;

  const AttachmentThumbnail({
    super.key,
    required this.image,
    required this.onRemoveItem,
  });

  @override
  State<AttachmentThumbnail> createState() => _AttachmentThumbnailState();
}

class _AttachmentThumbnailState extends State<AttachmentThumbnail> {
  bool remove = false;
  double? dx;
  double? dy;

  @override
  Widget build(BuildContext context) {
    Widget image = ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Image.file(
        File(widget.image.path),
        height: 80.0 - 8.0,
      ),
    );

    return Draggable(
      // affinity: Axis.horizontal,
      // axis: Axis.vertical,
      onDragEnd: (details) {
        dx = null;
        dy = null;
        if (remove) {
          widget.onRemoveItem(widget.image);
        }
      },
      onDragUpdate: (details) {
        dx ??= details.localPosition.dx;
        dy ??= details.localPosition.dy;

        bool newRemove = ((dx! - details.localPosition.dx).abs() +
                (dy! - details.localPosition.dy).abs()) >
            80.0;
        if (remove ^ newRemove) {
          setState(() => remove = newRemove);
        }
      },
      feedback: image,
      childWhenDragging: Stack(
        children: [
          Opacity(
            opacity: remove ? 0.4 : 0.8,
            child: image,
          ),
          Positioned.fill(
            child: Center(
              child: Icon(
                remove ? Icons.delete : Icons.delete_outline,
                color: remove ? Colors.red : Colors.white,
              ),
            ),
          ),
        ],
      ),
      child: image,
    );
  }
}

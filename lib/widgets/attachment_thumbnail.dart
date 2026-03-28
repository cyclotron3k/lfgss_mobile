import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class AttachmentThumbnail extends StatefulWidget {
  final XFile image;
  final Function onRemoveItem;
  final double? uploadProgress;

  const AttachmentThumbnail({
    super.key,
    required this.image,
    required this.onRemoveItem,
    this.uploadProgress,
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
    final uploading = widget.uploadProgress != null;

    Widget image = SizedBox(
      height: 72.0,
      width: 72.0,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.file(
              File(widget.image.path),
              fit: BoxFit.cover,
            ),
          ),
          if (uploading)
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          if (uploading)
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: CircularProgressIndicator(
                value: widget.uploadProgress!.clamp(0.0, 1.0).toDouble(),
                strokeWidth: 3.0,
              ),
            ),
        ],
      ),
    );

    return Draggable(
      // affinity: Axis.horizontal,
      // axis: Axis.vertical,
      maxSimultaneousDrags: uploading ? 0 : null,
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
          if (!uploading)
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

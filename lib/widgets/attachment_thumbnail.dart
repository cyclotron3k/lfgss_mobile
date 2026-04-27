import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/attachment.dart';
import '../services/attachment_cache_manager.dart';

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
  @override
  Widget build(BuildContext context) {
    final uploading = widget.uploadProgress != null;
    return SizedBox(
      height: 72.0,
      width: 72.0,
      child: Stack(
        clipBehavior: Clip.none,
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
          Positioned(
            top: -8.0,
            right: -8.0,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                iconSize: 18.0,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),
                onPressed:
                    uploading ? null : () => widget.onRemoveItem(widget.image),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExistingAttachmentThumbnail extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback onRemove;

  const ExistingAttachmentThumbnail({
    super.key,
    required this.attachment,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72.0,
      width: 72.0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: _preview(context),
              ),
            ),
          ),
          Positioned(
            top: -8.0,
            right: -8.0,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.error,
                ),
                iconSize: 18.0,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),
                onPressed: onRemove,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _preview(BuildContext context) {
    if (attachment.isImage) {
      return CachedNetworkImage(
        imageUrl: attachment.url,
        cacheManager: AttachmentCacheManager.instance,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => _filePreview(context),
      );
    }

    return _filePreview(context);
  }

  Widget _filePreview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            attachment.fileTypeIcon,
            size: 24.0,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 4.0),
          Text(
            attachment.fileName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

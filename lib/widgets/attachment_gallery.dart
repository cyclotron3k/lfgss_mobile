import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';

import '../models/attachment.dart';

class AttachmentGallery extends StatefulWidget {
  AttachmentGallery({
    super.key,
    this.loadingBuilder,
    this.initialIndex = 0,
    required this.attachments,
    this.scrollDirection = Axis.horizontal,
  }) : pageController = PageController(initialPage: initialIndex);

  final LoadingBuilder? loadingBuilder;
  final int initialIndex;
  final PageController pageController;
  final List<Attachment> attachments;
  final Axis scrollDirection;

  @override
  State<StatefulWidget> createState() {
    return _GalleryPhotoViewWrapperState();
  }
}

class _GalleryPhotoViewWrapperState extends State<AttachmentGallery> {
  late int currentIndex = widget.initialIndex;

  void onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  Future<void> shareImage() async {
    var file = await DefaultCacheManager().getSingleFile(
      widget.attachments[currentIndex].url,
    );
    var xfile = XFile(
      file.path,
      name: widget.attachments[currentIndex].fileName,
    );
    Share.shareXFiles(
      [xfile],
      //text: attachment.fileName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Stack(
          alignment: Alignment.bottomRight,
          children: <Widget>[
            PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: _buildItem,
              itemCount: widget.attachments.length,
              loadingBuilder: widget.loadingBuilder,
              backgroundDecoration: const BoxDecoration(),
              pageController: widget.pageController,
              onPageChanged: onPageChanged,
              scrollDirection: widget.scrollDirection,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.adaptive.share),
                  tooltip: 'Share',
                  onPressed: () async {
                    await shareImage();
                  },
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 48.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  PhotoViewGalleryPageOptions _buildItem(BuildContext context, int index) =>
      PhotoViewGalleryPageOptions(
        imageProvider: CachedNetworkImageProvider(
          widget.attachments[index].url,
        ),
        initialScale: PhotoViewComputedScale.contained,
        minScale: PhotoViewComputedScale.contained * 0.8,
      );
}

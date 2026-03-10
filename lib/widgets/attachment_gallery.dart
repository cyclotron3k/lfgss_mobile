import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';

import '../models/attachment.dart';
import '../services/attachment_cache_manager.dart';

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
    var file = await AttachmentCacheManager.instance.getSingleFile(
      widget.attachments[currentIndex].url,
    );
    var xfile = XFile(
      file.path,
      name: widget.attachments[currentIndex].fileName,
    );
    SharePlus.instance.share(ShareParams(files: [xfile]));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Stack(
          alignment: Alignment.bottomRight,
          children: <Widget>[
            PageView.builder(
              scrollDirection: widget.scrollDirection,
              controller: widget.pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: onPageChanged,
              itemCount: widget.attachments.length,
              itemBuilder: _buildItem,
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

  Widget _buildItem(BuildContext context, int index) {
    return widget.attachments[index].buildForGallery(context);
  }
}

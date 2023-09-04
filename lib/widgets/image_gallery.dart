import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:photo_view/photo_view.dart';

import '../models/attachment.dart';

class ImageGallery extends ModalRoute {
  // variables passed from the parent widget
  final Attachment attachment;

  // constructor
  ImageGallery({required this.attachment});

  @override
  Duration get transitionDuration => const Duration(milliseconds: 250);

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color get barrierColor => Colors.black.withOpacity(0.8);

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  Future<void> _shareImage() async {
    var file = await DefaultCacheManager().getSingleFile(
      attachment.getUrl(),
    );
    var xfile = XFile(file.path, name: attachment.fileName);
    Share.shareXFiles(
      [xfile],
      //text: attachment.fileName,
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: PhotoView(
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                heroAttributes: PhotoViewHeroAttributes(
                  tag: attachment.fileHash,
                  //transitionOnUserGestures: true,
                ),
                minScale: PhotoViewComputedScale.contained * 0.8,
                imageProvider: attachment.asImageProvider(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.adaptive.share),
                  tooltip: 'Share',
                  onPressed: () async {
                    await _shareImage();
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

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    // add fade animation
    return FadeTransition(
      opacity: animation,
      // add slide animation
      child: child,
    );
  }
}

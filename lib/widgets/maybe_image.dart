import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../services/settings.dart';

enum ImageState {
  blocked,
  downloading,
  downloaded,
  error,
}

class MaybeImage extends StatefulWidget {
  final CachedNetworkImage cni;

  MaybeImage({
    super.key,
    required String imageUrl,
    imageBuilder,
    placeholder,
    progressIndicatorBuilder = _defaultProgress,
    errorWidget,
    fadeOutDuration = const Duration(milliseconds: 1000),
    fadeOutCurve = Curves.easeOut,
    fadeInDuration = const Duration(milliseconds: 500),
    fadeInCurve = Curves.easeIn,
    width,
    height,
    fit,
    alignment = Alignment.center,
    repeat = ImageRepeat.noRepeat,
    matchTextDirection = false,
    cacheManager,
    useOldImageOnUrlChange = false,
    color,
    filterQuality = FilterQuality.low,
    colorBlendMode,
    placeholderFadeInDuration,
    memCacheWidth,
    memCacheHeight,
    cacheKey,
    maxWidthDiskCache,
    maxHeightDiskCache,
  }) : cni = CachedNetworkImage(
          imageUrl: imageUrl,
          httpHeaders: const {"User-Agent": USER_AGENT},
          imageBuilder: imageBuilder,
          placeholder: placeholder,
          progressIndicatorBuilder: progressIndicatorBuilder,
          errorWidget: errorWidget,
          fadeOutDuration: fadeOutDuration,
          fadeOutCurve: fadeOutCurve,
          fadeInDuration: fadeInDuration,
          fadeInCurve: fadeInCurve,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          repeat: repeat,
          matchTextDirection: matchTextDirection,
          cacheManager: cacheManager,
          useOldImageOnUrlChange: useOldImageOnUrlChange,
          color: color,
          filterQuality: filterQuality,
          colorBlendMode: colorBlendMode,
          placeholderFadeInDuration: placeholderFadeInDuration,
          memCacheWidth: memCacheWidth,
          memCacheHeight: memCacheHeight,
          cacheKey: cacheKey,
          maxWidthDiskCache: maxWidthDiskCache,
          maxHeightDiskCache: maxHeightDiskCache,
        );

  static Widget _defaultProgress(
    BuildContext context,
    String url,
    DownloadProgress downloadProgress,
  ) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          color: Colors.grey.shade800,
          child: AspectRatio(
            aspectRatio: 1,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 32.0,
                  maxWidth: 32.0,
                ),
                child: CircularProgressIndicator(
                  value: downloadProgress.progress,
                ),
              ),
            ),
          ),
        ),
      );

  @override
  State<MaybeImage> createState() => _MaybeImageState();
}

class _MaybeImageState extends State<MaybeImage> {
  ImageState imageState = ImageState.blocked;

  bool get _isFirstParty {
    var uri = Uri.parse(widget.cni.imageUrl);
    return API_HOST == uri.host;
  }

  Future<bool> get _precached async {
    final file = await DefaultCacheManager().getFileFromCache(
      widget.cni.imageUrl,
    );
    return file != null;
  }

  bool _allowDownload(Settings settings) {
    if (imageState != ImageState.blocked) return true;
    if (!((settings.getString('downloadImages') ?? 'always') == 'always')) {
      return false;
    }
    if (settings.getBool('downloadThirdParty') ?? true) return true;
    return _isFirstParty;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Settings>(builder: (context, settings, child) {
      if (_allowDownload(settings)) {
        return widget.cni.build(context);
      }

      return FutureBuilder<bool>(
        future: _precached,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data! as bool) {
              return widget.cni.build(context);
            } else {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  color: Colors.grey.shade800,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: InkWell(
                      child: const Center(
                        child: Icon(Icons.download),
                      ),
                      onTap: () {
                        setState(() => imageState = ImageState.downloading);
                      },
                    ),
                  ),
                ),
              );
            }
          } else {
            return const AspectRatio(
              aspectRatio: 1,
            );
          }
        },
      );
    });
  }
}

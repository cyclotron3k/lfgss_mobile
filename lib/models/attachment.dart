import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../constants.dart';
import '../services/attachment_cache_manager.dart';
import '../widgets/maybe_image.dart';
import 'links.dart';

class Attachment {
  final int profileId;
  final String fileHash;
  final String fileName;
  final String fileExt;
  final DateTime created;
  final String _url;
  final Links links;

  Attachment.fromJson({required Map<String, dynamic> json})
      : profileId = json["profileId"],
        fileHash = json["fileHash"],
        fileName = json["fileName"],
        fileExt = json["fileExt"],
        created = DateTime.parse(json["created"]),
        _url = json["meta"]["links"][0]["href"], // TODO: be more robust
        links = Links.fromJson(json: json["meta"]["links"]);

  String get url => _url.startsWith('/') ? "https://$API_HOST$_url" : _url;

  final imageExtMatcher = RegExp(
    r"^(jpe?g|png|webp|heic|gif)$",
    multiLine: false,
    caseSensitive: false,
  );
  final videoExtMatcher = RegExp(
    r"^(mp4|m4v|mov|webm|mkv|avi|wmv|mpeg|mpg)$",
    multiLine: false,
    caseSensitive: false,
  );

  bool get isImage => imageExtMatcher.hasMatch(fileExt);
  bool get isVideo => videoExtMatcher.hasMatch(fileExt);

  IconData get fileTypeIcon {
    final ext = fileExt.toLowerCase();

    if (isVideo) return Icons.play_circle;

    if ({'pdf'}.contains(ext)) return Icons.picture_as_pdf;
    if ({'doc', 'docx', 'odt', 'rtf', 'txt', 'md'}.contains(ext)) {
      return Icons.description;
    }
    if ({'xls', 'xlsx', 'ods', 'csv'}.contains(ext)) {
      return Icons.table_chart;
    }
    if ({'ppt', 'pptx', 'odp'}.contains(ext)) return Icons.slideshow;
    if ({'zip', 'rar', '7z', 'tar', 'gz', 'bz2'}.contains(ext)) {
      return Icons.folder_zip;
    }
    if ({'mp3', 'm4a', 'wav', 'aac', 'flac', 'ogg'}.contains(ext)) {
      return Icons.audiotrack;
    }

    return Icons.insert_drive_file;
  }

  Widget build(BuildContext context) {
    if (isImage) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0, right: 8.0, bottom: 8.0),
        child: MaybeImage(
          imageUrl: url,
          imageBuilder: (context, imageProvider) => ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image(
              image: imageProvider,
              fit: BoxFit.contain,
            ),
          ),
          errorWidget: (context, url, error) => const Icon(
            Icons.error_outline,
          ),
        ),
      );
    } else if (isVideo) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0, right: 8.0, bottom: 8.0),
        child: _AttachmentFileCard(
          attachment: this,
          borderRadius: 8.0,
          aspectRatio: 1.0,
          iconSize: 36.0,
          padding: EdgeInsets.zero,
          interactive: false,
        ),
      );
    } else {
      return _AttachmentFileCard(
        attachment: this,
        borderRadius: 8.0,
        aspectRatio: 1.0,
        iconSize: 36.0,
        padding: const EdgeInsets.only(top: 8.0, right: 8.0, bottom: 8.0),
      );
    }
  }

  Widget buildForGallery(BuildContext context) {
    if (isImage) {
      return PhotoView(
        imageProvider: CachedNetworkImageProvider(
          url,
          cacheManager: AttachmentCacheManager.instance,
        ),
        initialScale: PhotoViewComputedScale.contained,
        minScale: PhotoViewComputedScale.contained * 0.8,
        backgroundDecoration: const BoxDecoration(),
      );
    } else if (isVideo) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _AttachmentVideoPlayer(
            attachment: this,
            borderRadius: 12.0,
            showProgress: true,
          ),
        ),
      );
    } else {
      return Center(
        child: _AttachmentFileCard(
          attachment: this,
          borderRadius: 12.0,
          aspectRatio: 1.6,
          iconSize: 52.0,
          padding: const EdgeInsets.all(16.0),
          showOpenIcon: true,
        ),
      );
    }
  }
}

class _AttachmentVideoPlayer extends StatefulWidget {
  const _AttachmentVideoPlayer({
    required this.attachment,
    required this.borderRadius,
    required this.showProgress,
  });

  final Attachment attachment;
  final double borderRadius;
  final bool showProgress;

  @override
  State<_AttachmentVideoPlayer> createState() => _AttachmentVideoPlayerState();
}

class _AttachmentVideoPlayerState extends State<_AttachmentVideoPlayer> {
  VideoPlayerController? _controller;
  late final Future<void> _initializeVideoPlayerFuture;
  Object? _initializationError;
  double? _downloadProgress;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.attachment.url),
    );
    _initializeVideoPlayerFuture = _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      final stream = AttachmentCacheManager.instance.getFileStream(
        widget.attachment.url,
        withProgress: true,
      );
      await for (final response in stream) {
        if (response is DownloadProgress) {
          if (mounted) setState(() => _downloadProgress = response.progress);
        } else if (response is FileInfo) {
          _controller = VideoPlayerController.file(response.file);
          await _controller!.initialize();
          _controller!.addListener(_onVideoPositionUpdate);
          break;
        }
      }
    } catch (error) {
      _initializationError = error;
    }
  }

  void _onVideoPositionUpdate() {
    final controller = _controller;
    if (controller == null) return;
    final pos = controller.value.position;
    final dur = controller.value.duration;
    if (dur > Duration.zero && pos >= dur && !controller.value.isPlaying) {
      controller.seekTo(Duration.zero);
      _hideControlsTimer?.cancel();
      if (mounted) setState(() => _showControls = true);
    }
  }

  void _resetHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _onVideoTap() {
    setState(() => _showControls = true);
    if (_controller?.value.isPlaying == true) {
      _resetHideTimer();
    }
  }

  void _onPlayPauseTap() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
        _hideControlsTimer?.cancel();
      } else {
        controller.play();
        _resetHideTimer();
      }
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.removeListener(_onVideoPositionUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initializationError != null) {
      return _AttachmentFileCard(
        attachment: widget.attachment,
        borderRadius: widget.borderRadius,
        aspectRatio: widget.showProgress ? 1.6 : 1.0,
        iconSize: widget.showProgress ? 52.0 : 36.0,
        padding: EdgeInsets.zero,
        showOpenIcon: widget.showProgress,
      );
    }

    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return AspectRatio(
            aspectRatio: 1,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 32.0,
                  maxWidth: 32.0,
                ),
                child: CircularProgressIndicator(value: _downloadProgress),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _AttachmentFileCard(
            attachment: widget.attachment,
            borderRadius: widget.borderRadius,
            aspectRatio: widget.showProgress ? 1.6 : 1.0,
            iconSize: widget.showProgress ? 52.0 : 36.0,
            padding: EdgeInsets.zero,
            showOpenIcon: widget.showProgress,
          );
        }

        return GestureDetector(
          onTap: _onVideoTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Container(
              color: Colors.black,
              child: AspectRatio(
                aspectRatio:
                    widget.showProgress ? _controller!.value.aspectRatio : 1.0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: _controller!.value.size.width,
                          height: _controller!.value.size.height,
                          child: VideoPlayer(_controller!),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: AnimatedOpacity(
                        opacity: _showControls ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: IgnorePointer(
                          ignoring: !_showControls,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                bottom: widget.showProgress ? 8.0 : null,
                                child: IconButton.filledTonal(
                                  onPressed: _onPlayPauseTap,
                                  icon: Icon(
                                    _controller!.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                  ),
                                ),
                              ),
                              if (widget.showProgress)
                                Positioned(
                                  left: 8.0,
                                  right: 8.0,
                                  bottom: 0.0,
                                  child: VideoProgressIndicator(
                                    _controller!,
                                    allowScrubbing: true,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AttachmentFileCard extends StatelessWidget {
  const _AttachmentFileCard({
    required this.attachment,
    required this.borderRadius,
    required this.aspectRatio,
    required this.iconSize,
    required this.padding,
    this.showOpenIcon = false,
    this.interactive = true,
  });

  final Attachment attachment;
  final double borderRadius;
  final double aspectRatio;
  final double iconSize;
  final EdgeInsets padding;
  final bool showOpenIcon;
  final bool interactive;

  Widget _buildContent(BuildContext context) {
    final inner = Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(attachment.fileTypeIcon, size: iconSize),
          const SizedBox(height: 8.0),
          Text(
            attachment.fileName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (showOpenIcon) const SizedBox(height: 12.0),
          if (showOpenIcon) const Icon(Icons.open_in_new),
        ],
      ),
    );
    if (!interactive) return inner;
    return InkWell(
      onTap: () async => launchUrl(
        Uri.parse(attachment.url),
        mode: LaunchMode.externalApplication,
      ),
      child: inner,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          color: Colors.grey.shade800,
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: _buildContent(context),
          ),
        ),
      ),
    );
  }
}

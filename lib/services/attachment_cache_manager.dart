import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class AttachmentCacheManager {
  static const key = 'attachment-cache-key';
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 14),
    ),
  );
}

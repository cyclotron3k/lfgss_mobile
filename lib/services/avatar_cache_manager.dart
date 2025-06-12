import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class AvatarCacheManager {
  static const key = 'avatar-cache-key';
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 90),
    ),
  );
}

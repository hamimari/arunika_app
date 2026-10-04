import 'dart:async';

import 'package:arunika_app/core/logger/app_logger.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_audio/just_audio.dart';

/// On-device disk cache for remote media (images, audio) so a file is
/// downloaded once instead of on every app launch.
///
/// Content is served from Cloudflare R2, which bills per read request, so
/// repeat downloads cost money as well as data and load time. Files are
/// treated as immutable: a cached copy is reused for [minFreshness] before
/// the server is asked again. When replacing a file, upload it under a new
/// URL (e.g. a new filename) so installed apps pick it up.
class MediaCache {
  MediaCache._();

  static const Duration minFreshness = Duration(days: 30);

  // Entries not used for 60 days, or beyond the newest 1000 files, are
  // evicted so the cache can't grow without bound.
  static final CacheManager manager = CacheManager(
    Config(
      'arunika_media',
      stalePeriod: const Duration(days: 60),
      maxNrOfCacheObjects: 1000,
      fileService: _ImmutableHttpFileService(),
    ),
  );

  /// Drop-in replacement for `NetworkImage(url)` backed by the disk cache.
  static ImageProvider image(String url) =>
      CachedNetworkImageProvider(url, cacheManager: manager);

  /// Points [player] at [url], playing from the disk cache when the file has
  /// been downloaded before. On a cache miss it streams [url] as usual and
  /// saves a copy in the background, so the next play needs no download.
  static Future<Duration?> setAudioUrl(
    AudioPlayer player,
    String url, {
    @visibleForTesting BaseCacheManager? cache,
  }) async {
    final manager = cache ?? MediaCache.manager;
    try {
      final cached = await manager.getFileFromCache(url);
      if (cached != null && await cached.file.exists()) {
        return player.setFilePath(cached.file.path);
      }
    } catch (e) {
      AppLogger.warning(
        'Audio cache lookup failed',
        name: 'MediaCache',
        error: e,
      );
    }
    unawaited(
      manager
          .downloadFile(url)
          .then<void>(
            (_) {},
            onError: (Object e) {
              AppLogger.warning(
                'Audio cache download failed',
                name: 'MediaCache',
                error: e,
              );
            },
          ),
    );
    return player.setUrl(url);
  }
}

/// [HttpFileService] that keeps responses valid for at least
/// [MediaCache.minFreshness], even when the server sends no or a short
/// `Cache-Control` (r2.dev public URLs send none).
class _ImmutableHttpFileService extends HttpFileService {
  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    return MinFreshnessResponse(await super.get(url, headers: headers));
  }
}

@visibleForTesting
class MinFreshnessResponse implements FileServiceResponse {
  final FileServiceResponse _inner;

  MinFreshnessResponse(this._inner);

  @override
  DateTime get validTill {
    final floor = DateTime.now().add(MediaCache.minFreshness);
    return _inner.validTill.isAfter(floor) ? _inner.validTill : floor;
  }

  @override
  Stream<List<int>> get content => _inner.content;

  @override
  int? get contentLength => _inner.contentLength;

  @override
  int get statusCode => _inner.statusCode;

  @override
  String? get eTag => _inner.eTag;

  @override
  String get fileExtension => _inner.fileExtension;
}

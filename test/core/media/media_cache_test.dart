import 'dart:io' show SocketException;

import 'package:arunika_app/core/media/media_cache.dart';
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockCacheManager extends Mock implements BaseCacheManager {}

class FakeResponse implements FileServiceResponse {
  @override
  final DateTime validTill;
  FakeResponse(this.validTill);

  @override
  Stream<List<int>> get content => const Stream.empty();
  @override
  int? get contentLength => 0;
  @override
  int get statusCode => 200;
  @override
  String? get eTag => 'etag';
  @override
  String get fileExtension => '.png';
}

void main() {
  late MockAudioPlayer player;
  late MockCacheManager cache;
  const url = 'https://pub-x.r2.dev/dongeng/kancil.mp3';

  setUp(() {
    player = MockAudioPlayer();
    cache = MockCacheManager();
  });

  test('plays from the cached file when it was downloaded before', () async {
    const fs = LocalFileSystem();
    final dir = await fs.systemTempDirectory.createTemp('media_cache_test');
    addTearDown(() => dir.delete(recursive: true));
    final file = await fs.file('${dir.path}/kancil.mp3').writeAsBytes([
      1,
      2,
      3,
    ]);
    when(() => cache.getFileFromCache(url)).thenAnswer(
      (_) async => FileInfo(file, FileSource.Cache, DateTime.now(), url),
    );
    when(() => player.setFilePath(file.path)).thenAnswer((_) async => null);

    await MediaCache.setAudioUrl(player, url, cache: cache);

    verify(() => player.setFilePath(file.path)).called(1);
    verifyNever(() => player.setUrl(any()));
    verifyNever(() => cache.downloadFile(any()));
  });

  test('streams on a cache miss and saves a copy for next time', () async {
    when(() => cache.getFileFromCache(url)).thenAnswer((_) async => null);
    when(() => cache.downloadFile(url)).thenAnswer(
      (_) async => FileInfo(
        const LocalFileSystem().file('unused'),
        FileSource.Online,
        DateTime.now(),
        url,
      ),
    );
    when(() => player.setUrl(url)).thenAnswer((_) async => null);

    await MediaCache.setAudioUrl(player, url, cache: cache);

    verify(() => player.setUrl(url)).called(1);
    verify(() => cache.downloadFile(url)).called(1);
  });

  test('a failed background download never breaks playback', () async {
    when(() => cache.getFileFromCache(url)).thenAnswer((_) async => null);
    when(
      () => cache.downloadFile(url),
    ).thenAnswer((_) => Future.error(const SocketException('offline')));
    when(() => player.setUrl(url)).thenAnswer((_) async => null);

    await MediaCache.setAudioUrl(player, url, cache: cache);
    await Future<void>.delayed(Duration.zero);

    verify(() => player.setUrl(url)).called(1);
  });

  group('MinFreshnessResponse', () {
    test('extends a missing/short server expiry to at least 30 days', () {
      final response = MinFreshnessResponse(
        FakeResponse(DateTime.now().add(const Duration(days: 7))),
      );
      expect(
        response.validTill.isAfter(
          DateTime.now().add(const Duration(days: 29)),
        ),
        isTrue,
      );
      expect(response.eTag, 'etag');
      expect(response.fileExtension, '.png');
    });

    test('keeps a longer server expiry', () {
      final serverExpiry = DateTime.now().add(const Duration(days: 365));
      expect(
        MinFreshnessResponse(FakeResponse(serverExpiry)).validTill,
        serverExpiry,
      );
    });
  });
}

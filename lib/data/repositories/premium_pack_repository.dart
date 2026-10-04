import 'package:arunika_app/data/api/premium_pack_api.dart';
import 'package:arunika_app/data/static/premium_packs.dart';

class PremiumPackRepository {
  final PremiumPackApi api;

  PremiumPackRepository(this.api);

  // Per-type cache: key = type string ('content', 'subscription', '')
  final Map<String, List<PremiumPack>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  static const _cacheTtl = Duration(minutes: 5);

  /// Fetches packs for the given [type], using cache if fresh.
  /// Falls back to static list on error.
  Future<List<PremiumPack>> fetchPacks({String? type}) async {
    final key = type ?? '';
    final timestamp = _cacheTimestamps[key];
    if (timestamp != null &&
        DateTime.now().difference(timestamp) < _cacheTtl &&
        _cache.containsKey(key)) {
      return _cache[key]!;
    }

    try {
      final raw = await api.fetchPacks(type: type);
      final packs = raw
          .map((e) => PremiumPack.fromJson(e as Map<String, dynamic>))
          .toList();
      _cache[key] = packs;
      _cacheTimestamps[key] = DateTime.now();
      return packs;
    } catch (_) {
      rethrow;
    }
  }

  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
}

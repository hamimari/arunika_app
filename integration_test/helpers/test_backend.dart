import 'package:arunika_app/config/app_config.dart';
import 'package:dio/dio.dart';

/// Seeds content and grants access directly against the real backend's admin
/// API, so integration tests exercise real HTTP end to end rather than
/// against data injected by some other mechanism (a raw SQL insert, a
/// fixture file) that the running app can never actually observe happening.
///
/// Every call here is exactly what the backoffice itself would send. This is
/// a deliberate choice over shelling out to `docker exec psql`: that would
/// only work on a machine with the Docker CLI in `PATH` and a container of a
/// guessed name, whereas an admin-API seed works against any backend this
/// suite is pointed at — including the docker-compose stack Phase 6 builds.
class TestBackend {
  TestBackend() : _dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

  final Dio _dio;
  String? _adminToken;

  Future<String> _requireAdminToken() async {
    if (_adminToken != null) return _adminToken!;
    // Seeded by db/seeds/R__seed_admin_user.sql on every environment this
    // suite can run against.
    final res = await _dio.post(
      '/admin/auth/login',
      data: {'email': 'admin@arunika.id', 'password': 'admin123'},
    );
    _adminToken = res.data['access_token'] as String;
    return _adminToken!;
  }

  Future<Options> _adminAuth() async => Options(
    headers: {'Authorization': 'Bearer ${await _requireAdminToken()}'},
  );

  /// Creates a free dongeng (no linked product, so the backend serves it
  /// unlocked to everyone — see DongengService.computeUnlocked).
  Future<String> seedFreeDongeng({required String title}) async {
    final res = await _dio.post(
      '/admin/content/fairy-tales',
      data: {
        'title': title,
        'image_url': 'https://example.test/dongeng.png',
        'audio_url': 'https://example.test/dongeng.mp3',
        'is_free': true,
        'duration': 300,
      },
      options: await _adminAuth(),
    );
    return res.data['data']['id'] as String;
  }

  /// Titles on the first page of the public dongeng list — all the app ever
  /// requests (10 stories, oldest first).
  Future<List<String>> firstPageDongengTitles() async {
    final res = await _dio.get('/fairy-tales');
    return [
      for (final item in res.data['data'] as List<dynamic>)
        (item as Map<String, dynamic>)['title'] as String,
    ];
  }

  /// Creates a paid dongeng with a linked product, so the backend serves it
  /// locked (with its price, and its Play SKU when given) until the viewing
  /// user is entitled.
  Future<({String dongengId, String productId})> seedPaidDongeng({
    required String title,
    int priceIdr = 39000,
    String? playProductId,
  }) async {
    final auth = await _adminAuth();
    final tale = await _dio.post(
      '/admin/content/fairy-tales',
      data: {
        'title': title,
        'image_url': 'https://example.test/dongeng.png',
        'audio_url': 'https://example.test/dongeng.mp3',
        'is_free': false,
        'duration': 300,
      },
      options: auth,
    );
    final dongengId = tale.data['data']['id'] as String;
    final product = await _dio.post(
      '/admin/products',
      data: {
        'feature_code': 'DONGENG',
        'price_idr': priceIdr,
        'dongeng_id': dongengId,
        'play_product_id': ?playProductId,
      },
      options: auth,
    );
    return (dongengId: dongengId, productId: product.data['data']['id'] as String);
  }

  /// Creates an AR card with a linked product, so the backend serves it
  /// locked until the viewing user has an entitlement or an active
  /// subscription — see ArService.applyUnlocked.
  Future<({String cardId, String productId})> seedPaidArCard({
    required String title,
    int priceIdr = 25000,
    // Google Play SKU selling the card; without one it can't be bought.
    String? playProductId,
  }) async {
    final auth = await _adminAuth();
    final shortCode = 'ITEST${DateTime.now().microsecondsSinceEpoch}';

    final card = await _dio.post(
      '/admin/content/ar-cards',
      data: {
        'title': title,
        'type': 'animal',
        'file_url': 'https://example.test/model.glb',
        'short_code': shortCode,
      },
      options: auth,
    );
    final cardId = card.data['data']['id'] as String;

    final product = await _dio.post(
      '/admin/products',
      data: {
        'feature_code': 'AR_CARD',
        'price_idr': priceIdr,
        'ar_card_id': cardId,
        'play_product_id': ?playProductId,
      },
      options: auth,
    );
    final productId = product.data['data']['id'] as String;

    return (cardId: cardId, productId: productId);
  }

  /// Sets the global promotional strike-price rule for [scope]
  /// (`AR_CARD`, `DONGENG` or `PACKAGE`) — what the backoffice's
  /// "Harga Coret" page sends. The rule is display-only: nothing charged
  /// changes.
  Future<void> setStrikeRule(
    String scope, {
    required String mode,
    required int value,
    required DateTime endsAt,
  }) async {
    await _dio.put(
      '/admin/strike-price-rules/$scope',
      data: {
        'mode': mode,
        'value': value,
        'starts_at': null,
        'ends_at': endsAt.toUtc().toIso8601String(),
      },
      options: await _adminAuth(),
    );
  }

  /// Flips an app feature flag — what the backoffice's App Features switch
  /// sends. The backend is shared, so a test that turns a flag on must turn it
  /// back off.
  Future<void> setFeatureFlag(String key, {required bool enabled}) async {
    await _dio.patch(
      '/admin/feature-flags/$key',
      data: {'is_enabled': enabled},
      options: await _adminAuth(),
    );
  }

  /// Turns [scope]'s strike-price rule back off. The backend is shared by
  /// every flow, so a test that sets a rule must clear it.
  Future<void> clearStrikeRule(String scope) async {
    await _dio.put(
      '/admin/strike-price-rules/$scope',
      data: {'mode': 'NONE', 'value': 0, 'starts_at': null, 'ends_at': null},
      options: await _adminAuth(),
    );
  }

  /// Grants a user blanket premium access — exactly what
  /// `PATCH /admin/users/:id/permission` does from the backoffice's
  /// "Grant Premium" button, used here to model a user who already owns
  /// paid content (via a prior purchase or an admin grant) rather than
  /// re-deriving a purchase through Google Play, which cannot run here.
  Future<void> grantPremium(String userId, {int durationDays = 30}) async {
    await _dio.patch(
      '/admin/users/$userId/permission',
      data: {'action': 'grant', 'duration_days': durationDays},
      options: await _adminAuth(),
    );
  }

  /// Publishes Belajar Huruf letter [upper] (a draft in the e2e seed) with
  /// the seeded test assets — the backoffice editor's "Simpan draft" then
  /// "Terbitkan". Letters are not free, so non-subscribers see it locked.
  Future<String> publishHurufLetter(
    String upper, {
    required String word,
  }) async {
    final auth = await _adminAuth();
    final list = await _dio.get('/admin/huruf/letters', options: auth);
    final id =
        (list.data['data'] as List).cast<Map<String, dynamic>>().firstWhere(
              (l) => l['upper'] == upper,
            )['id']
            as String;
    final draft = await _dio.get(
      '/admin/huruf/letters/$id/draft',
      options: auth,
    );
    await _dio.put(
      '/admin/huruf/letters/$id/draft',
      data: {
        'draft_rev': draft.data['data']['draft_rev'],
        'draft': {
          'kenali': {
            'word': word,
            'highlight': [0],
            // Seeded by db/seeds/test/seed.sql in arunika-backend.
            'image_asset_id': 'e2e0f000-0000-0000-0000-000000000001',
          },
          'dengar': {
            'letter_audio_id': 'e2e0f000-0000-0000-0000-000000000002',
            'word_audio_id': 'e2e0f000-0000-0000-0000-000000000003',
          },
          'tebalkan': {
            'lower_required': false,
            'upper': [
              {'order': 1, 'label': 'Garis tegak', 'path': 'M90 40 L90 260'},
            ],
            'lower': [],
          },
          'feedback': {
            'success': 'Keren! Huruf $upper rapi!',
            'retry': 'Belum pas, ayo lagi!',
            'hint': 'Mulai dari angka 1, lalu ikuti titik-titik sampai ujung.',
          },
        },
      },
      options: auth,
    );
    await _dio.post('/admin/huruf/letters/$id/publish', options: auth);
    return id;
  }

  /// Hides a letter again, so other flows see the seeded state.
  Future<void> hideHurufLetter(String id) async {
    await _dio.post(
      '/admin/huruf/letters/$id/hide',
      options: await _adminAuth(),
    );
  }
}

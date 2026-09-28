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

  /// Creates an AR card with a linked product, so the backend serves it
  /// locked until the viewing user has an entitlement or an active
  /// subscription — see ArService.applyUnlocked.
  Future<({String cardId, String productId})> seedPaidArCard({
    required String title,
    int priceIdr = 25000,
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
      },
      options: auth,
    );
    final productId = product.data['data']['id'] as String;

    return (cardId: cardId, productId: productId);
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
}

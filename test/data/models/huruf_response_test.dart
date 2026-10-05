import 'package:arunika_app/data/models/response/huruf_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveMediaUrl', () {
    const base = 'https://abc.ngrok-free.dev';

    test('resolves a relative path against the API host', () {
      expect(
        resolveMediaUrl('/media/huruf/x.png', base: base),
        'https://abc.ngrok-free.dev/media/huruf/x.png',
      );
    });

    test('keeps absolute URLs and empty values', () {
      expect(
        resolveMediaUrl(
          'https://media.haloarunika.com/huruf/x.png',
          base: base,
        ),
        'https://media.haloarunika.com/huruf/x.png',
      );
      expect(resolveMediaUrl(null, base: base), '');
      expect(resolveMediaUrl('', base: base), '');
    });
  });
}

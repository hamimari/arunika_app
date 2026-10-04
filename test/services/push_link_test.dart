import 'package:arunika_app/services/push_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a dongeng link', () {
    final link = PushLink.fromData({'link_type': 'dongeng', 'link_id': 'd-1'});
    expect(link.type, PushLinkType.dongeng);
    expect(link.id, 'd-1');
  });

  test('parses an AR card link', () {
    final link = PushLink.fromData({
      'link_type': 'ar_card',
      'link_id': 'card-1',
    });
    expect(link.type, PushLinkType.arCard);
  });

  test('missing id, none, or unknown type yields no link', () {
    expect(
      PushLink.fromData({'link_type': 'dongeng', 'link_id': ''}).isNone,
      isTrue,
    );
    expect(
      PushLink.fromData({'link_type': 'none', 'link_id': ''}).isNone,
      isTrue,
    );
    expect(
      PushLink.fromData({'link_type': 'badge', 'link_id': 'x'}).isNone,
      isTrue,
    );
    expect(PushLink.fromData({}).isNone, isTrue);
  });
}

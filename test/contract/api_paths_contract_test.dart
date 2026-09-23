import 'dart:io';

import 'package:arunika_app/constants/api_paths.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// Asserts every backend path this app calls is actually served by the
/// backend, by checking it against the vendored OpenAPI document.
///
/// This is the cheap half of contract testing, and it is the half that would
/// have caught the drift already present here: `ApiPaths.animals` and
/// `ApiPaths.dongengPopular` name routes `routes/router.go` does not serve.
/// Nothing reached them from the UI, so the breakage was latent — but nothing
/// would have caught the next one either.
///
/// test/contract/openapi.yaml is a copy published by arunika-backend. A
/// scheduled job opens a pull request when the upstream document changes, so
/// a stale copy shows up as a review item rather than as a silently passing
/// test.
///
/// Known limit: this compares paths, not semantics. `/fairy-tales/popular`
/// would pass here because the spec declares `/fairy-tales/{id}` and a router
/// happily binds `id = "popular"` — the request routes, it just does the
/// wrong thing. Catching that needs response validation against the operation
/// (tests/contract in the backend), not a path check. Path drift is the cheap
/// half; this is the cheap half.
void main() {
  late Set<String> specPaths;

  setUpAll(() {
    final file = File('test/contract/openapi.yaml');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'the vendored OpenAPI document is missing',
    );
    final doc = loadYaml(file.readAsStringSync()) as YamlMap;
    specPaths = (doc['paths'] as YamlMap).keys.map((k) => k as String).toSet();
  });

  /// Normalises an app path to the spec's shape: strips query strings, drops a
  /// trailing slash used for id concatenation, and replaces concrete path
  /// segments with the `{param}` placeholders the spec declares.
  String normalise(String path) {
    var p = path.split('?').first;
    if (p.endsWith('/')) p = p.substring(0, p.length - 1);
    return p;
  }

  /// Every path declared in lib/constants/api_paths.dart, read from the
  /// source rather than listed here by hand.
  ///
  /// Hand-listing is how this test fails at its own job: the first draft
  /// enumerated 31 of the 33 constants and happened to omit the two that are
  /// actually drifted, so it passed while proving nothing. Parsing the source
  /// makes the test exhaustive by construction — a new constant is covered
  /// the moment it is added.
  Map<String, String> appPaths() {
    final source = File('lib/constants/api_paths.dart').readAsStringSync();
    final paths = <String, String>{};

    // static const String name = "/path";
    final constants = RegExp(
      r'static\s+const\s+String\s+(\w+)\s*=\s*"([^"]+)"',
    );
    for (final m in constants.allMatches(source)) {
      paths[m.group(1)!] = m.group(2)!;
    }

    // static String name(String id) => "/path/$id";  — the interpolated
    // segment becomes a spec-style placeholder.
    final builders = RegExp(
      r'static\s+String\s+(\w+)\([^)]*\)\s*=>\s*"([^"]+)"',
    );
    for (final m in builders.allMatches(source)) {
      paths[m.group(1)!] = m.group(2)!.replaceAll(RegExp(r'\$\w+'), '{id}');
    }

    return paths;
  }

  /// A path matches if the spec declares it literally, or declares a
  /// parameterised form the app fills in — `/user/` + an id is `/user/{id}`.
  bool specServes(String appPath) {
    final p = normalise(appPath);
    if (specPaths.contains(p)) return true;

    final appSegments = p.split('/');
    for (final candidate in specPaths) {
      final specSegments = candidate.split('/');
      if (specSegments.length != appSegments.length) continue;

      var matches = true;
      for (var i = 0; i < specSegments.length; i++) {
        final spec = specSegments[i];
        if (spec.startsWith('{') && spec.endsWith('}')) continue;
        if (spec != appSegments[i]) {
          matches = false;
          break;
        }
      }
      if (matches) return true;
    }
    return false;
  }

  test('should_serve_every_path_the_app_calls', () {
    final unserved = <String, String>{};
    appPaths().forEach((name, path) {
      if (!specServes(path)) unserved[name] = path;
    });

    expect(
      unserved,
      isEmpty,
      reason:
          'these ApiPaths entries name routes the backend does not serve — '
          'either the route was removed, or the client was written against a '
          'path that never existed:\n'
          '${unserved.entries.map((e) => '  ApiPaths.${e.key} -> ${e.value}').join('\n')}',
    );
  });

  test('should_treat_a_parameterised_path_as_matching_its_spec_form', () {
    // Guards the matcher itself: without parameter handling this test would
    // pass vacuously by never matching anything.
    expect(specServes('/orders/{id}'), isTrue);
    expect(specServes('/definitely/not/a/route'), isFalse);
  });
}

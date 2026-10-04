import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

/// Host side of integration_test/perf/app_perf_test.dart: turns each traced
/// flow's timeline into a frame-timing summary under build/perf/.
Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    for (final entry in data.entries) {
      if (entry.key == 'memory_rss_mb') {
        await File('build/perf/memory_rss_mb.json').writeAsString(
          const JsonEncoder.withIndent('  ').convert(entry.value),
        );
        continue;
      }
      final timeline = driver.Timeline.fromJson(
        entry.value as Map<String, dynamic>,
      );
      await driver.TimelineSummary.summarize(timeline).writeTimelineToFile(
        entry.key,
        destinationDirectory: 'build/perf',
        pretty: true,
        includeSummary: true,
      );
    }
  },
);

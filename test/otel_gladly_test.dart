// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_gladly/otel_gladly.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_gladly-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('conversations.create records channel + topic + hero', () async {
    await tracedGladly<String>(
      operation: 'conversations.create',
      invoke: () async => const GladlyCallResult(
        value: 'ok',
        result: GladlyResult(
          channel: 'PHONE',
          conversationStatus: 'OPEN',
          topicId: 'top-1',
          inboxId: 'inb-1',
          agentAvailability: 'AVAILABLE',
          heroId: 'hero-1',
          statusCode: 201,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('gladly conversations.create')!);
    expect(a['gladly.channel'], 'PHONE');
    expect(a['gladly.topic.id'], 'top-1');
    expect(a['gladly.hero.id'], 'hero-1');
    expect(a['gladly.agent.availability'], 'AVAILABLE');
  });

  test('suppression skips spans', () async {
    await runWithoutGladlyInstrumentationAsync(() async {
      await tracedGladly<String>(
        operation: 'customers.list',
        invoke: () async => const GladlyCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('gladly '), isEmpty);
  });
}

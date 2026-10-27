// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_gladly/otel_gladly.dart';

/// Traces Gladly calls with OpenTelemetry.
///
/// `otel_gladly` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Gladly call in
/// [tracedGladly]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'gladly-example');

  // Wraps a Gladly REST API call in a CLIENT span.
  final gladlyId = await tracedGladly<String>(
    operation: 'customers.create',
    invoke: () async {
      // Make the Gladly call here, then report what it returned.
      const id = 'gladly_8f3a2c';
      return const GladlyCallResult(
          value: id,
          result: GladlyResult(
              itemCount: 3,
              channel: 'EMAIL',
              conversationStatus: 'OPEN',
              topicId: 'topic_8f3a2c',
              inboxId: 'inbox_8f3a2c',
              agentAvailability: 'AVAILABLE',
              heroId: 'hero_8f3a2c',
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedGladly customers.create returned $gladlyId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutGladlyInstrumentationAsync.
  await runWithoutGladlyInstrumentationAsync(
    () => tracedGladly<String>(
      operation: 'customers.create',
      invoke: () async {
        const id = 'gladly_8f3a2c';
        return const GladlyCallResult(
            value: id,
            result: GladlyResult(
                itemCount: 3,
                channel: 'EMAIL',
                conversationStatus: 'OPEN',
                topicId: 'topic_8f3a2c',
                inboxId: 'inbox_8f3a2c',
                agentAvailability: 'AVAILABLE',
                heroId: 'hero_8f3a2c',
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}

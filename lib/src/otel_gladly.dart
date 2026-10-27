// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_gladly_suppression.dart';

const _tracerName = 'dartastic_otel_libs_gladly';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class GladlyResult {
  /// Creates a result.
  const GladlyResult({
    this.itemCount,
    this.channel,
    this.conversationStatus,
    this.topicId,
    this.inboxId,
    this.agentAvailability,
    this.heroId,
    this.requestId,
    this.statusCode,
  });

  /// Items returned.
  final int? itemCount;

  /// `EMAIL` / `SMS` / `CHAT` / `FACEBOOK_MESSENGER` / `WHATSAPP` /
  /// `INSTAGRAM_DIRECT` / `TWITTER` / `PHONE` / `VOICEMAIL`.
  final String? channel;

  /// `OPEN` / `CLOSED` / `WAITING`.
  final String? conversationStatus;

  /// Topic id (Gladly's primary categorization — drives reports +
  /// SLAs).
  final String? topicId;

  /// Routing inbox id.
  final String? inboxId;

  /// `AVAILABLE` / `AWAY` / `BUSY` / `OFFLINE` for the calling agent.
  final String? agentAvailability;

  /// "Hero" (assigned-for-life agent) id — Gladly's signature feature.
  final String? heroId;

  /// `X-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class GladlyCallResult<T> {
  /// Creates a call result.
  const GladlyCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final GladlyResult? result;
}

/// Wraps a Gladly REST API call in a CLIENT span. [operation] is one
/// of `customers.list`, `customers.get`, `customers.create`,
/// `customers.update`, `customers.timeline.list`,
/// `conversations.list`, `conversations.get`, `conversations.create`,
/// `conversations.close`, `conversations.assign`,
/// `conversations.set_topic`, `topics.list`, `inboxes.list`,
/// `agents.list`, `agents.availability`, `webhooks.create`.
Future<T> tracedGladly<T>({
  required String operation,
  required Future<GladlyCallResult<T>> Function() invoke,
}) async {
  if (gladlyInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'gladly',
    'rpc.method': operation,
    'gladly.operation': operation,
  };

  final span = _tracer().startSpan(
    'gladly $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(OTelAPI.attributeInt(
          'gladly.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.channel != null) {
        extras.add(OTelAPI.attributeString(
          'gladly.channel',
          r.result!.channel!,
        ));
      }
      if (r.result!.conversationStatus != null) {
        extras.add(OTelAPI.attributeString(
          'gladly.conversation.status',
          r.result!.conversationStatus!,
        ));
      }
      if (r.result!.topicId != null) {
        extras.add(OTelAPI.attributeString(
          'gladly.topic.id',
          r.result!.topicId!,
        ));
      }
      if (r.result!.inboxId != null) {
        extras.add(OTelAPI.attributeString(
          'gladly.inbox.id',
          r.result!.inboxId!,
        ));
      }
      if (r.result!.agentAvailability != null) {
        extras.add(OTelAPI.attributeString(
          'gladly.agent.availability',
          r.result!.agentAvailability!,
        ));
      }
      if (r.result!.heroId != null) {
        extras.add(OTelAPI.attributeString(
          'gladly.hero.id',
          r.result!.heroId!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTelAPI.attributeString(
          'gladly.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Gladly HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

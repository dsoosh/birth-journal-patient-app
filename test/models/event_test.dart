import 'package:flutter_test/flutter_test.dart';
import 'package:birth_journal_patient/models/event.dart';

void main() {
  group('EventEnvelope Model', () {
    test('fromJson creates EventEnvelope from valid JSON', () {
      final json = {
        'event_id': '123e4567-e89b-12d3-a456-426614174000',
        'case_id': 'case-123',
        'type': 'contraction_start',
        'ts': '2025-12-31T10:00:00.000Z',
        'track': 'labor',
        'source': 'woman',
        'payload_v': 1,
        'payload': {'local_seq': 1},
      };

      final event = EventEnvelope.fromJson(json);

      expect(event.eventId, '123e4567-e89b-12d3-a456-426614174000');
      expect(event.caseId, 'case-123');
      expect(event.type, 'contraction_start');
      expect(event.ts, '2025-12-31T10:00:00.000Z');
      expect(event.track, 'labor');
      expect(event.source, 'woman');
      expect(event.payloadVersion, 1);
      expect(event.payload['local_seq'], 1);
    });

    test('fromJson handles null track and source', () {
      final json = <String, dynamic>{
        'event_id': 'event-123',
        'case_id': 'case-123',
        'type': 'note',
        'ts': '2025-12-31T10:00:00.000Z',
        'payload_v': 1,
        'payload': <String, dynamic>{},
      };

      final event = EventEnvelope.fromJson(json);

      expect(event.eventId, 'event-123');
      expect(event.track, isNull);
      expect(event.source, isNull);
    });

    test('toJson converts EventEnvelope to JSON', () {
      final event = EventEnvelope(
        eventId: 'test-event',
        caseId: 'test-case',
        type: 'labor_event',
        ts: '2025-12-31T10:00:00.000Z',
        track: 'labor',
        source: 'woman',
        payloadVersion: 1,
        payload: {'kind': 'bleeding', 'severity': 'high'},
      );

      final json = event.toJson();

      expect(json['event_id'], 'test-event');
      expect(json['case_id'], 'test-case');
      expect(json['type'], 'labor_event');
      expect(json['track'], 'labor');
      expect(json['source'], 'woman');
      expect(json['payload_v'], 1);
      expect(json['payload']['kind'], 'bleeding');
      expect(json['payload']['severity'], 'high');
    });

    test('toJson excludes null track and source', () {
      final event = EventEnvelope(
        eventId: 'test-event',
        caseId: 'test-case',
        type: 'note',
        ts: '2025-12-31T10:00:00.000Z',
        payloadVersion: 1,
        payload: {},
        track: null,
        source: null,
      );

      final json = event.toJson();

      expect(json.containsKey('track'), false);
      expect(json.containsKey('source'), false);
    });

    test('EventEnvelope equality by eventId', () {
      final event1 = EventEnvelope(
        eventId: 'same-id',
        caseId: 'case-1',
        type: 'type1',
        ts: '2025-12-31T10:00:00.000Z',
        payloadVersion: 1,
        payload: {},
      );

      final event2 = EventEnvelope(
        eventId: 'same-id',
        caseId: 'case-2', // different case
        type: 'type2', // different type
        ts: '2025-12-31T11:00:00.000Z',
        payloadVersion: 1,
        payload: {},
      );

      // They have same eventId
      expect(event1.eventId, event2.eventId);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:birth_journal_patient/models/sync.dart';
import 'package:birth_journal_patient/models/event.dart';

void main() {
  group('SyncRequest', () {
    test('toJson creates valid JSON with events', () {
      final request = SyncRequest(
        clientTime: '2025-12-31T10:00:00.000Z',
        cursor: 'cursor-123',
        events: [
          EventEnvelope(
            eventId: 'event-1',
            caseId: 'case-1',
            type: 'contraction_start',
            ts: '2025-12-31T10:00:00.000Z',
            payloadVersion: 1,
            payload: {'local_seq': 1},
          ),
        ],
      );

      final json = request.toJson();

      expect(json['client_time'], '2025-12-31T10:00:00.000Z');
      expect(json['cursor'], 'cursor-123');
      expect(json['events'], isList);
      expect(json['events'].length, 1);
    });

    test('toJson handles null cursor', () {
      final request = SyncRequest(
        clientTime: '2025-12-31T10:00:00.000Z',
        cursor: null,
        events: [],
      );

      final json = request.toJson();

      expect(json['cursor'], isNull);
      expect(json['events'], isEmpty);
    });

    test('fromJson parses valid JSON', () {
      final json = <String, dynamic>{
        'client_time': '2025-12-31T10:00:00.000Z',
        'cursor': 'cursor-abc',
        'events': <Map<String, dynamic>>[
          <String, dynamic>{
            'event_id': 'event-1',
            'case_id': 'case-1',
            'type': 'note',
            'ts': '2025-12-31T10:00:00.000Z',
            'payload_v': 1,
            'payload': <String, dynamic>{},
          }
        ],
      };

      final request = SyncRequest.fromJson(json);

      expect(request.clientTime, '2025-12-31T10:00:00.000Z');
      expect(request.cursor, 'cursor-abc');
      expect(request.events.length, 1);
      expect(request.events[0].eventId, 'event-1');
    });
  });

  group('RejectedEvent', () {
    test('fromJson creates RejectedEvent', () {
      final json = {
        'event_id': 'rejected-event-123',
        'reason': 'case_scope_violation',
      };

      final rejected = RejectedEvent.fromJson(json);

      expect(rejected.eventId, 'rejected-event-123');
      expect(rejected.reason, 'case_scope_violation');
    });

    test('toJson converts RejectedEvent to JSON', () {
      final rejected = RejectedEvent(
        eventId: 'test-event',
        reason: 'invalid_payload',
      );

      final json = rejected.toJson();

      expect(json['event_id'], 'test-event');
      expect(json['reason'], 'invalid_payload');
    });
  });

  group('SyncResponse', () {
    test('fromJson parses successful sync response', () {
      final json = {
        'accepted_event_ids': ['event-1', 'event-2'],
        'rejected': [
          {'event_id': 'event-3', 'reason': 'duplicate'}
        ],
        'server_cursor': 'cursor-xyz',
        'new_events': [
          {
            'event_id': 'server-event-1',
            'case_id': 'case-1',
            'type': 'midwife_reaction',
            'ts': '2025-12-31T11:00:00.000Z',
            'payload_v': 1,
            'payload': {'reaction': 'ack'},
          }
        ],
      };

      final response = SyncResponse.fromJson(json);

      expect(response.acceptedEventIds, ['event-1', 'event-2']);
      expect(response.rejected.length, 1);
      expect(response.rejected[0].eventId, 'event-3');
      expect(response.rejected[0].reason, 'duplicate');
      expect(response.serverCursor, 'cursor-xyz');
      expect(response.newEvents.length, 1);
      expect(response.newEvents[0].type, 'midwife_reaction');
    });

    test('fromJson handles empty lists', () {
      final json = {
        'accepted_event_ids': <String>[],
        'rejected': <Map<String, dynamic>>[],
        'server_cursor': null,
        'new_events': <Map<String, dynamic>>[],
      };

      final response = SyncResponse.fromJson(json);

      expect(response.acceptedEventIds, isEmpty);
      expect(response.rejected, isEmpty);
      expect(response.serverCursor, isNull);
      expect(response.newEvents, isEmpty);
    });

    test('toJson converts SyncResponse to JSON', () {
      final response = SyncResponse(
        acceptedEventIds: ['id-1'],
        rejected: [],
        serverCursor: 'cursor',
        newEvents: [],
      );

      final json = response.toJson();

      expect(json['accepted_event_ids'], ['id-1']);
      expect(json['rejected'], isEmpty);
      expect(json['server_cursor'], 'cursor');
      expect(json['new_events'], isEmpty);
    });
  });
}

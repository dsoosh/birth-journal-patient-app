import 'package:flutter_test/flutter_test.dart';
import 'package:birth_journal_patient/providers/events_provider.dart';

void main() {
  group('MidwifeFeedback', () {
    test('creates with required fields only', () {
      final feedback = MidwifeFeedback(
        originalEventId: 'event-123',
        originalEventType: 'labor_event',
        originalTs: DateTime.utc(2025, 12, 31, 10, 0, 0),
      );

      expect(feedback.originalEventId, 'event-123');
      expect(feedback.originalEventType, 'labor_event');
      expect(feedback.originalTs.year, 2025);
      expect(feedback.acknowledged, false);
      expect(feedback.resolved, false);
      expect(feedback.reaction, isNull);
    });

    test('creates with all fields', () {
      final feedback = MidwifeFeedback(
        originalEventId: 'event-456',
        originalEventType: 'postpartum_checkin',
        originalKind: 'bleeding',
        originalTs: DateTime.utc(2025, 12, 31, 10, 0, 0),
        acknowledged: true,
        resolved: true,
        acknowledgedAt: DateTime.utc(2025, 12, 31, 10, 5, 0),
        resolvedAt: DateTime.utc(2025, 12, 31, 10, 10, 0),
        reaction: 'coming',
        reactionAt: DateTime.utc(2025, 12, 31, 10, 3, 0),
      );

      expect(feedback.originalEventId, 'event-456');
      expect(feedback.originalKind, 'bleeding');
      expect(feedback.acknowledged, true);
      expect(feedback.resolved, true);
      expect(feedback.reaction, 'coming');
      expect(feedback.acknowledgedAt?.minute, 5);
      expect(feedback.resolvedAt?.minute, 10);
      expect(feedback.reactionAt?.minute, 3);
    });

    test('reaction types are valid', () {
      // Test all possible reaction types
      final reactions = ['ack', 'coming', 'ok', 'seen'];
      
      for (final reaction in reactions) {
        final feedback = MidwifeFeedback(
          originalEventId: 'test',
          originalEventType: 'labor_event',
          originalTs: DateTime.now(),
          reaction: reaction,
        );
        expect(feedback.reaction, reaction);
      }
    });

    test('originalTs is DateTime', () {
      final now = DateTime.now();
      final feedback = MidwifeFeedback(
        originalEventId: 'test',
        originalEventType: 'test',
        originalTs: now,
      );

      expect(feedback.originalTs, isA<DateTime>());
      expect(feedback.originalTs, now);
    });
  });
}

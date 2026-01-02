import 'package:flutter/foundation.dart';

import '../models/event.dart';
import '../services/api_client.dart';

/// Represents feedback from the midwife on a patient's reported event
class MidwifeFeedback {
  final String originalEventId;
  final String originalEventType;
  final String? originalKind;
  final DateTime originalTs;
  final bool acknowledged;
  final bool resolved;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final String? reaction; // 'ack', 'coming', 'ok', 'seen'
  final DateTime? reactionAt;

  MidwifeFeedback({
    required this.originalEventId,
    required this.originalEventType,
    this.originalKind,
    required this.originalTs,
    this.acknowledged = false,
    this.resolved = false,
    this.acknowledgedAt,
    this.resolvedAt,
    this.reaction,
    this.reactionAt,
  });
}

class EventsProvider extends ChangeNotifier {
  final ApiClient apiClient;

  List<EventEnvelope> _events = [];
  bool _isLoading = false;
  String? _error;

  EventsProvider({required this.apiClient});

  List<EventEnvelope> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get all labor_event and postpartum symptoms with their feedback status
  List<MidwifeFeedback> get feedbackItems {
    final List<MidwifeFeedback> items = [];

    // Find all patient-reported events (labor_event, postpartum_checkin, etc.)
    final patientEvents = _events
        .where(
          (e) =>
              e.type == 'labor_event' ||
              e.type == 'contraction_start' ||
              e.type == 'postpartum_checkin',
        )
        .toList();

    // Find all midwife reactions
    final reactionEvents = _events
        .where((e) => e.type == 'midwife_reaction')
        .toList();

    // Find all alert events and their ack/resolve status
    final alertEvents = _events
        .where((e) => e.type == 'alert_triggered')
        .toList();
    final ackEvents = _events.where((e) => e.type == 'alert_ack').toList();
    final resolveEvents = _events
        .where((e) => e.type == 'alert_resolve')
        .toList();

    // Build a map of alert_event_id -> status
    final Map<String, MidwifeFeedback> alertFeedback = {};

    for (final alert in alertEvents) {
      final alertEventId = alert.eventId;

      // Check if acknowledged
      final ack = ackEvents
          .where((e) => e.payload['alert_event_id'] == alertEventId)
          .firstOrNull;

      // Check if resolved
      final resolve = resolveEvents
          .where((e) => e.payload['alert_event_id'] == alertEventId)
          .firstOrNull;

      alertFeedback[alertEventId] = MidwifeFeedback(
        originalEventId: alertEventId,
        originalEventType: 'alert_triggered',
        originalKind: alert.payload['alert_code']?.toString(),
        originalTs: DateTime.parse(alert.ts),
        acknowledged: ack != null,
        resolved: resolve != null,
        acknowledgedAt: ack != null ? DateTime.tryParse(ack.ts) : null,
        resolvedAt: resolve != null ? DateTime.tryParse(resolve.ts) : null,
      );
    }

    // For labor events with high severity, check if there's a related alert or reaction
    for (final event in patientEvents) {
      final severity = event.payload['severity']?.toString();
      final kind = event.payload['kind']?.toString();

      // Check for midwife reaction to this event
      final reaction = reactionEvents
          .where((r) => r.payload['event_id'] == event.eventId)
          .firstOrNull;

      // Only high severity events trigger alerts
      if (severity == 'high') {
        // Find matching alert
        final matchingAlert = alertEvents.where((a) {
          final alertCode = a.payload['alert_code']?.toString() ?? '';
          // HEAVY_BLEEDING alert matches bleeding high severity event
          if (alertCode == 'HEAVY_BLEEDING' && kind == 'bleeding') return true;
          // Other high severity events may generate alerts
          return false;
        }).firstOrNull;

        if (matchingAlert != null &&
            alertFeedback.containsKey(matchingAlert.eventId)) {
          final feedback = alertFeedback[matchingAlert.eventId]!;
          items.add(
            MidwifeFeedback(
              originalEventId: event.eventId,
              originalEventType: event.type,
              originalKind: kind,
              originalTs: DateTime.parse(event.ts),
              acknowledged: feedback.acknowledged,
              resolved: feedback.resolved,
              acknowledgedAt: feedback.acknowledgedAt,
              resolvedAt: feedback.resolvedAt,
              reaction: reaction?.payload['reaction']?.toString(),
              reactionAt:
                  reaction != null ? DateTime.tryParse(reaction.ts) : null,
            ),
          );
        } else {
          // High severity but no alert yet - show as pending review
          items.add(
            MidwifeFeedback(
              originalEventId: event.eventId,
              originalEventType: event.type,
              originalKind: kind,
              originalTs: DateTime.parse(event.ts),
              reaction: reaction?.payload['reaction']?.toString(),
              reactionAt:
                  reaction != null ? DateTime.tryParse(reaction.ts) : null,
            ),
          );
        }
      } else if (reaction != null) {
        // Non-high severity event with a reaction
        items.add(
          MidwifeFeedback(
            originalEventId: event.eventId,
            originalEventType: event.type,
            originalKind: kind,
            originalTs: DateTime.parse(event.ts),
            reaction: reaction.payload['reaction']?.toString(),
            reactionAt: DateTime.tryParse(reaction.ts),
          ),
        );
      }
    }

    // Sort by timestamp descending (most recent first)
    items.sort((a, b) => b.originalTs.compareTo(a.originalTs));

    return items;
  }

  /// Get recent midwife notes directed at this case
  List<EventEnvelope> get midwifeNotes {
    return _events
        .where((e) => e.type == 'note' && e.source == 'midwife')
        .toList()
      ..sort((a, b) => DateTime.parse(b.ts).compareTo(DateTime.parse(a.ts)));
  }

  /// Get unread feedback count (acknowledged but not yet seen by patient)
  int get unreadFeedbackCount {
    return feedbackItems.where((f) => f.acknowledged || f.resolved).length;
  }

  Future<void> fetchEvents(String caseId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _events = await apiClient.listEvents(caseId: caseId, limit: 200);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add event from WebSocket
  void addEvent(EventEnvelope event) {
    // Avoid duplicates
    if (!_events.any((e) => e.eventId == event.eventId)) {
      _events.add(event);
      notifyListeners();
    }
  }

  void clear() {
    _events = [];
    notifyListeners();
  }
}

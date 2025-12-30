import 'package:json_annotation/json_annotation.dart';
import 'event.dart';

part 'sync.g.dart';

@JsonSerializable()
class SyncRequest {
  @JsonKey(name: 'client_time')
  final String clientTime;
  final String? cursor;
  final List<EventEnvelope> events;

  SyncRequest({required this.clientTime, this.cursor, required this.events});

  factory SyncRequest.fromJson(Map<String, dynamic> json) =>
      _$SyncRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SyncRequestToJson(this);
}

@JsonSerializable()
class RejectedEvent {
  @JsonKey(name: 'event_id')
  final String eventId;
  final String reason;

  RejectedEvent({required this.eventId, required this.reason});

  factory RejectedEvent.fromJson(Map<String, dynamic> json) =>
      _$RejectedEventFromJson(json);

  Map<String, dynamic> toJson() => _$RejectedEventToJson(this);
}

@JsonSerializable()
class SyncResponse {
  @JsonKey(name: 'accepted_event_ids')
  final List<String> acceptedEventIds;
  final List<RejectedEvent> rejected;
  @JsonKey(name: 'server_cursor')
  final String? serverCursor;
  @JsonKey(name: 'new_events')
  final List<EventEnvelope> newEvents;

  SyncResponse({
    required this.acceptedEventIds,
    required this.rejected,
    required this.serverCursor,
    required this.newEvents,
  });

  factory SyncResponse.fromJson(Map<String, dynamic> json) =>
      _$SyncResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SyncResponseToJson(this);
}

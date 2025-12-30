// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncRequest _$SyncRequestFromJson(Map<String, dynamic> json) => SyncRequest(
      clientTime: json['client_time'] as String,
      cursor: json['cursor'] as String?,
      events: (json['events'] as List<dynamic>)
          .map((e) => EventEnvelope.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SyncRequestToJson(SyncRequest instance) =>
    <String, dynamic>{
      'client_time': instance.clientTime,
      'cursor': instance.cursor,
      'events': instance.events,
    };

RejectedEvent _$RejectedEventFromJson(Map<String, dynamic> json) =>
    RejectedEvent(
      eventId: json['event_id'] as String,
      reason: json['reason'] as String,
    );

Map<String, dynamic> _$RejectedEventToJson(RejectedEvent instance) =>
    <String, dynamic>{
      'event_id': instance.eventId,
      'reason': instance.reason,
    };

SyncResponse _$SyncResponseFromJson(Map<String, dynamic> json) => SyncResponse(
      acceptedEventIds: (json['accepted_event_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      rejected: (json['rejected'] as List<dynamic>)
          .map((e) => RejectedEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      serverCursor: json['server_cursor'] as String?,
      newEvents: (json['new_events'] as List<dynamic>)
          .map((e) => EventEnvelope.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SyncResponseToJson(SyncResponse instance) =>
    <String, dynamic>{
      'accepted_event_ids': instance.acceptedEventIds,
      'rejected': instance.rejected,
      'server_cursor': instance.serverCursor,
      'new_events': instance.newEvents,
    };

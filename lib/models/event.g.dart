// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventEnvelope _$EventEnvelopeFromJson(Map<String, dynamic> json) =>
    EventEnvelope(
      eventId: json['event_id'] as String,
      caseId: json['case_id'] as String,
      type: json['type'] as String,
      ts: json['ts'] as String,
      payloadVersion: (json['payload_v'] as num).toInt(),
      payload: json['payload'] as Map<String, dynamic>,
      track: json['track'] as String?,
      source: json['source'] as String?,
    );

Map<String, dynamic> _$EventEnvelopeToJson(EventEnvelope instance) {
  final val = <String, dynamic>{
    'event_id': instance.eventId,
    'case_id': instance.caseId,
    'type': instance.type,
    'ts': instance.ts,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('track', instance.track);
  writeNotNull('source', instance.source);
  val['payload_v'] = instance.payloadVersion;
  val['payload'] = instance.payload;
  return val;
}

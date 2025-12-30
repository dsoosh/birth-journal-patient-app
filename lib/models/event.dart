import 'package:json_annotation/json_annotation.dart';

part 'event.g.dart';

@JsonSerializable()
class EventEnvelope {
  @JsonKey(name: 'event_id')
  final String eventId;
  @JsonKey(name: 'case_id')
  final String caseId;
  final String type;
  final String ts;
  @JsonKey(includeIfNull: false)
  final String? track;
  @JsonKey(includeIfNull: false)
  final String? source;
  @JsonKey(name: 'payload_v')
  final int payloadVersion;
  final Map<String, dynamic> payload;

  EventEnvelope({
    required this.eventId,
    required this.caseId,
    required this.type,
    required this.ts,
    required this.payloadVersion,
    required this.payload,
    this.track,
    this.source,
  });

  factory EventEnvelope.fromJson(Map<String, dynamic> json) =>
      _$EventEnvelopeFromJson(json);

  Map<String, dynamic> toJson() => _$EventEnvelopeToJson(this);
}

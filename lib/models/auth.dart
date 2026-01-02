import 'package:json_annotation/json_annotation.dart';

part 'auth.g.dart';

@JsonSerializable()
class JoinRequest {
  final String joinCode;

  JoinRequest({required this.joinCode});

  factory JoinRequest.fromJson(Map<String, dynamic> json) =>
      _$JoinRequestFromJson(json);

  Map<String, dynamic> toJson() => _$JoinRequestToJson(this);
}

@JsonSerializable()
class JoinResponse {
  final String token;
  @JsonKey(name: 'case_id')
  final String caseId;

  JoinResponse({required this.token, required this.caseId});

  factory JoinResponse.fromJson(Map<String, dynamic> json) =>
      _$JoinResponseFromJson(json);

  Map<String, dynamic> toJson() => _$JoinResponseToJson(this);
}

@JsonSerializable()
class InitiateResponse {
  @JsonKey(name: 'case_id')
  final String caseId;
  @JsonKey(name: 'join_code')
  final String joinCode;
  final String token;

  InitiateResponse({required this.caseId, required this.joinCode, required this.token});

  factory InitiateResponse.fromJson(Map<String, dynamic> json) =>
      _$InitiateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$InitiateResponseToJson(this);
}

@JsonSerializable()
class CaseStatus {
  @JsonKey(name: 'case_id')
  final String caseId;
  final String status;
  final bool claimed;
  @JsonKey(name: 'labor_active')
  final bool laborActive;
  @JsonKey(name: 'postpartum_active')
  final bool postpartumActive;
  @JsonKey(name: 'closed_at')
  final String? closedAt;

  CaseStatus({
    required this.caseId,
    required this.status,
    required this.claimed,
    this.laborActive = false,
    this.postpartumActive = false,
    this.closedAt,
  });

  factory CaseStatus.fromJson(Map<String, dynamic> json) =>
      _$CaseStatusFromJson(json);

  Map<String, dynamic> toJson() => _$CaseStatusToJson(this);
}

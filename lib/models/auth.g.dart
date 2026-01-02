// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JoinRequest _$JoinRequestFromJson(Map<String, dynamic> json) => JoinRequest(
      joinCode: json['joinCode'] as String,
    );

Map<String, dynamic> _$JoinRequestToJson(JoinRequest instance) =>
    <String, dynamic>{
      'joinCode': instance.joinCode,
    };

JoinResponse _$JoinResponseFromJson(Map<String, dynamic> json) => JoinResponse(
      token: json['token'] as String,
      caseId: json['case_id'] as String,
    );

Map<String, dynamic> _$JoinResponseToJson(JoinResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'case_id': instance.caseId,
    };

InitiateResponse _$InitiateResponseFromJson(Map<String, dynamic> json) =>
    InitiateResponse(
      caseId: json['case_id'] as String,
      joinCode: json['join_code'] as String,
      token: json['token'] as String,
    );

Map<String, dynamic> _$InitiateResponseToJson(InitiateResponse instance) =>
    <String, dynamic>{
      'case_id': instance.caseId,
      'join_code': instance.joinCode,
      'token': instance.token,
    };

CaseStatus _$CaseStatusFromJson(Map<String, dynamic> json) => CaseStatus(
      caseId: json['case_id'] as String,
      status: json['status'] as String,
      claimed: json['claimed'] as bool,
      laborActive: json['labor_active'] as bool? ?? false,
      postpartumActive: json['postpartum_active'] as bool? ?? false,
      closedAt: json['closed_at'] as String?,
    );

Map<String, dynamic> _$CaseStatusToJson(CaseStatus instance) =>
    <String, dynamic>{
      'case_id': instance.caseId,
      'status': instance.status,
      'claimed': instance.claimed,
      'labor_active': instance.laborActive,
      'postpartum_active': instance.postpartumActive,
      'closed_at': instance.closedAt,
    };

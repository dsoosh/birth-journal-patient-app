import 'dart:convert';

/// Represents a linked case in the patient app
class CaseInfo {
  final String caseId;
  final String token;
  final String? joinCode;
  final DateTime linkedAt;
  final bool isClosed;

  CaseInfo({
    required this.caseId,
    required this.token,
    this.joinCode,
    required this.linkedAt,
    this.isClosed = false,
  });

  CaseInfo copyWith({
    String? caseId,
    String? token,
    String? joinCode,
    DateTime? linkedAt,
    bool? isClosed,
  }) {
    return CaseInfo(
      caseId: caseId ?? this.caseId,
      token: token ?? this.token,
      joinCode: joinCode ?? this.joinCode,
      linkedAt: linkedAt ?? this.linkedAt,
      isClosed: isClosed ?? this.isClosed,
    );
  }

  Map<String, dynamic> toJson() => {
    'case_id': caseId,
    'token': token,
    'join_code': joinCode,
    'linked_at': linkedAt.toIso8601String(),
    'is_closed': isClosed,
  };

  factory CaseInfo.fromJson(Map<String, dynamic> json) => CaseInfo(
    caseId: json['case_id'] as String,
    token: json['token'] as String,
    joinCode: json['join_code'] as String?,
    linkedAt: DateTime.parse(json['linked_at'] as String),
    isClosed: json['is_closed'] as bool? ?? false,
  );

  /// Short display ID (first 8 chars)
  String get shortId => caseId.length > 8 ? caseId.substring(0, 8) : caseId;

  /// Encode list of cases to JSON string
  static String encodeList(List<CaseInfo> cases) =>
      jsonEncode(cases.map((c) => c.toJson()).toList());

  /// Decode JSON string to list of cases
  static List<CaseInfo> decodeList(String json) {
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => CaseInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

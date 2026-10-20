enum FindingStatus { low, normal, high, critical, unknown }

FindingStatus _statusFrom(dynamic v) {
  switch (v.toString().toLowerCase().trim()) {
    case 'low':
      return FindingStatus.low;
    case 'normal':
      return FindingStatus.normal;
    case 'high':
      return FindingStatus.high;
    case 'critical':
      return FindingStatus.critical;
    default:
      return FindingStatus.unknown;
  }
}

String _s(dynamic v) => v == null ? '' : v.toString().trim();

List<String> _list(dynamic v) =>
    v is List ? v.map(_s).where((e) => e.isNotEmpty).toList() : <String>[];

class Finding {
  const Finding({
    required this.test,
    required this.value,
    required this.unit,
    required this.referenceRange,
    required this.status,
    required this.explanation,
    required this.possibleCauses,
  });

  final String test;
  final String value;
  final String unit;
  final String referenceRange;
  final FindingStatus status;
  final String explanation;
  final List<String> possibleCauses;

  factory Finding.fromJson(Map<String, dynamic> j) => Finding(
    test: _s(j['test']),
    value: _s(j['value']),
    unit: _s(j['unit']),
    referenceRange: _s(j['reference_range']),
    status: _statusFrom(j['status']),
    explanation: _s(j['explanation']),
    possibleCauses: _list(j['possible_causes']),
  );

  Map<String, dynamic> toJson() => {
    'test': test,
    'value': value,
    'unit': unit,
    'reference_range': referenceRange,
    'status': status.name,
    'explanation': explanation,
    'possible_causes': possibleCauses,
  };
}

class ReportAnalysis {
  const ReportAnalysis({
    required this.reportType,
    required this.summary,
    required this.findings,
    required this.urgentFlags,
    required this.questionsForDoctor,
    required this.disclaimer,
  });

  final String reportType;
  final String summary;
  final List<Finding> findings;
  final List<String> urgentFlags;
  final List<String> questionsForDoctor;
  final String disclaimer;

  int get abnormalCount => findings
      .where(
        (f) =>
            f.status == FindingStatus.low ||
            f.status == FindingStatus.high ||
            f.status == FindingStatus.critical,
      )
      .length;

  factory ReportAnalysis.fromJson(Map<String, dynamic> j) => ReportAnalysis(
    reportType: _s(j['report_type']),
    summary: _s(j['summary']),
    findings: (j['findings'] is List)
        ? (j['findings'] as List)
              .whereType<Map>()
              .map((e) => Finding.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <Finding>[],
    urgentFlags: _list(j['urgent_flags']),
    questionsForDoctor: _list(j['questions_for_doctor']),
    disclaimer: _s(j['disclaimer']).isEmpty
        ? 'Informational only. This is not a medical diagnosis.'
        : _s(j['disclaimer']),
  );

  Map<String, dynamic> toJson() => {
    'report_type': reportType,
    'summary': summary,
    'findings': findings.map((f) => f.toJson()).toList(),
    'urgent_flags': urgentFlags,
    'questions_for_doctor': questionsForDoctor,
    'disclaimer': disclaimer,
  };
}

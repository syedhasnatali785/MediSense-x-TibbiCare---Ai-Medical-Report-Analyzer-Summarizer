import 'dart:convert';

import 'package:aimedicalreportanalyzer/models/report_analysis_m.dart';

class StoredReportModel {
  const StoredReportModel({
    required this.id,
    required this.createdAt,
    required this.reportType,
    required this.summary,
    required this.findingCount,
    required this.abnormalCount,
    required this.hasUrgent,
    required this.ocrText,
    required this.resultJson,
    this.imagePath,
  });

  final int id;
  final DateTime createdAt;
  final String reportType;
  final String summary;
  final int findingCount;
  final int abnormalCount;
  final bool hasUrgent;
  final String ocrText;
  final String resultJson;
  final String? imagePath;

  ReportAnalysis get analysis => ReportAnalysis.fromJson(
    Map<String, dynamic>.from(jsonDecode(resultJson) as Map),
  );

  factory StoredReportModel.fromRow(Map<String, Object?> r) =>
      StoredReportModel(
        id: r['id'] as int,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
        reportType: r['report_type'] as String,
        summary: r['summary'] as String,
        findingCount: r['finding_count'] as int,
        abnormalCount: r['abnormal_count'] as int,
        hasUrgent: (r['has_urgent'] as int) == 1,
        ocrText: r['ocr_text'] as String,
        resultJson: r['result_json'] as String,
        imagePath: r['image_path'] as String?,
      );
}

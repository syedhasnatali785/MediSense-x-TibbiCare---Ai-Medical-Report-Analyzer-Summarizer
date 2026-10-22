import 'dart:convert';

import 'package:aimedicalreportanalyzer/constants/app_config.dart';
import 'package:aimedicalreportanalyzer/models/report_analysis_m.dart';
import 'package:aimedicalreportanalyzer/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

/// Sends OCR text to the Cloudflare Worker and parses the JSON response.
class AnalysisApi {
  AnalysisApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<ReportAnalysis> analyze(String text) async {
    final user = await AuthRepository.instance.getCurrentUser();
    final patientContext = {
      'patient_name': user?.name ?? 'Unknown Patient',
      'age': '',
      'gender': '',
      'referred_by': '',
      'lab_name': 'MediSense AI Lab',
    };

    final systemPrompt = '''
You are a senior medical report analyst. Extract patient details and summarize the report in a clear clinical format.
Return valid JSON only.
Requirements:
- patient_name: patient full name if clearly present; otherwise use "Unknown Patient"
- age: age in years if found; else empty string
- gender: gender if found; else empty string
- referred_by: doctor or clinician name if found; else empty string
- lab_name: lab or facility name if found; else "MediSense AI Lab"
- report_type: one short label such as "CBC", "Lipid Panel", "Thyroid", "General Health Review", or "Medical Report"
- summary: a short plain-language summary of the findings
- overall_summary: concise assessment of the overall health state
- overall_status: one of "Good", "Needs attention", or "Urgent"
- total_rate: integer from 0 to 100 representing overall patient health score
- findings: list of medical tests with fields test, value, unit, reference_range, status, explanation, possible_causes
- urgent_flags: list of urgent findings and warnings
- questions_for_doctor: short questions a patient should ask the doctor
- disclaimer: short medical disclaimer
''';

    final response = await _client
        .post(
          Uri.parse(AppConfig.workerUrl),
          headers: {
            'Content-Type': 'application/json',
            if (AppConfig.appKey.isNotEmpty) 'x-app-key': AppConfig.appKey,
          },
          body: jsonEncode({
            'text': text,
            'system_prompt': systemPrompt,
            'patient_context': patientContext,
          }),
        )
        .timeout(const Duration(seconds: 60));

    final body = utf8.decode(response.bodyBytes);

    if (response.statusCode != 200) {
      var message = 'Server error (${response.statusCode}). Please try again.';
      try {
        final err = jsonDecode(body);
        if (err is Map && err['error'] is String) message = err['error'];
      } catch (_) {}
      throw ApiException(message, statusCode: response.statusCode);
    }

    try {
      return await compute(_decodeAnalysisPayload, body);
    } catch (_) {
      throw ApiException('The analysis could not be read. Please try again.');
    }
  }
}

ReportAnalysis _decodeAnalysisPayload(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map) {
    throw const FormatException('Missing analysis payload');
  }
  return ReportAnalysis.fromJson(Map<String, dynamic>.from(decoded));
}

import 'dart:convert';

import 'package:aimedicalreportanalyzer/constants/app_config.dart';
import 'package:aimedicalreportanalyzer/models/report_analysis_m.dart';
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
    final response = await _client
        .post(
          Uri.parse(AppConfig.workerUrl),
          headers: {
            'Content-Type': 'application/json',
            if (AppConfig.appKey.isNotEmpty) 'x-app-key': AppConfig.appKey,
          },
          body: jsonEncode({'text': text}),
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
      return ReportAnalysis.fromJson(
        Map<String, dynamic>.from(jsonDecode(body) as Map),
      );
    } catch (_) {
      throw ApiException('The analysis could not be read. Please try again.');
    }
  }
}

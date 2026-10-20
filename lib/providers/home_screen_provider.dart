import 'package:aimedicalreportanalyzer/providers/analysis_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MetricCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  const MetricCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });
}

class TrendCardData {
  final String title;
  final String value;
  final String unit;
  final String subtitle;
  final String state;
  final bool isNormal;
  final Color accent;

  const TrendCardData({
    required this.title,
    required this.value,
    required this.unit,
    required this.subtitle,
    required this.state,
    required this.isNormal,
    required this.accent,
  });
}

class ReportItemData {
  final String title;
  final String meta;
  final String tag;
  final bool archived;
  final bool summary;

  const ReportItemData({
    required this.title,
    required this.meta,
    required this.tag,
    required this.archived,
    required this.summary,
  });
}

class HomeScreenData {
  final String greeting;
  final String subtitle;
  final List<MetricCardData> summaryCards;
  final List<TrendCardData> trends;
  final List<ReportItemData> recentReports;

  const HomeScreenData({
    required this.greeting,
    required this.subtitle,
    required this.summaryCards,
    required this.trends,
    required this.recentReports,
  });
}

final homeScreenProvider = FutureProvider<HomeScreenData>((ref) async {
  final reports = await ref.read(reportRepositoryProvider).list();

  final recentReports = reports.take(3).map((report) {
    final title = report.reportType.isEmpty
        ? 'Medical report'
        : report.reportType;
    final meta =
        '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year} • ${report.findingCount} findings';
    final tag = report.hasUrgent
        ? 'Urgent'
        : report.abnormalCount > 0
        ? 'Review'
        : 'Normal';

    return ReportItemData(
      title: title,
      meta: meta,
      tag: tag,
      archived: false,
      summary: false,
    );
  }).toList();

  final totalReports = reports.length;
  final urgentCount = reports.where((report) => report.hasUrgent).length;
  final abnormalCount = reports
      .where((report) => report.abnormalCount > 0)
      .length;

  final trends = reports.isEmpty
      ? [
          const TrendCardData(
            title: 'No saved reports yet',
            value: '0',
            unit: '',
            subtitle: 'Scan a document to populate your dashboard.',
            state: 'Ready',
            isNormal: true,
            accent: Color(0xFF4CC0B1),
          ),
        ]
      : reports.take(3).map((report) {
          final state = report.hasUrgent
              ? 'Urgent'
              : report.abnormalCount > 0
              ? 'Review'
              : 'Normal';
          final accent = report.hasUrgent
              ? const Color(0xFFEF5350)
              : report.abnormalCount > 0
              ? const Color(0xFFE9B34A)
              : const Color(0xFF4CC0B1);

          return TrendCardData(
            title: report.reportType.isEmpty
                ? 'Medical report'
                : report.reportType,
            value: report.findingCount.toString(),
            unit: 'items',
            subtitle: report.summary.isEmpty
                ? 'No summary available yet.'
                : report.summary,
            state: state,
            isNormal: !report.hasUrgent && report.abnormalCount == 0,
            accent: accent,
          );
        }).toList();

  return HomeScreenData(
    greeting: 'Good morning, Sarah',
    subtitle: totalReports == 0
        ? 'Your health snapshot is empty until you scan a report.'
        : 'Your latest ${totalReports} report${totalReports == 1 ? '' : 's'} are ready.',
    summaryCards: [
      MetricCardData(
        label: 'Reports',
        value: totalReports.toString(),
        icon: Icons.insert_drive_file_outlined,
        iconBackground: const Color(0xFFEAF2FF),
        iconColor: const Color(0xFF5077E8),
      ),
      MetricCardData(
        label: 'Urgent',
        value: urgentCount.toString(),
        icon: Icons.warning_amber_rounded,
        iconBackground: const Color(0xFFFBE9EF),
        iconColor: const Color(0xFFE5687E),
      ),
      MetricCardData(
        label: 'Abnormal',
        value: abnormalCount.toString(),
        icon: Icons.auto_graph_rounded,
        iconBackground: const Color(0xFFE7F7EF),
        iconColor: const Color(0xFF1CA381),
      ),
    ],
    trends: trends,
    recentReports: recentReports,
  );
});

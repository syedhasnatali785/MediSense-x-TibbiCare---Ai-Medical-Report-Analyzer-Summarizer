import 'dart:io';

import 'package:aimedicalreportanalyzer/components/app_header.dart';
import 'package:aimedicalreportanalyzer/components/bottom_nav.dart';
import 'package:aimedicalreportanalyzer/components/metric_card.dart';
import 'package:aimedicalreportanalyzer/components/report_item.dart';
import 'package:aimedicalreportanalyzer/components/scan_hero_card.dart';
import 'package:aimedicalreportanalyzer/components/section_title.dart';
import 'package:aimedicalreportanalyzer/components/trend_card.dart';
import 'package:aimedicalreportanalyzer/providers/analysis_controller.dart';
import 'package:aimedicalreportanalyzer/providers/home_screen_provider.dart';
import 'package:aimedicalreportanalyzer/screens/history_screen.dart';
import 'package:aimedicalreportanalyzer/screens/live_scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'report_analysis_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _openScanner(BuildContext context, WidgetRef ref) async {
    final file = await Navigator.of(context).push<File>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const LiveScanScreen(),
      ),
    );
    if (file != null) {
      ref.read(analysisControllerProvider.notifier).analyzeFile(file);
    }
  }

  String _fmt(DateTime d) {
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year} • ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisControllerProvider);
    final controller = ref.read(analysisControllerProvider.notifier);
    final dashboardAsync = ref.watch(homeScreenProvider);
    final history = ref.watch(historyProvider);

    ref.listen<AnalysisState>(analysisControllerProvider, (prev, next) {
      if (prev?.stage != Stage.done &&
          next.stage == Stage.done &&
          next.result != null) {
        ref.invalidate(historyProvider);
        ref.invalidate(homeScreenProvider);
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) => ReportAnalysisScreen(
                  analysis: next.result!,
                  ocrText: next.ocrText,
                ),
              ),
            )
            .then((_) => controller.reset());
      } else if (prev?.stage != Stage.error && next.stage == Stage.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error ?? 'Something went wrong.')),
        );
      }
    });

    return dashboardAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF081B2E),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: const Color(0xFF081B2E),
        body: Center(
          child: Text(
            'Could not load dashboard data.',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
      data: (dashboard) {
        return Scaffold(
          backgroundColor: const Color.fromARGB(255, 139, 197, 255),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 15, 69, 123),
                  Color(0xFF102A3B),
                  Color(0xFF0B1C2B),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: AppHeader(
                      title: dashboard.greeting,
                      subtitle: dashboard.subtitle,
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      children: [
                        const _GlassCard(child: ScanHeroCard()),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            for (final item in dashboard.summaryCards)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _GlassCard(
                                    child: MetricCard(
                                      label: item.label,
                                      value: item.value,
                                      icon: item.icon,
                                      iconBackground: item.iconBackground,
                                      iconColor: item.iconColor,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const SectionTitle(
                          title: 'Health trend',
                          actionLabel: 'View all',
                        ),
                        const SizedBox(height: 12),
                        for (final trend in dashboard.trends)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _GlassCard(
                              child: TrendCard(
                                title: trend.title,
                                value: trend.value,
                                unit: trend.unit,
                                subtitle: trend.subtitle,
                                state: trend.state,
                                isNormal: trend.isNormal,
                                accent: trend.accent,
                              ),
                            ),
                          ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent scans',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const HistoryScreen(),
                                ),
                              ),
                              child: const Text('See all'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        history.when(
                          loading: () => const _GlassCard(
                            child: Padding(
                              padding: EdgeInsets.all(18),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          error: (_, _) => const _GlassCard(
                            child: Padding(
                              padding: EdgeInsets.all(18),
                              child: Text(
                                'Could not load recent scans.',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          data: (items) {
                            final recent = items.take(3).toList();
                            if (recent.isEmpty) {
                              return const _GlassCard(
                                child: Padding(
                                  padding: EdgeInsets.all(18),
                                  child: Text(
                                    'No saved reports yet. Scan a document to start.',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              );
                            }

                            return Column(
                              children: [
                                for (final item in recent)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _GlassCard(
                                      child: ReportItem(
                                        title: item.reportType,
                                        meta:
                                            '${_fmt(item.createdAt)} • ${item.findingCount} findings',
                                        tag: item.hasUrgent
                                            ? 'Urgent'
                                            : item.abnormalCount > 0
                                            ? 'Review'
                                            : 'Normal',
                                        archived: false,
                                        summary: false,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        if (state.isBusy) _ProgressCard(stage: state.stage),
                        const SizedBox(height: 18),
                        const Text(
                          'For information only. Not a diagnosis. Always consult a qualified doctor.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: const BottomNav(),
        );
      },
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 24,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.stage});
  final Stage stage;

  String get _label => switch (stage) {
    Stage.capturing => 'Opening camera...',
    Stage.ocr => 'Reading text from the image...',
    Stage.analyzing => 'Analyzing your report...',
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(_label, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

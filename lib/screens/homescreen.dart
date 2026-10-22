import 'dart:io';

import 'package:aimedicalreportanalyzer/components/app_header.dart';
import 'package:aimedicalreportanalyzer/components/metric_card.dart';
import 'package:aimedicalreportanalyzer/components/report_item.dart';
import 'package:aimedicalreportanalyzer/components/scan_hero_card.dart';
import 'package:aimedicalreportanalyzer/components/section_title.dart';
import 'package:aimedicalreportanalyzer/components/trend_card.dart';
import 'package:aimedicalreportanalyzer/providers/analysis_controller.dart';
import 'package:aimedicalreportanalyzer/providers/home_screen_provider.dart';
import 'package:aimedicalreportanalyzer/repositories/auth_repository.dart';
import 'package:aimedicalreportanalyzer/screens/auth_screen.dart';
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

  Future<void> _showProfileSheet(BuildContext context) async {
    final user = await AuthRepository.instance.getCurrentUser();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFF0D706C),
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(fontSize: 30, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.name ?? 'User',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? 'No email',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('My profile'),
              onTap: () => Navigator.pop(sheetContext),
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Logout'),
              onTap: () async {
                await AuthRepository.instance.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
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
        backgroundColor: Colors.white,
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
                  Color.fromARGB(255, 173, 200, 227),
                  Color.fromARGB(255, 255, 255, 255),
                  Color.fromARGB(255, 255, 255, 255),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: FutureBuilder<String>(
                      future: AuthRepository.instance
                          .getCurrentUser()
                          .then((user) => user?.name.split(' ').first ?? 'Friend'),
                      builder: (context, snapshot) {
                        final name = snapshot.data ?? 'Friend';
                        return AppHeader(
                          title: 'Good morning, $name',
                          subtitle: dashboard.subtitle,
                          onProfileTap: () => _showProfileSheet(context),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      children: [
                        _GlassCard(
                          child: ScanHeroCard(
                            onTap: state.isBusy
                                ? null
                                : () => _openScanner(context, ref),
                          ),
                        ),
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
                        if (state.isBusy) ...[
                          const SizedBox(height: 8),
                          _ProgressCard(stage: state.stage),
                        ],
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
        );
      },
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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


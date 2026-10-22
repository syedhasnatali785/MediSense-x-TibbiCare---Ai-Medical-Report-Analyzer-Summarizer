import 'package:aimedicalreportanalyzer/models/db_model.dart';
import 'package:aimedicalreportanalyzer/providers/analysis_controller.dart';
import 'package:aimedicalreportanalyzer/screens/report_analysis_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final historyProvider = FutureProvider.autoDispose<List<StoredReportModel>>((
  ref,
) async {
  final reports = await ref.read(reportRepositoryProvider).list();
  return reports;
});

String _fmt(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}  ${two(d.hour)}:${two(d.minute)}';
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            tooltip: 'Delete all',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete all reports?'),
                  content: const Text(
                    'This removes every saved analysis from this device.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await ref.read(reportRepositoryProvider).clear();
                ref.invalidate(historyProvider);
              }
            },
          ),
        ],
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(child: Text('Could not load history.')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No saved reports yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = items[i];
              return Dismissible(
                key: ValueKey(r.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline),
                ),
                onDismissed: (_) async {
                  await ref.read(reportRepositoryProvider).delete(r.id);
                  ref.invalidate(historyProvider);
                },
                child: Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(
                      r.hasUrgent
                          ? Icons.warning_amber_rounded
                          : r.abnormalCount > 0
                          ? Icons.info_outline
                          : Icons.check_circle_outline,
                      color: r.hasUrgent
                          ? Colors.red
                          : r.abnormalCount > 0
                          ? Colors.orange
                          : Colors.green,
                    ),
                    title: Text(r.reportType),
                    subtitle: Text(
                      '${_fmt(r.createdAt)}\n'
                      '${r.findingCount} tests, ${r.abnormalCount} outside range',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReportAnalysisScreen(
                          analysis: r.analysis,
                          ocrText: r.ocrText,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

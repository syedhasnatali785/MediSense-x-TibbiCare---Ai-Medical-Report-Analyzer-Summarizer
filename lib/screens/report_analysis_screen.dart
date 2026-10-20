import 'package:aimedicalreportanalyzer/models/report_analysis_m.dart';
import 'package:flutter/material.dart';

class ReportAnalysisScreen extends StatelessWidget {
  const ReportAnalysisScreen({super.key, required this.analysis, this.ocrText});

  final ReportAnalysis analysis;
  final String? ocrText;

  @override
  Widget build(BuildContext context) {
    final a = analysis;
    return Scaffold(
      appBar: AppBar(title: const Text('Report Analysis')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (a.urgentFlags.isNotEmpty) _UrgentBanner(flags: a.urgentFlags),
          _SummaryCard(analysis: a),
          if (a.findings.isNotEmpty) ...[
            const _SectionTitle('Findings'),
            for (final f in a.findings) _FindingCard(finding: f),
          ],
          if (a.questionsForDoctor.isNotEmpty) ...[
            const _SectionTitle('Questions to ask your doctor'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final q in a.questionsForDoctor)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.help_outline, size: 18),
                            const SizedBox(width: 10),
                            Expanded(child: Text(q)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (ocrText != null && ocrText!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Card(
              child: ExpansionTile(
                title: const Text('Extracted text (check for errors)'),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [SelectableText(ocrText!)],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            a.disclaimer,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _UrgentBanner extends StatelessWidget {
  const _UrgentBanner({required this.flags});
  final List<String> flags;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: scheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Needs attention',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: scheme.onErrorContainer),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final f in flags)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  f,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Please contact a doctor soon.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.analysis});
  final ReportAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final a = analysis;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (a.reportType.isNotEmpty)
              Text(
                a.reportType,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
            const SizedBox(height: 6),
            Text(a.summary.isEmpty ? 'No summary available.' : a.summary),
            if (a.findings.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${a.findings.length} tests read, ${a.abnormalCount} outside the normal range',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

({Color color, IconData icon, String label}) _style(FindingStatus s) {
  switch (s) {
    case FindingStatus.low:
      return (color: Colors.blue, icon: Icons.arrow_downward, label: 'Low');
    case FindingStatus.normal:
      return (
        color: Colors.green,
        icon: Icons.check_circle_outline,
        label: 'Normal',
      );
    case FindingStatus.high:
      return (color: Colors.orange, icon: Icons.arrow_upward, label: 'High');
    case FindingStatus.critical:
      return (
        color: Colors.red,
        icon: Icons.warning_amber_rounded,
        label: 'Critical',
      );
    case FindingStatus.unknown:
      return (color: Colors.grey, icon: Icons.help_outline, label: 'Unclear');
  }
}

class _FindingCard extends StatelessWidget {
  const _FindingCard({required this.finding});
  final Finding finding;

  @override
  Widget build(BuildContext context) {
    final f = finding;
    final st = _style(f.status);
    final theme = Theme.of(context);
    final valueText = [f.value, f.unit].where((e) => e.isNotEmpty).join(' ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: st.color.withAlpha(90)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(f.test, style: theme.textTheme.titleMedium),
                ),
                Chip(
                  avatar: Icon(st.icon, size: 16, color: st.color),
                  label: Text(st.label),
                  backgroundColor: st.color.withAlpha(30),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (valueText.isNotEmpty)
              Text(
                valueText,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: st.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (f.referenceRange.isNotEmpty)
              Text(
                'Reference: ${f.referenceRange}',
                style: theme.textTheme.bodySmall,
              ),
            if (f.explanation.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(f.explanation),
            ],
            if (f.possibleCauses.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in f.possibleCauses)
                    Chip(label: Text(c), visualDensity: VisualDensity.compact),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

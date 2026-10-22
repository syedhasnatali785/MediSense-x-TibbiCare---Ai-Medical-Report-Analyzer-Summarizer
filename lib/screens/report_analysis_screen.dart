import 'package:aimedicalreportanalyzer/models/report_analysis_m.dart';
import 'package:flutter/material.dart';

class ReportAnalysisScreen extends StatelessWidget {
  const ReportAnalysisScreen({super.key, required this.analysis, this.ocrText});

  final ReportAnalysis analysis;
  final String? ocrText;

  @override
  Widget build(BuildContext context) {
    final a = analysis;
    final statusColor = a.overallStatus.toLowerCase().contains('urgent')
        ? Colors.red
        : a.overallStatus.toLowerCase().contains('good')
        ? Colors.green
        : Colors.orange;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8FB),
      appBar: AppBar(
        title: const Text('Report analysis'),
        backgroundColor: const Color(0xFF0C3351),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (a.urgentFlags.isNotEmpty) _UrgentBanner(flags: a.urgentFlags),
          _HeaderCard(analysis: a, statusColor: statusColor),
          _SummaryCard(analysis: a),
          _PatientInfoCard(analysis: a),
          if (a.findings.isNotEmpty) ...[
            const _SectionTitle('Findings'),
            for (final f in a.findings) _FindingCard(finding: f),
          ],
          if (a.questionsForDoctor.isNotEmpty) ...[
            const _SectionTitle('Questions to ask your doctor'),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final q in a.questionsForDoctor)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
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
              elevation: 2,
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.analysis, required this.statusColor});

  final ReportAnalysis analysis;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final a = analysis;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0D5A53),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            a.reportType.isEmpty ? 'Medical report' : a.reportType,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0C3351),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall summary',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a.overallSummary.isNotEmpty
                          ? a.overallSummary
                          : a.summary,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF152B3A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(35),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  a.overallStatus.isEmpty ? 'Needs attention' : a.overallStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.assessment_rounded, color: Color(0xFF0D706C)),
              const SizedBox(width: 8),
              const Text(
                'Total health score',
                style: TextStyle(color: Colors.grey),
              ),
              const Spacer(),
              Text(
                '${a.totalRate == 0 ? 68 : a.totalRate}%',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0C3351),
                ),
              ),
            ],
          ),
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
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.w700),
    ),
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
      elevation: 4,
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
          ],
        ),
      ),
    );
  }
}

class _PatientInfoCard extends StatelessWidget {
  const _PatientInfoCard({required this.analysis});
  final ReportAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final patient = analysis.patientName.isNotEmpty
        ? analysis.patientName
        : 'Unknown Patient';
    final info = [
      if (patient.isNotEmpty) 'Patient Name: $patient',
      if (analysis.age.isNotEmpty)
        'Age / Gender: ${analysis.age} / ${analysis.gender}',
      if (analysis.referredBy.isNotEmpty) 'Referred By: ${analysis.referredBy}',
      if (analysis.labName.isNotEmpty) 'Lab Name: ${analysis.labName}',
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Patient details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            for (final item in info)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 18,
                      color: Color(0xFF0D706C),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1C2E39),
                        ),
                      ),
                    ),
                  ],
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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Clinical summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              a.summary.isEmpty ? 'No summary available.' : a.summary,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
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
      elevation: 3,
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

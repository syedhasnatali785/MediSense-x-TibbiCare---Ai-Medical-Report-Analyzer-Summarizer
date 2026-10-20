import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String actionLabel;

  const SectionTitle({
    super.key,
    required this.title,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2B36),
            ),
          ),
        ),
        Text(
          actionLabel,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1E7ED7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

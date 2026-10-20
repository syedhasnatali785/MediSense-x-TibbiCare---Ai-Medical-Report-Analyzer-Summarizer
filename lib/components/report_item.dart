import 'package:flutter/material.dart';

class ReportItem extends StatelessWidget {
  final String title;
  final String meta;
  final String tag;
  final bool archived;
  final bool summary;

  const ReportItem({
    super.key,
    required this.title,
    required this.meta,
    required this.tag,
    required this.archived,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1E2C3A),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: archived
                  ? const Color(0xFFE8F6F0)
                  : const Color(0xFFF5ECFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              archived ? Icons.archive_outlined : Icons.description_outlined,
              color: archived
                  ? const Color(0xFF0B8E74)
                  : const Color(0xFF7A4EC7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2B36),
                        ),
                      ),
                    ),
                    if (archived || summary)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: archived
                              ? const Color(0xFFE7F7EF)
                              : const Color(0xFFF4EBFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: archived
                                ? const Color(0xFF0F8C67)
                                : const Color(0xFF6F58CB),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  meta,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF67777D),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF6B7A82)),
        ],
      ),
    );
  }
}

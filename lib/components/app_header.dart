import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onProfileTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Row(
                children: [
                  Icon(Icons.add, size: 18, color: Color(0xFF2177F8)),
                  SizedBox(width: 8),
                  Text(
                    'MediSense AI',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF223B46),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.notifications_none_rounded,
              size: 28,
              color: Color(0xFF2D6A7A),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onProfileTap,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB8E0CF), Color(0xFFE9C59D)],
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A0D5A53),
                      blurRadius: 12,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person,
                  size: 22,
                  color: Color(0xFF1B2F3A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF183648),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF4A6772),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0A876F),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x220A876F),
                    blurRadius: 16,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ],
        ),
      ],
    );
  }
}

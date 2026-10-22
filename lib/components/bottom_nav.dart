import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      {'label': 'Home', 'icon': Icons.home_outlined},
      {'label': 'History', 'icon': Icons.history_rounded},
      {'label': 'Scan', 'icon': Icons.camera_alt_outlined},
      {'label': 'Profile', 'icon': Icons.person_outline_rounded},
    ];

    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A1E2C3A),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final bool selected = index == selectedIndex;

            return GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 74,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF0D6768) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: selected ? Colors.white : const Color(0xFF5D6771),
                      size: 26,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF5D6771),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

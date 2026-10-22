import 'package:aimedicalreportanalyzer/components/bottom_nav.dart';
import 'package:aimedicalreportanalyzer/repositories/auth_repository.dart';
import 'package:aimedicalreportanalyzer/screens/auth_screen.dart';
import 'package:aimedicalreportanalyzer/screens/history_screen.dart';
import 'package:aimedicalreportanalyzer/screens/homescreen.dart';
import 'package:aimedicalreportanalyzer/screens/live_scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

enum _ScanChoice { camera, gallery }

String _initialOf(String? name) => (name != null && name.trim().isNotEmpty)
    ? name.trim().substring(0, 1).toUpperCase()
    : 'U';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  // If HomeScreen/HistoryScreen don't have const constructors,
  // remove `const` here and in the list.
  static const List<Widget> _pages = [
    HomeScreen(),
    HistoryScreen(),
    _ReportsPlaceholder(),
    _ProfileScreen(),
  ];

  Future<void> _openScan() async {
    final choice = await showModalBottomSheet<_ScanChoice>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 18),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Open camera'),
              onTap: () => Navigator.pop(sheetContext, _ScanChoice.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, _ScanChoice.gallery),
            ),
          ],
        ),
      ),
    );

    if (choice == null || !mounted) return;

    if (choice == _ScanChoice.camera) {
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const LiveScanScreen()));
      return;
    }

    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    // TODO: LiveScanScreen currently ignores the picked image.
    // Add a parameter (e.g. `imagePath`) to it and pass `picked.path`:
    // LiveScanScreen(imagePath: picked.path)
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const LiveScanScreen()));
  }

  Future<void> _openProfileSheet() async {
    final user = await AuthRepository.instance.getCurrentUser();
    if (!mounted) return;

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
                _initialOf(user?.name),
                style: const TextStyle(fontSize: 30, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.name ?? 'User',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              user?.email ?? 'No email',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text('Profile'),
              onTap: () => Navigator.pop(sheetContext),
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Logout'),
              onTap: () async {
                await AuthRepository.instance.logout();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => AuthScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNav(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          if (index == 2) {
            _openScan();
            return;
          }
          if (index == 3) {
            _openProfileSheet();
            return;
          }
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}

class _ReportsPlaceholder extends StatelessWidget {
  const _ReportsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF081B2E),
      body: Center(
        child: Text(
          'Reports',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AuthRepository.instance.getCurrentUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Scaffold(
          backgroundColor: const Color(0xFF081B2E),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: const Color(0xFF0D706C),
                  child: Text(
                    _initialOf(user?.name),
                    style: const TextStyle(fontSize: 32, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  user?.name ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.email ?? 'No email',
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () async {
                    await AuthRepository.instance.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => AuthScreen()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D706C),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(180, 50),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

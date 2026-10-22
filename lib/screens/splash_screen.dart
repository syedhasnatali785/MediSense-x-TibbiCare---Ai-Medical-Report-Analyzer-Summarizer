import 'package:aimedicalreportanalyzer/repositories/auth_repository.dart';
import 'package:aimedicalreportanalyzer/screens/auth_screen.dart';
import 'package:aimedicalreportanalyzer/screens/main_shell.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final user = await AuthRepository.instance.getCurrentUser();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => user == null ? const AuthScreen() : const MainShell(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061A2A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.medical_services_rounded,
              size: 82,
              color: Color(0xFF74E0D4),
            ),
            SizedBox(height: 18),
            Text(
              'Medical AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 12),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF74E0D4)),
            ),
          ],
        ),
      ),
    );
  }
}

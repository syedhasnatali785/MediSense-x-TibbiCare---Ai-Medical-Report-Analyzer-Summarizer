import 'package:aimedicalreportanalyzer/repositories/auth_repository.dart';
import 'package:aimedicalreportanalyzer/screens/main_shell.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  final _loginEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();
  final _signupNameCtrl = TextEditingController();
  final _signupEmailCtrl = TextEditingController();
  final _signupPasswordCtrl = TextEditingController();

  bool _showLogin = true;
  bool _isSubmitting = false;

  Future<void> _submitLogin() async {
    if (!(_loginFormKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      await AuthRepository.instance.login(
        email: _loginEmailCtrl.text,
        password: _loginPasswordCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } on FormatException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Unable to sign in right now.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitSignup() async {
    if (!(_signupFormKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      await AuthRepository.instance.register(
        name: _signupNameCtrl.text,
        email: _signupEmailCtrl.text,
        password: _signupPasswordCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } on FormatException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Unable to create your account right now.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _signupNameCtrl.dispose();
    _signupEmailCtrl.dispose();
    _signupPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF0D706C);
    final bg = const Color(0xFF081B2E);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.medical_services_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Medical AI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _showLogin ? 'Welcome back' : 'Create account',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 34,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showLogin = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _showLogin
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Login',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _showLogin ? primary : Colors.white70,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showLogin = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _showLogin
                                ? Colors.transparent
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Sign up',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _showLogin ? Colors.white70 : primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_showLogin) _loginForm() else _signupForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loginForm() => Form(
    key: _loginFormKey,
    child: Column(
      children: [
        _InputField(
          controller: _loginEmailCtrl,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'Email is required'
              : null,
        ),
        const SizedBox(height: 16),
        _InputField(
          controller: _loginPasswordCtrl,
          label: 'Password',
          icon: Icons.lock_outline,
          obscureText: true,
          validator: (value) =>
              (value == null || value.isEmpty) ? 'Password is required' : null,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _submitLogin,
            icon: const Icon(Icons.login_rounded),
            label: Text(_isSubmitting ? 'Signing in...' : 'Login'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: const Color(0xFF0D706C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _signupForm() => Form(
    key: _signupFormKey,
    child: Column(
      children: [
        _InputField(
          controller: _signupNameCtrl,
          label: 'Full name',
          icon: Icons.person_outline,
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'Name is required'
              : null,
        ),
        const SizedBox(height: 16),
        _InputField(
          controller: _signupEmailCtrl,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'Email is required'
              : null,
        ),
        const SizedBox(height: 16),
        _InputField(
          controller: _signupPasswordCtrl,
          label: 'Password',
          icon: Icons.lock_outline,
          obscureText: true,
          validator: (value) => (value == null || value.length < 6)
              ? 'Use at least 6 characters'
              : null,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _submitSignup,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: Text(
              _isSubmitting ? 'Creating account...' : 'Create account',
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: const Color(0xFF1A9A93),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF74E0D4)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import '../../core/theme/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  /// Set to `true` when navigated here from RegisterScreen after a successful
  /// simulated registration. Triggers a one-time success Snackbar.
  final bool registrationSuccess;

  const LoginScreen({super.key, this.registrationSuccess = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Clear any stale error left from a previous auth attempt.
    Future.microtask(() {
      if (mounted) ref.read(authNotifierProvider.notifier).clearError();
    });

    // Show one-time registration success banner.
    if (widget.registrationSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Account created! Please sign in.'),
            ]),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Validators ─────────────────────────────────────────────────────

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final re =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!re.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    return null;
  }

  // ── Submit ──────────────────────────────────────────────────────────

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() != true) return;
    await ref.read(authNotifierProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
    // Navigation on success is handled entirely by the router guard —
    // this widget does NOT call context.go() on success.
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final errorMessage =
        authState.status == AuthStatus.error ? authState.errorMessage : null;

    // Refresh snackbar (e.g. if user was on login page with an existing token
    // that got silently refreshed during checkSession).
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next.sessionWasRefreshed && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_refreshSnackbar());
        ref.read(authNotifierProvider.notifier).clearRefreshFlag();
      }
    });

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(32, 56, 32, 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3), width: 1),
                      ),
                      child: const Icon(Icons.task_alt_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome back!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to your TaskFlow account',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Form card ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Email ──────────────────────────────────
                          AppTextField(
                            label: 'Email address',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => ref
                                .read(authNotifierProvider.notifier)
                                .clearError(),
                            validator: _validateEmail,
                            prefixIcon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 20),

                          // ── Password ────────────────────────────────
                          AppTextField(
                            label: 'Password',
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            onChanged: (_) => ref
                                .read(authNotifierProvider.notifier)
                                .clearError(),
                            validator: _validatePassword,
                            prefixIcon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              color: AppColors.textSecondary,
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── Auth error banner ────────────────────────
                          if (errorMessage != null) ...[
                            _ErrorBanner(message: errorMessage),
                            const SizedBox(height: 12),
                          ],

                          const SizedBox(height: 4),

                          // ── Sign In button ───────────────────────────
                          PrimaryButton(
                            text: 'Sign In',
                            onPressed: _submit,
                            isLoading: isLoading,
                          ),
                          const SizedBox(height: 24),

                          // ── Register link ────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Don't have an account?",
                                  style: TextStyle(color: cs.onSurfaceVariant)),
                              TextButton(
                                onPressed: () => context.go('/register'),
                                child: const Text(
                                  'Register',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Debug hint (test credentials) ─────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.amber.shade800),
                        const SizedBox(width: 6),
                        Text(
                          'Test Credentials',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      _credRow('Admin (Nimbus)', 'ava.admin@nimbusdigital.test'),
                      _credRow('Member (Nimbus)', 'marcus.member@nimbusdigital.test'),
                      _credRow('Member (Nimbus)', 'priya.member@nimbusdigital.test'),
                      _credRow('Admin (Harbor)', 'daniel.admin@harborlightstudios.test'),
                      _credRow('Member (Harbor)', 'elena.member@harborlightstudios.test'),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // ── Private helpers ─────────────────────────────────────────────────



  Widget _credRow(String label, String email) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: email),
            const TextSpan(
              text: '  /  Password123!',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  SnackBar _refreshSnackbar() => SnackBar(
        content: const Row(children: [
          Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Session refreshed'),
        ]),
        backgroundColor: Colors.indigo.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );
}

// ── Shared small widgets ──────────────────────────────────────────────



class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: Colors.red.shade600, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
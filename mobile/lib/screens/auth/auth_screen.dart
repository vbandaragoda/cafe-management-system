import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Login / Register screen — the app's primary data-input screen,
/// matching the Figma auth card: tab bar, styled email/password
/// fields, password-visibility toggle, primary Sign In button, and a
/// "Continue as Guest" link satisfying the guest-role requirement.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignIn = true;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = _isSignIn
        ? await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text)
        : await auth.register(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error!)));
    }
  }

  Future<void> _continueAsGuest() async {
    await context.read<AuthProvider>().continueAsGuest();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(18)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.local_cafe_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text('Welcome to Caffora', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to order ahead and track your cup',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildTabBar(theme, isDark),
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (!_isSignIn) ...[
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(labelText: 'Full name', hintText: 'Elena Woods'),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                            ),
                            const SizedBox(height: 14),
                          ],
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: 'Email', hintText: 'you@example.com'),
                            validator: (v) =>
                                (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: '••••••••',
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                          ),
                          if (_isSignIn)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: Text('Forgot?', style: TextStyle(color: theme.colorScheme.primary)),
                              ),
                            )
                          else
                            const SizedBox(height: 14),
                          const SizedBox(height: 6),
                          ElevatedButton(
                            onPressed: auth.isLoading ? null : _submit,
                            child: auth.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(_isSignIn ? 'Sign In' : 'Create Account'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(child: Divider(color: theme.colorScheme.outline)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('or', style: theme.textTheme.bodySmall),
                        ),
                        Expanded(child: Divider(color: theme.colorScheme.outline)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: _continueAsGuest,
                      child: Text(
                        'Continue as Guest',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutralTint : AppColors.lightSearchFill,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(child: _tabButton('Sign In', _isSignIn, theme, isDark)),
          Expanded(child: _tabButton('Register', !_isSignIn, theme, isDark)),
        ],
      ),
    );
  }

  Widget _tabButton(String label, bool active, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _isSignIn = label == 'Sign In'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? (isDark ? AppColors.darkAccentTint : AppColors.lightAccentTint) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
            color: active ? theme.colorScheme.primary : theme.textTheme.bodySmall?.color,
          ),
        ),
      ),
    );
  }
}

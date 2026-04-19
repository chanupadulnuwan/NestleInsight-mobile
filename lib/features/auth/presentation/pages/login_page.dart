import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/utils/form_validators.dart';
import 'package:mobile/features/auth/data/services/auth_service.dart';
import 'package:mobile/features/auth/presentation/pages/otp_verification_page.dart';
import 'package:mobile/features/auth/presentation/pages/signup_page.dart';
import 'package:mobile/features/auth/presentation/widgets/auth_page_shell.dart';
import 'package:mobile/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:mobile/features/distributor/presentation/pages/distributor_home_page.dart';
import 'package:mobile/features/home/presentation/pages/shop_owner_dashboard_page.dart';
import 'package:mobile/features/home/presentation/pages/dummy_home_page.dart';
import '../../../home/presentation/pages/sales_rep_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _openSignup() async {
    final identifier = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const SignupPage()),
    );

    if (!mounted || identifier == null || identifier.isEmpty) {
      return;
    }

    _identifierController.text = identifier;
    _showMessage('Account setup completed. You can sign in with this email.');
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    var shouldRetryLogin = false;

    try {
      final result = await _authService.login(
        identifier: _identifierController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => _buildHomePageForUser(result.user),
        ),
      );
    } on AuthServiceException catch (error) {
      if (!mounted) {
        return;
      }

      if (_requiresOtp(error)) {
        shouldRetryLogin = await _openOtpVerification();
      } else {
        _showMessage(error.message);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }

    if (shouldRetryLogin && mounted) {
      await _submit();
    }
  }

  Widget _buildHomePageForUser(Map<String, dynamic>? user) {
    final role = user?['role'] as String?;
    if (role == 'SHOP_OWNER') {
      return ShopOwnerDashboardPage(user: user);
    }
    if (role == 'TERRITORY_DISTRIBUTOR') {
      return DistributorHomePage(user: user);
    }
    if (role == 'SALES_REP') {
      return const SalesRepHomePage();
    }
    return DummyHomePage(user: user);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _requiresOtp(AuthServiceException error) {
    return error.code == 'OTP_REQUIRED' ||
        error.message.toLowerCase().contains('otp');
  }

  Future<bool> _openOtpVerification() async {
    final identifier = _identifierController.text.trim();

    if (identifier.isEmpty) {
      _showMessage('Enter your email, username, or phone number first.');
      return false;
    }

    final verified = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => OtpVerificationPage(identifier: identifier),
      ),
    );

    return verified ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AuthPageShell(
      title: 'Welcome back',
      header: Image.asset(
        'assets/images/logpage.png',
        height: 200,
        fit: BoxFit.contain,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surfaceTint,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.outlineWarm.withAlpha(140)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Public signup is available only for Shop Owner, Territory Distributor, and Sales Representative accounts.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            CustomTextField(
              labelText: 'Email/Username',
              hintText: 'Enter your email, username, or telephone number',
              controller: _identifierController,
              prefixIcon: const Icon(Icons.person_outline),
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  FormValidators.required(value, fieldName: 'Identifier'),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              labelText: 'Password',
              controller: _passwordController,
              obscureText: _obscurePassword,
              prefixIcon: const Icon(Icons.lock_outline),
              textInputAction: TextInputAction.done,
              validator: (value) =>
                  FormValidators.required(value, fieldName: 'Password'),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Log in',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSoft,
                    ),
                  ),
                  TextButton(
                    onPressed: _isSubmitting ? null : _openSignup,
                    child: const Text('Create an account'),
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

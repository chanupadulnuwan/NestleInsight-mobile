import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/services/auth_service.dart';
import 'package:mobile/features/auth/presentation/pages/login_page.dart';

class DummyHomePage extends StatelessWidget {
  DummyHomePage({super.key, this.user});

  final Map<String, dynamic>? user;
  final AuthService _authService = AuthService();

  String get _displayName {
    final firstName = user?['firstName'] as String?;
    final lastName = user?['lastName'] as String?;
    final fallbackName = user?['username'] as String? ?? 'User';

    final fullName = [
      firstName,
      lastName,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' ');

    return fullName.isEmpty ? fallbackName : fullName;
  }

  String get _roleLabel {
    return user?['role'] as String? ?? 'MOBILE_USER';
  }

  Future<void> _logout(BuildContext context) async {
    await _authService.logout();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nestle Insight'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFFFFCF8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/images/logpage.png',
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome, $_displayName',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppTheme.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This is the dummy home page for the new auth flow. Every successful login now lands here.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSoft,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceTint,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.outlineWarm.withAlpha(140),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Signed in role',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _roleLabel,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSoft,
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: () => _logout(context),
                            child: const Text('Log out'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

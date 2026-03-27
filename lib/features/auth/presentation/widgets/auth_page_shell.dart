import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

class AuthPageShell extends StatelessWidget {
  const AuthPageShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.header,
    this.appBar,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? header;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleText = subtitle?.trim();

    return Scaffold(
      appBar: appBar,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.white],
              ),
            ),
          ),
          const Positioned(
            top: -72,
            right: -48,
            child: _BackdropOrb(size: 220, color: Color(0xFFF2E2CF)),
          ),
          const Positioned(
            bottom: -92,
            left: -56,
            child: _BackdropOrb(size: 260, color: Color(0xFFF6EBDE)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (header != null) ...[
                        Center(child: header!),
                        const SizedBox(height: 20),
                      ],
                      Text(
                        title,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppTheme.textDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (subtitleText != null && subtitleText.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            subtitleText,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSoft,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withAlpha(190), color.withAlpha(0)],
          ),
        ),
      ),
    );
  }
}

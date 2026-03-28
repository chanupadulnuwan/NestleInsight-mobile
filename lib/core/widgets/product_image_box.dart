import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

class ProductImageBox extends StatelessWidget {
  const ProductImageBox({
    super.key,
    required this.imageSource,
    required this.fallbackLabel,
    this.fit = BoxFit.contain,
  });

  final String? imageSource;
  final String fallbackLabel;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final normalized = imageSource?.trim() ?? '';
    if (normalized.isEmpty) {
      return _FallbackLabel(label: fallbackLabel);
    }

    if (normalized.startsWith('assets/')) {
      return Image.asset(
        normalized,
        fit: fit,
        errorBuilder: (_, _, _) => _FallbackLabel(label: fallbackLabel),
      );
    }

    return Image.network(
      normalized,
      fit: fit,
      errorBuilder: (_, _, _) => _FallbackLabel(label: fallbackLabel),
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }

        return const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }
}

class _FallbackLabel extends StatelessWidget {
  const _FallbackLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.primaryBrownDark,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

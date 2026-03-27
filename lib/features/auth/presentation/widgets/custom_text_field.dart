import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.labelText,
    required this.controller,
    this.hintText,
    this.helperText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.readOnly = false,
    this.enabled = true,
    this.onTap,
    this.textInputAction,
    this.validator,
    this.onChanged,
  });

  final String labelText;
  final String? hintText;
  final String? helperText;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int maxLines;
  final bool readOnly;
  final bool enabled;
  final VoidCallback? onTap;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: obscureText ? 1 : maxLines,
      readOnly: readOnly,
      enabled: enabled,
      onTap: onTap,
      onChanged: onChanged,
      validator: validator,
      textInputAction: textInputAction,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

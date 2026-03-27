import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/utils/form_validators.dart';
import 'package:mobile/features/auth/data/services/auth_service.dart';
import 'package:mobile/features/auth/presentation/widgets/custom_text_field.dart';

class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key, this.authService});

  final AuthService? authService;

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final AuthService _authService;
  bool _isSaving = false;
  bool _hideCurrentPassword = true;
  bool _hideNewPassword = true;
  bool _hideConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final message = await _authService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmNewPassword: _confirmPasswordController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(message);
    } on AuthServiceException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          top: 12,
          right: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 56,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppTheme.outlineWarm,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Security',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your current password and confirm the new password.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSoft,
                    ),
                  ),
                  const SizedBox(height: 18),
                  CustomTextField(
                    labelText: 'Current password',
                    controller: _currentPasswordController,
                    obscureText: _hideCurrentPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    validator: (value) =>
                        FormValidators.required(value, fieldName: 'Current password'),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _hideCurrentPassword = !_hideCurrentPassword;
                        });
                      },
                      icon: Icon(
                        _hideCurrentPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    labelText: 'New password',
                    controller: _newPasswordController,
                    obscureText: _hideNewPassword,
                    prefixIcon: const Icon(Icons.password_outlined),
                    validator: FormValidators.password,
                    helperText:
                        'Use at least 8 characters with uppercase, lowercase, and a number.',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _hideNewPassword = !_hideNewPassword;
                        });
                      },
                      icon: Icon(
                        _hideNewPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    labelText: 'Confirm new password',
                    controller: _confirmPasswordController,
                    obscureText: _hideConfirmPassword,
                    prefixIcon: const Icon(Icons.verified_user_outlined),
                    validator: (value) => FormValidators.confirmPassword(
                      value,
                      password: _newPasswordController.text,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _hideConfirmPassword = !_hideConfirmPassword;
                        });
                      },
                      icon: Icon(
                        _hideConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isSaving ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.securitySlate,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.1,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Save password'),
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mobile/core/services/otp_service.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/presentation/pages/pending_approval_screen.dart';
import 'package:mobile/features/auth/presentation/widgets/auth_page_shell.dart';
import 'package:mobile/features/auth/presentation/widgets/custom_text_field.dart';

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({
    super.key,
    required this.identifier,
    this.initialDebugOtpCode,
    this.initialOtpDeliveryMethod,
    this.title = 'Verify OTP',
    this.subtitle,
    // When true, a successful OTP verification navigates to
    // PendingApprovalScreen instead of popping with `true`.
    this.requiresApproval = false,
  });

  final String identifier;
  final String? initialDebugOtpCode;
  final String? initialOtpDeliveryMethod;
  final String title;
  final String? subtitle;

  /// Set to true for SALES_REP and other roles that need admin approval
  /// after OTP verification.  The [identifier] (email) is passed to
  /// [PendingApprovalScreen] for its polling loop.
  final bool requiresApproval;

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _otpController = TextEditingController();
  final _otpService = OtpService();

  bool _isSubmitting = false;
  bool _isResending = false;
  String? _debugOtpCode;
  String? _otpDeliveryMethod;

  @override
  void initState() {
    super.initState();
    _debugOtpCode = widget.initialDebugOtpCode;
    _otpDeliveryMethod = widget.initialOtpDeliveryMethod;
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showMessage('Enter the 6-digit OTP.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await _otpService.verifyOtp(
        identifier: widget.identifier,
        otp: otp,
      );

      if (!mounted) {
        return;
      }

      _showMessage(result.message);

      if (widget.requiresApproval) {
        // For roles that need admin approval, land on the polling screen
        // instead of returning control to SignupPage.
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) =>
                PendingApprovalScreen(email: widget.identifier),
          ),
        );
      } else {
        Navigator.of(context).pop(true);
      }
    } on OtpServiceException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
    });

    try {
      final result = await _otpService.resendOtp(identifier: widget.identifier);

      if (!mounted) {
        return;
      }

      setState(() {
        _debugOtpCode = result.debugOtpCode;
        _otpDeliveryMethod = result.otpDeliveryMethod ?? _otpDeliveryMethod;
      });
      _showMessage(result.message);
    } on OtpServiceException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildNoticeCard({required IconData icon, required String message}) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTint,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outlineWarm.withAlpha(140)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryBrownDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _otpHelpMessage {
    if (_otpDeliveryMethod == 'debug' || _debugOtpCode != null) {
      return 'This backend is using a development OTP for now. Use the code shown below, or configure SMTP on the backend to send OTPs to email.';
    }

    return 'We sent a 6-digit OTP to ${widget.identifier}. Check your email inbox and enter the code here. If it does not arrive, tap Resend OTP.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthPageShell(
      title: widget.title,
      subtitle:
          widget.subtitle ??
          'Enter the 6-digit code for ${widget.identifier} to activate your account.',
      header: Image.asset(
        'assets/images/logpage.png',
        height: 160,
        fit: BoxFit.contain,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildNoticeCard(
            icon: Icons.sms_outlined,
            message: _otpHelpMessage,
          ),
          if (_debugOtpCode != null && _debugOtpCode!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildNoticeCard(
              icon: Icons.key_outlined,
              message: 'Development OTP: $_debugOtpCode',
            ),
          ],
          const SizedBox(height: 24),
          CustomTextField(
            labelText: 'OTP code',
            hintText: 'Enter 6 digits',
            controller: _otpController,
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.lock_clock_outlined),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSubmitting ? null : _verifyOtp,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Verify OTP',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: _isResending ? null : _resendOtp,
            child: _isResending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Text('Resend OTP'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }
}

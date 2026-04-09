import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/services/auth_service.dart';

/// Shown after OTP verification for roles that require admin approval
/// (e.g. SALES_REP, TERRITORY_DISTRIBUTOR).
///
/// Polls GET /auth/status?email= every 10 seconds and automatically
/// transitions to the Approved or Rejected view when the admin acts.
/// The back button is disabled — the user must wait for a decision.
///
/// Usage (navigate from OtpVerificationPage after verification):
/// ```dart
/// Navigator.of(context).pushReplacement(
///   MaterialPageRoute(builder: (_) => PendingApprovalScreen(email: email)),
/// );
/// ```
class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key, required this.email});

  final String email;

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen>
    with TickerProviderStateMixin {
  final _authService = AuthService();

  Timer? _pollTimer;
  _ScreenState _screenState = _ScreenState.pending;
  String? _rejectionReason;
  String? _errorMessage;
  bool _isPolling = false;

  // Pulse animation for the pending state ring.
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // Slide-in animation for state transitions.
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _slideController.forward();

    // First poll immediately, then every 10 seconds.
    _poll();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _poll() async {
    if (_isPolling || !mounted) return;
    if (_screenState != _ScreenState.pending) return;

    setState(() {
      _isPolling = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.getAccountStatus(email: widget.email);

      if (!mounted) return;

      if (result.isApproved) {
        _pollTimer?.cancel();
        setState(() {
          _screenState = _ScreenState.approved;
          _isPolling = false;
        });
        _slideController
          ..reset()
          ..forward();
        return;
      }

      if (result.isRejected) {
        _pollTimer?.cancel();
        setState(() {
          _screenState = _ScreenState.rejected;
          _rejectionReason = result.rejectionReason;
          _isPolling = false;
        });
        _slideController
          ..reset()
          ..forward();
        return;
      }
    } on AuthServiceException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Network issue — will retry shortly.');
    } finally {
      if (mounted) setState(() => _isPolling = false);
    }
  }

  void _goToLogin() {
    // Pop all routes back to the login page.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent accidental back navigation while waiting.
      canPop: _screenState != _ScreenState.pending,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF9F5),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildBody(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_screenState) {
      case _ScreenState.pending:
        return _buildPendingView(context);
      case _ScreenState.approved:
        return _buildApprovedView(context);
      case _ScreenState.rejected:
        return _buildRejectedView(context);
    }
  }

  // ── Pending View ────────────────────────────────────────────────────────────

  Widget _buildPendingView(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Pulsing ring animation.
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFF3DC),
              border: Border.all(color: const Color(0xFFE8C97A), width: 2.5),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFFE8C97A).withAlpha(80),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              size: 52,
              color: Color(0xFFB88B2A),
            ),
          ),
        ),

        const SizedBox(height: 32),

        Text(
          'Waiting for approval',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 14),

        Text(
          'Your account has been verified. An administrator will review your registration and approve or reject it shortly.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSoft,
            height: 1.65,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 10),

        Text(
          widget.email,
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFFB88B2A),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 28),

        // Live polling indicator.
        _buildPollingRow(),

        if (_errorMessage != null) ...<Widget>[
          const SizedBox(height: 16),
          _buildErrorCard(_errorMessage!),
        ],

        const SizedBox(height: 28),

        _buildInfoCard(
          icon: Icons.info_outline_rounded,
          message:
              'You can close this screen and come back later — your email was saved. You will need to log in once approved.',
        ),
      ],
    );
  }

  Widget _buildPollingRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (_isPolling) ...<Widget>[
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB88B2A)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Checking…',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
        ] else ...<Widget>[
          const Icon(Icons.sync_rounded, size: 16, color: Color(0xFFB88B2A)),
          const SizedBox(width: 6),
          Text(
            'Auto-refreshes every 10 seconds',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSoft,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  // ── Approved View ────────────────────────────────────────────────────────────

  Widget _buildApprovedView(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFECF8E5),
            border: Border.all(color: const Color(0xFF8CB53A), width: 2.5),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF8CB53A).withAlpha(60),
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            size: 56,
            color: Color(0xFF4D7A1E),
          ),
        ),

        const SizedBox(height: 32),

        Text(
          'Account approved! 🎉',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2D5A0D),
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 14),

        Text(
          'Your registration has been approved. You can now log in to the Nestle Insight mobile app.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSoft,
            height: 1.65,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 36),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _goToLogin,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6FA132),
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Go to login',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  // ── Rejected View ────────────────────────────────────────────────────────────

  Widget _buildRejectedView(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFF0EE),
            border: Border.all(color: const Color(0xFFE08D8D), width: 2.5),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFFE08D8D).withAlpha(60),
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.cancel_outlined,
            size: 56,
            color: Color(0xFFAA3535),
          ),
        ),

        const SizedBox(height: 32),

        Text(
          'Registration rejected',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF8B2020),
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 14),

        Text(
          'Unfortunately, your registration was not approved. Please contact support if you believe this is an error.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSoft,
            height: 1.65,
          ),
          textAlign: TextAlign.center,
        ),

        if (_rejectionReason != null &&
            _rejectionReason!.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEBD5CF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Reason provided',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8B2020),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _rejectionReason!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF7B514A),
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 36),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _goToLogin,
            child: const Text(
              'Back to login',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // ── Shared helpers ───────────────────────────────────────────────────────────

  Widget _buildInfoCard({required IconData icon, required String message}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineWarm.withAlpha(140)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: AppTheme.primaryBrownDark, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w500,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8C5BF)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.wifi_off_rounded,
            size: 18,
            color: Color(0xFFB94040),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFFB94040),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ScreenState { pending, approved, rejected }

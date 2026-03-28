import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/features/activity/data/services/activity_feed_service.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/activity/presentation/widgets/feedback_sheet.dart';
import 'package:mobile/features/auth/data/services/auth_service.dart';
import 'package:mobile/features/auth/presentation/pages/login_page.dart';
import 'package:mobile/features/home/presentation/controllers/shop_owner_dashboard_controller.dart';
import 'package:mobile/features/home/presentation/widgets/shop_owner_home_tab.dart';
import 'package:mobile/features/home/presentation/widgets/shop_owner_secondary_tabs.dart';
import 'package:mobile/features/orders/data/services/order_service.dart';
import 'package:mobile/features/orders/domain/shop_order.dart';
import 'package:mobile/features/orders/presentation/widgets/cart_side_sheet.dart';
import 'package:mobile/features/orders/presentation/widgets/order_summary_sheet.dart';
import 'package:mobile/features/profile/domain/shop_owner_profile.dart';
import 'package:mobile/features/profile/presentation/widgets/shop_owner_profile_sheet.dart';
import 'package:mobile/features/settings/presentation/widgets/change_password_sheet.dart';

class ShopOwnerDashboardPage extends StatefulWidget {
  const ShopOwnerDashboardPage({super.key, this.user});

  final Map<String, dynamic>? user;

  @override
  State<ShopOwnerDashboardPage> createState() => _ShopOwnerDashboardPageState();
}

class _ShopOwnerDashboardPageState extends State<ShopOwnerDashboardPage> {
  final AuthService _authService = AuthService();
  final ShopOwnerDashboardController _dashboardController =
      ShopOwnerDashboardController();

  late ShopOwnerProfile _profile;
  late DateTime _currentTime;
  Timer? _greetingTimer;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _profile = ShopOwnerProfile.fromJson(widget.user);
    _currentTime = DateTime.now();

    _greetingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _currentTime = DateTime.now();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dashboardController.loadCatalog();
      _dashboardController.loadOrders();
      _dashboardController.loadActivities();
    });
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    _dashboardController.dispose();
    super.dispose();
  }

  String get _greetingText {
    final hour = _currentTime.hour;
    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  Future<void> _logout() async {
    await _authService.logout();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _openProfileSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShopOwnerProfileSheet(
        initialProfile: _profile,
        onProfileSaved: (profile) {
          if (!mounted) {
            return;
          }

          setState(() {
            _profile = profile;
          });
        },
        onLogoutRequested: _logout,
      ),
    );
  }

  Future<void> _openChangePasswordSheet() async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChangePasswordSheet(),
    );

    if (!mounted || message == null || message.isEmpty) {
      return;
    }

    _showMessage(message);
    _dashboardController.loadActivities();
  }

  Future<void> _openFeedbackSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AnimatedBuilder(
          animation: _dashboardController,
          builder: (context, child) {
            return FeedbackSheet(
              isSubmitting: _dashboardController.isSubmittingFeedback,
              onSubmit: (message) async {
                try {
                  final resultMessage = await _dashboardController
                      .submitFeedback(message);

                  if (!mounted || !context.mounted) {
                    return;
                  }

                  Navigator.of(context).pop();
                  _showMessage(resultMessage);
                } on ActivityFeedServiceException catch (error) {
                  if (!mounted) {
                    return;
                  }

                  _showMessage(error.message);
                }
              },
            );
          },
        );
      },
    );
  }

  Future<void> _openOrderSummary() async {
    if (!_dashboardController.hasCartItems) {
      _showMessage('Add at least one product to the cart first.');
      return;
    }

    final isTablet = MediaQuery.of(context).size.width >= 700;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AnimatedBuilder(
          animation: _dashboardController,
          builder: (_, _) {
            return OrderSummarySheet(
              items: _dashboardController.cartItems,
              isTablet: isTablet,
              isSubmitting: _dashboardController.isPlacingOrder,
              onConfirm: () async {
                try {
                  final order = await _dashboardController.placeCurrentOrder();

                  if (!mounted || !sheetContext.mounted) {
                    return;
                  }

                  Navigator.of(sheetContext).pop();
                  _showMessage('Order placed successfully.');
                  await _showOrderPlacedDialog(order);
                } on OrderServiceException catch (error) {
                  if (!mounted) {
                    return;
                  }

                  _showMessage(error.message);
                }
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showCartSideSheet(bool isTablet) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cart',
      barrierColor: Colors.black.withAlpha(40),
      pageBuilder: (dialogContext, _, _) {
        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(),
                child: const SizedBox.expand(),
              ),
            ),
            CartSideSheet(
              controller: _dashboardController,
              isTablet: isTablet,
              onClose: () => Navigator.of(dialogContext).pop(),
              onProceedOrder: () async {
                Navigator.of(dialogContext).pop();
                await _openOrderSummary();
              },
              onUsePreviousOrder: (order) async {
                final shouldReplace = await showDialog<bool>(
                  context: dialogContext,
                  builder: (context) {
                    return Dialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Replace current cart?',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: AppTheme.textDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'This will order the same previous order and replace the current cart items. Do you want to continue?',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppTheme.textSoft),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Replace cart'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );

                if (shouldReplace == true) {
                  final result = _dashboardController.replaceCartWithOrder(order);
                  if (result.addedCount == 0 &&
                      result.unavailableProductNames.isNotEmpty) {
                    _showMessage(
                      'Previous order items are currently unavailable.',
                    );
                    return;
                  }

                  if (result.hasUnavailableProducts) {
                    _showMessage(
                      'Added available items only. Currently unavailable: ${result.unavailableProductNames.join(', ')}',
                    );
                    return;
                  }

                  _showMessage('Cart replaced with the previous order.');
                }
              },
            ),
          ],
        );
      },
      transitionBuilder: (
        context,
        animation,
        secondaryAnimation,
        child,
      ) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
    );
  }

  Future<void> _showOrderPlacedDialog(ShopOrder order) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Order confirmed'),
          content: Text(
            'Order ID: ${order.orderCode}\n'
            'Date: ${_formatDate(order.placedAt)}\n'
            'Time: ${_formatTime(order.placedAt)}',
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _handleBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      _dashboardController.loadOrders();
    } else if (index == 2) {
      _dashboardController.loadActivities();
    } else if (index == 0) {
      _dashboardController.loadCatalog();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 700;
        final horizontalPadding = isTablet ? 28.0 : 14.0;
        final contentBottomPadding = isTablet ? 180.0 : 164.0;

        return AnimatedBuilder(
          animation: _dashboardController,
          builder: (context, _) {
            return Scaffold(
              backgroundColor: Colors.white,
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.startFloat,
              floatingActionButton: Padding(
                padding: EdgeInsets.only(left: isTablet ? 10 : 2, bottom: 14),
                child: FilledButton.icon(
                  onPressed: _openFeedbackSheet,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryBrownDark,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 16 : 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 17),
                  label: Text(
                    'Feedback',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              bottomNavigationBar: _BottomBar(
                isTablet: isTablet,
                selectedIndex: _selectedIndex,
                onTap: _handleBottomNavTap,
              ),
              body: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Colors.white, Color(0xFFFFFCF8)],
                  ),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      10,
                      horizontalPadding,
                      contentBottomPadding,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 980 : 620,
                        ),
                        child: _TabBody(
                          selectedIndex: _selectedIndex,
                          isTablet: isTablet,
                          profile: _profile,
                          greetingText: _greetingText,
                          controller: _dashboardController,
                          onProfileTap: _openProfileSheet,
                          onCartTap: () => _showCartSideSheet(isTablet),
                          onProceedOrderTap: _openOrderSummary,
                          onSecurityTap: _openChangePasswordSheet,
                          onShowMessage: _showMessage,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TabBody extends StatelessWidget {
  const _TabBody({
    required this.selectedIndex,
    required this.isTablet,
    required this.profile,
    required this.greetingText,
    required this.controller,
    required this.onProfileTap,
    required this.onCartTap,
    required this.onProceedOrderTap,
    required this.onSecurityTap,
    required this.onShowMessage,
  });

  final int selectedIndex;
  final bool isTablet;
  final ShopOwnerProfile profile;
  final String greetingText;
  final ShopOwnerDashboardController controller;
  final VoidCallback onProfileTap;
  final VoidCallback onCartTap;
  final VoidCallback onProceedOrderTap;
  final VoidCallback onSecurityTap;
  final ValueChanged<String> onShowMessage;

  @override
  Widget build(BuildContext context) {
    switch (selectedIndex) {
      case 1:
        return ShopOwnerOrdersTab(
          isTablet: isTablet,
          controller: controller,
          onCartTap: onCartTap,
        );
      case 2:
        return ShopOwnerActivityTab(
          isTablet: isTablet,
          controller: controller,
        );
      case 3:
        return ShopOwnerSettingsTab(
          isTablet: isTablet,
          profile: profile,
          onSecurityTap: onSecurityTap,
        );
      case 0:
      default:
        return ShopOwnerHomeTab(
          isTablet: isTablet,
          profile: profile,
          greetingText: greetingText,
          controller: controller,
          onProfileTap: onProfileTap,
          onProceedOrderTap: onProceedOrderTap,
          onShowMessage: onShowMessage,
        );
    }
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.isTablet,
    required this.selectedIndex,
    required this.onTap,
  });

  final bool isTablet;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String label})>[
      (icon: Icons.home_outlined, label: 'Home'),
      (icon: Icons.inventory_2_outlined, label: 'Orders'),
      (icon: Icons.notifications_none_outlined, label: 'Activity'),
      (icon: Icons.settings_outlined, label: 'Settings'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          isTablet ? 18 : 14,
          10,
          isTablet ? 18 : 14,
          isTablet ? 14 : 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppTheme.outlineWarm.withAlpha(90)),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppTheme.primaryBrownDark.withAlpha(10),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List<Widget>.generate(items.length, (index) {
            final isActive = selectedIndex == index;
            final color = isActive ? AppTheme.primaryBrown : AppTheme.textSoft;

            return InkWell(
              onTap: () => onTap(index),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(items[index].icon, color: color, size: isTablet ? 28 : 24),
                    const SizedBox(height: 4),
                    Text(
                      items[index].label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        fontSize: isTablet ? 13 : 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.primaryBrown
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

String _formatDate(DateTime dateTime) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = '${dateTime.minute}'.padLeft(2, '0');
  final meridiem = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $meridiem';
}

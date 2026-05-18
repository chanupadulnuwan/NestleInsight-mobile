import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/services/auth_service.dart';
import 'package:mobile/features/auth/presentation/pages/login_page.dart';
import 'package:mobile/features/distributor/data/services/distributor_service.dart';
import 'package:mobile/features/distributor/domain/delivery_assignment.dart';
import 'package:mobile/features/distributor/presentation/pages/add_note_page.dart';
import 'package:mobile/features/distributor/presentation/pages/deliver_order_page.dart';
import 'package:mobile/features/distributor/presentation/pages/distributor_smart_route_page.dart';
import 'package:mobile/features/distributor/presentation/pages/lorry_inventory_page.dart';
import 'package:mobile/features/distributor/presentation/pages/report_incident_page.dart';
import 'package:mobile/features/distributor/presentation/pages/shop_return_page.dart';
import 'package:mobile/features/distributor/presentation/pages/warehouse_return_page.dart';
import 'package:mobile/features/distributor/presentation/widgets/distributor_profile_sheet.dart';
import 'package:mobile/features/settings/presentation/widgets/change_password_sheet.dart';

class DistributorHomePage extends StatefulWidget {
  const DistributorHomePage({super.key, this.user});

  final Map<String, dynamic>? user;

  @override
  State<DistributorHomePage> createState() => _DistributorHomePageState();
}

class _DistributorHomePageState extends State<DistributorHomePage>
    with WidgetsBindingObserver {
  final DistributorService _service = DistributorService();
  final AuthService _authService = AuthService();

  DeliveryAssignment? _assignment;
  bool _loading = true;
  String? _error;
  int _selectedIndex = 0;
  late DateTime _currentTime;
  Timer? _greetingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentTime = DateTime.now();
    _startGreetingSync();
    _loadAssignment();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _greetingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }

    setState(() {
      _currentTime = DateTime.now();
    });
    _startGreetingSync();
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

  DistributorProfileData get _profile =>
      DistributorProfileData.fromUser(widget.user, assignment: _assignment);

  void _startGreetingSync() {
    _greetingTimer?.cancel();
    final now = DateTime.now();
    _currentTime = now;
    final delayUntilNextMinute =
        Duration(minutes: 1) -
        Duration(
          seconds: now.second,
          milliseconds: now.millisecond,
          microseconds: now.microsecond,
        );

    _greetingTimer = Timer(delayUntilNextMinute, () {
      if (!mounted) {
        return;
      }

      setState(() {
        _currentTime = DateTime.now();
      });

      _greetingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (!mounted) {
          return;
        }

        setState(() {
          _currentTime = DateTime.now();
        });
      });
    });
  }

  Future<void> _loadAssignment() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final assignment = await _service.getMyAssignment();
      if (!mounted) {
        return;
      }

      setState(() {
        _assignment = assignment;
        _loading = false;
      });
    } on DistributorServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Unable to load the distributor dashboard right now.';
        _loading = false;
      });
    }
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

  Future<void> _openProfileSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DistributorProfileSheet(
        profile: _profile,
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
  }

  Future<void> _openInventoryPage() async {
    final assignment = _assignment;
    if (assignment == null) {
      _showMessage('No delivery assignment is available yet.');
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LorryInventoryPage(assignment: assignment),
      ),
    );
  }

  Future<void> _openSmartRoutePage() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => DistributorSmartRoutePage(assignment: _assignment),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == true || result == null) {
      await _loadAssignment();
    }
  }

  Future<void> _openWarehouseReturnPage() async {
    final assignment = _assignment;
    if (assignment == null || !assignment.isActive) {
      _showMessage('Warehouse returns are available only for an active route.');
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => WarehouseReturnPage(assignment: assignment),
      ),
    );

    if (result == true) {
      await _loadAssignment();
    }
  }

  Future<void> _openDeliverOrder(AssignmentOrder order) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => DeliverOrderPage(order: order)),
    );

    if (result == true) {
      await _loadAssignment();
    }
  }

  Future<void> _openShopReturn(AssignmentOrder order) async {
    final assignment = _assignment;
    if (assignment == null) {
      _showMessage('No active lorry inventory is available.');
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ShopReturnPage(
          order: order,
          lorryInventory: assignment.lorryInventory,
        ),
      ),
    );

    if (result == true) {
      await _loadAssignment();
    }
  }

  Future<void> _openAddNotePage() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AddNotePage(assignmentId: _assignment?.id),
      ),
    );
  }

  Future<void> _openReportIncidentPage() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ReportIncidentPage(assignmentId: _assignment?.id),
      ),
    );
  }

  void _handleBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
        final contentBottomPadding = isTablet ? 182.0 : 166.0;

        return Scaffold(
          backgroundColor: Colors.white,
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
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryBrown,
                      ),
                    )
                  : _error != null
                  ? _ErrorStateView(
                      profile: _profile,
                      greetingText: _greetingText,
                      isTablet: isTablet,
                      message: _error!,
                      onRetry: _loadAssignment,
                      onProfileTap: _openProfileSheet,
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAssignment,
                      color: AppTheme.primaryBrown,
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          10,
                          horizontalPadding,
                          contentBottomPadding,
                        ),
                        children: <Widget>[
                          Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isTablet ? 980 : 620,
                              ),
                              child: _TabBody(
                                selectedIndex: _selectedIndex,
                                isTablet: isTablet,
                                profile: _profile,
                                greetingText: _greetingText,
                                assignment: _assignment,
                                onProfileTap: _openProfileSheet,
                                onSmartRouteTap: _openSmartRoutePage,
                                onInventoryTap: _openInventoryPage,
                                onWarehouseReturnTap: _openWarehouseReturnPage,
                                onDeliverTap: _openDeliverOrder,
                                onShopReturnTap: _openShopReturn,
                                onAddNoteTap: _openAddNotePage,
                                onReportIncidentTap: _openReportIncidentPage,
                                onSecurityTap: _openChangePasswordSheet,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
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
    required this.assignment,
    required this.onProfileTap,
    required this.onSmartRouteTap,
    required this.onInventoryTap,
    required this.onWarehouseReturnTap,
    required this.onDeliverTap,
    required this.onShopReturnTap,
    required this.onAddNoteTap,
    required this.onReportIncidentTap,
    required this.onSecurityTap,
  });

  final int selectedIndex;
  final bool isTablet;
  final DistributorProfileData profile;
  final String greetingText;
  final DeliveryAssignment? assignment;
  final VoidCallback onProfileTap;
  final Future<void> Function() onSmartRouteTap;
  final Future<void> Function() onInventoryTap;
  final Future<void> Function() onWarehouseReturnTap;
  final Future<void> Function(AssignmentOrder order) onDeliverTap;
  final Future<void> Function(AssignmentOrder order) onShopReturnTap;
  final Future<void> Function() onAddNoteTap;
  final Future<void> Function() onReportIncidentTap;
  final Future<void> Function() onSecurityTap;

  @override
  Widget build(BuildContext context) {
    switch (selectedIndex) {
      case 1:
        return _DistributorOrdersTab(
          isTablet: isTablet,
          assignment: assignment,
          onDeliverTap: onDeliverTap,
          onShopReturnTap: onShopReturnTap,
        );
      case 2:
        return _DistributorActivityTab(
          isTablet: isTablet,
          assignment: assignment,
          onAddNoteTap: onAddNoteTap,
          onReportIncidentTap: onReportIncidentTap,
        );
      case 3:
        return _DistributorSettingsTab(
          isTablet: isTablet,
          profile: profile,
          onSecurityTap: onSecurityTap,
        );
      case 0:
      default:
        return _DistributorHomeTab(
          isTablet: isTablet,
          profile: profile,
          greetingText: greetingText,
          assignment: assignment,
          onProfileTap: onProfileTap,
          onSmartRouteTap: onSmartRouteTap,
          onInventoryTap: onInventoryTap,
          onWarehouseReturnTap: onWarehouseReturnTap,
          onDeliverTap: onDeliverTap,
          onShopReturnTap: onShopReturnTap,
        );
    }
  }
}

class _DistributorHomeTab extends StatelessWidget {
  const _DistributorHomeTab({
    required this.isTablet,
    required this.profile,
    required this.greetingText,
    required this.assignment,
    required this.onProfileTap,
    required this.onSmartRouteTap,
    required this.onInventoryTap,
    required this.onWarehouseReturnTap,
    required this.onDeliverTap,
    required this.onShopReturnTap,
  });

  final bool isTablet;
  final DistributorProfileData profile;
  final String greetingText;
  final DeliveryAssignment? assignment;
  final VoidCallback onProfileTap;
  final Future<void> Function() onSmartRouteTap;
  final Future<void> Function() onInventoryTap;
  final Future<void> Function() onWarehouseReturnTap;
  final Future<void> Function(AssignmentOrder order) onDeliverTap;
  final Future<void> Function(AssignmentOrder order) onShopReturnTap;

  @override
  Widget build(BuildContext context) {
    final pendingOrders = assignment == null
        ? const <AssignmentOrder>[]
        : assignment!.orders.where((order) => !order.isCompleted).toList();
    final completedOrders = assignment == null
        ? const <AssignmentOrder>[]
        : assignment!.orders.where((order) => order.isCompleted).toList();
    final progress = assignment == null || assignment!.totalCount == 0
        ? 0.0
        : assignment!.completedCount / assignment!.totalCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HeaderCard(
          greetingText: greetingText,
          profile: profile,
          isTablet: isTablet,
          onProfileTap: onProfileTap,
        ),
        SizedBox(height: isTablet ? 22 : 18),
        Row(
          children: <Widget>[
            Expanded(
              child: _MetricCard(
                title: 'Vehicle',
                value: profile.vehicleHeadline,
                subtitle: profile.vehicleSubLabel,
                icon: Icons.local_shipping_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Pending stops',
                value: '${pendingOrders.length}',
                subtitle: assignment == null
                    ? 'Waiting for route'
                    : 'Out of ${assignment!.totalCount} assigned',
                icon: Icons.route_outlined,
                accentColor: AppTheme.proceedOrderOlive,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ProgressOverviewCard(
          assignment: assignment,
          progress: progress,
          completedCount: completedOrders.length,
          pendingCount: pendingOrders.length,
        ),
        SizedBox(height: isTablet ? 24 : 22),
        const _SectionHeading(
          title: 'Quick actions',
          subtitle:
              'Keep the same distributor tools, but with a cleaner dashboard layout.',
        ),
        const SizedBox(height: 12),
        _ActionPanel(
          icon: Icons.alt_route,
          title: 'Smart Route',
          subtitle: 'Navigate assigned shops from nearest to farthest.',
          onTap: onSmartRouteTap,
          accentColor: AppTheme.promotionMutedRed,
        ),
        const SizedBox(height: 12),
        if (assignment != null && assignment!.isActive)
          Row(
            children: <Widget>[
              Expanded(
                child: _ActionPanel(
                  icon: Icons.inventory_2_outlined,
                  title: 'Inventory',
                  subtitle: 'Check the lorry stock and loaded items.',
                  onTap: onInventoryTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionPanel(
                  icon: Icons.warehouse_outlined,
                  title: 'End route',
                  subtitle:
                      'Review route returns, cash, and close today\'s route.',
                  onTap: onWarehouseReturnTap,
                  accentColor: AppTheme.proceedOrderOlive,
                ),
              ),
            ],
          )
        else
          _ActionPanel(
            icon: Icons.inventory_2_outlined,
            title: 'Inventory',
            subtitle:
                'Open the lorry inventory view when a route is available.',
            onTap: onInventoryTap,
          ),
        SizedBox(height: isTablet ? 24 : 22),
        _SectionHeading(
          title: 'Next delivery',
          subtitle: pendingOrders.isEmpty
              ? 'All assigned deliveries are already completed.'
              : 'Use the main actions when you reach the next shop.',
        ),
        const SizedBox(height: 12),
        if (assignment == null)
          const _MessageCard(
            title: 'No assignment today',
            message:
                'Your territory manager has not assigned deliveries yet. Pull down to refresh this dashboard when the route is ready.',
          )
        else if (pendingOrders.isEmpty)
          _CompletionCard(completedCount: completedOrders.length)
        else
          _FeaturedOrderCard(
            order: pendingOrders.first,
            remainingStops: pendingOrders.length,
            onDeliverTap: () => onDeliverTap(pendingOrders.first),
            onShopReturnTap: () => onShopReturnTap(pendingOrders.first),
          ),
        if (assignment != null &&
            assignment!.notes != null &&
            assignment!.notes!.trim().isNotEmpty) ...<Widget>[
          SizedBox(height: isTablet ? 24 : 22),
          const _SectionHeading(
            title: 'Manager note',
            subtitle: 'Latest instruction attached to the current route.',
          ),
          const SizedBox(height: 12),
          _NoticeCard(
            icon: Icons.mark_chat_read_outlined,
            title: 'Today\'s route note',
            message: assignment!.notes!.trim(),
          ),
        ],
      ],
    );
  }
}

class _DistributorOrdersTab extends StatelessWidget {
  const _DistributorOrdersTab({
    required this.isTablet,
    required this.assignment,
    required this.onDeliverTap,
    required this.onShopReturnTap,
  });

  final bool isTablet;
  final DeliveryAssignment? assignment;
  final Future<void> Function(AssignmentOrder order) onDeliverTap;
  final Future<void> Function(AssignmentOrder order) onShopReturnTap;

  @override
  Widget build(BuildContext context) {
    final orders = assignment?.orders ?? const <AssignmentOrder>[];
    final pendingOrders = orders.where((order) => !order.isCompleted).toList();
    final completedOrders = orders.where((order) => order.isCompleted).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionHeading(
          title: 'Orders',
          subtitle:
              'Tap any order to review the delivery details and current status.',
        ),
        const SizedBox(height: 18),
        if (assignment == null)
          const _MessageCard(
            title: 'No order history available',
            message:
                'Once a delivery assignment is created for you, the route orders will appear here.',
          )
        else if (orders.isEmpty)
          const _MessageCard(
            title: 'No route orders yet',
            message:
                'This assignment does not have any shops linked to it yet.',
          )
        else ...<Widget>[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppTheme.outlineWarm.withAlpha(105)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppTheme.primaryBrownDark.withAlpha(10),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _SummaryPill(
                    label: 'Total',
                    value: '${orders.length}',
                    color: AppTheme.primaryBrown,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryPill(
                    label: 'Pending',
                    value: '${pendingOrders.length}',
                    color: AppTheme.proceedOrderOlive,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryPill(
                    label: 'Done',
                    value: '${completedOrders.length}',
                    color: AppTheme.primaryBrownDark,
                  ),
                ),
              ],
            ),
          ),
          if (pendingOrders.isNotEmpty) ...<Widget>[
            const SizedBox(height: 22),
            Text(
              'In progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ...pendingOrders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OrderHistoryCard(
                  order: order,
                  highlighted: true,
                  onTap: () => _showOrderDetails(context, order),
                ),
              ),
            ),
          ],
          if (completedOrders.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Completed',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ...completedOrders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OrderHistoryCard(
                  order: order,
                  onTap: () => _showOrderDetails(context, order),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _showOrderDetails(BuildContext context, AssignmentOrder order) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _OrderDetailsSheet(
          order: order,
          onDeliverTap: order.isCompleted
              ? null
              : () async {
                  Navigator.of(sheetContext).pop();
                  await onDeliverTap(order);
                },
          onShopReturnTap: order.isCompleted
              ? null
              : () async {
                  Navigator.of(sheetContext).pop();
                  await onShopReturnTap(order);
                },
        );
      },
    );
  }
}

class _DistributorActivityTab extends StatelessWidget {
  const _DistributorActivityTab({
    required this.isTablet,
    required this.assignment,
    required this.onAddNoteTap,
    required this.onReportIncidentTap,
  });

  final bool isTablet;
  final DeliveryAssignment? assignment;
  final Future<void> Function() onAddNoteTap;
  final Future<void> Function() onReportIncidentTap;

  @override
  Widget build(BuildContext context) {
    final pendingCount =
        assignment?.orders.where((order) => !order.isCompleted).length ?? 0;
    final completedCount =
        assignment?.orders.where((order) => order.isCompleted).length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionHeading(
          title: 'Activity Center',
          subtitle:
              'Important distributor actions live here, including reporting incidents and updating your manager.',
        ),
        const SizedBox(height: 18),
        _ActivityActionCard(
          icon: Icons.note_alt_outlined,
          title: 'Add note to manager',
          subtitle:
              'Send quick route updates such as delays, traffic, or fuel issues.',
          buttonLabel: 'Add note',
          onTap: onAddNoteTap,
        ),
        const SizedBox(height: 12),
        _ActivityActionCard(
          icon: Icons.warning_amber_outlined,
          title: 'Report incident',
          subtitle:
              'Record vehicle issues, customer disputes, route problems, or delivery delays.',
          buttonLabel: 'Report now',
          onTap: onReportIncidentTap,
          accentColor: AppTheme.promotionMutedRed,
        ),
        const SizedBox(height: 20),
        if (assignment != null)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppTheme.outlineWarm.withAlpha(100)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppTheme.primaryBrownDark.withAlpha(10),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Today\'s route snapshot',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _SummaryPill(
                        label: 'Status',
                        value: _friendlyStatus(assignment!.status),
                        color: AppTheme.primaryBrown,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryPill(
                        label: 'Pending',
                        value: '$pendingCount',
                        color: AppTheme.proceedOrderOlive,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryPill(
                        label: 'Done',
                        value: '$completedCount',
                        color: AppTheme.primaryBrownDark,
                      ),
                    ),
                  ],
                ),
                if (assignment!.notes != null &&
                    assignment!.notes!.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  _NoticeCard(
                    icon: Icons.mark_chat_read_outlined,
                    title: 'Manager note',
                    message: assignment!.notes!.trim(),
                  ),
                ],
              ],
            ),
          )
        else
          const _MessageCard(
            title: 'No active route yet',
            message:
                'You can still contact your manager from here even before today\'s route is assigned.',
          ),
      ],
    );
  }
}

class _DistributorSettingsTab extends StatelessWidget {
  const _DistributorSettingsTab({
    required this.isTablet,
    required this.profile,
    required this.onSecurityTap,
  });

  final bool isTablet;
  final DistributorProfileData profile;
  final Future<void> Function() onSecurityTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionHeading(
          title: 'Settings',
          subtitle:
              'Use the same shop-owner-style settings experience for security and account information.',
        ),
        const SizedBox(height: 20),
        Container(
          padding: EdgeInsets.all(isTablet ? 22 : 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.outlineWarm.withAlpha(100)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppTheme.primaryBrownDark.withAlpha(10),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceTint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.security_outlined,
                    color: AppTheme.securitySlate,
                  ),
                ),
                title: Text(
                  'Security',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  'Change your password using the same security sheet used in the shop owner experience.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: onSecurityTap,
              ),
              Divider(color: AppTheme.outlineWarm.withAlpha(110)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Account',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  '${profile.displayName}\n${profile.emailLabel}\n${profile.phoneLabel}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSoft,
                    height: 1.5,
                  ),
                ),
              ),
              Divider(color: AppTheme.outlineWarm.withAlpha(110)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Assignment',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  '${profile.territoryLabel}\n${profile.vehicleHeadline}\n${profile.deliveryDateLabel}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSoft,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorStateView extends StatelessWidget {
  const _ErrorStateView({
    required this.profile,
    required this.greetingText,
    required this.isTablet,
    required this.message,
    required this.onRetry,
    required this.onProfileTap,
  });

  final DistributorProfileData profile;
  final String greetingText;
  final bool isTablet;
  final String message;
  final Future<void> Function() onRetry;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 28 : 14,
        10,
        isTablet ? 28 : 14,
        32,
      ),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 980 : 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _HeaderCard(
                  greetingText: greetingText,
                  profile: profile,
                  isTablet: isTablet,
                  onProfileTap: onProfileTap,
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFE7C2BD)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFF9B4B46),
                        size: 34,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Unable to load the dashboard',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSoft,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: onRetry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.greetingText,
    required this.profile,
    required this.isTablet,
    required this.onProfileTap,
  });

  final String greetingText;
  final DistributorProfileData profile;
  final bool isTablet;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: isTablet ? 252 : 246,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppTheme.headerGradientStart,
            AppTheme.headerGradientEnd,
          ],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -52,
            right: -42,
            child: Container(
              width: isTablet ? 220 : 170,
              height: isTablet ? 220 : 170,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(36),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -24,
            bottom: -34,
            child: Container(
              width: isTablet ? 150 : 116,
              height: isTablet ? 150 : 116,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(24),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isTablet ? 28 : 20,
              isTablet ? 18 : 16,
              isTablet ? 28 : 20,
              isTablet ? 24 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Align(
                  alignment: Alignment.topRight,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onProfileTap,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: isTablet ? 56 : 48,
                        height: isTablet ? 56 : 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withAlpha(220),
                            width: 1.3,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: isTablet ? 28 : 24,
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  greetingText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withAlpha(235),
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 20 : 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  profile.firstNameOrFallback,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: isTablet ? 36 : 28,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Territory Distributor',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withAlpha(220),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Flexible(
                      child: _InfoChip(
                        icon: Icons.route_outlined,
                        label: profile.headerLocationLabel,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.isTablet,
  });

  final IconData icon;
  final String label;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 14 : 12,
        vertical: isTablet ? 10 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Colors.white, size: isTablet ? 18 : 15),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 260 : 170),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 15 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.accentColor = AppTheme.primaryBrown,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(216),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withAlpha(150)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.white.withAlpha(235),
            const Color(0xFFF9F4ED).withAlpha(220),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.primaryBrownDark.withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.surfaceTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSoft),
          ),
        ],
      ),
    );
  }
}

class _ProgressOverviewCard extends StatelessWidget {
  const _ProgressOverviewCard({
    required this.assignment,
    required this.progress,
    required this.completedCount,
    required this.pendingCount,
  });

  final DeliveryAssignment? assignment;
  final double progress;
  final int completedCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFE5F5E7),
            Color(0xFFD7EFE0),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFAED0B7)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF2F6B45).withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Today\'s delivery progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                assignment == null
                    ? '0/0'
                    : '${assignment!.completedCount}/${assignment!.totalCount}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF2C6A45),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFBFDCC8),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2C7A52),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _SummaryPill(
                  label: 'Completed',
                  value: '$completedCount',
                  color: const Color(0xFF2C7A52),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryPill(
                  label: 'Pending',
                  value: '$pendingCount',
                  color: const Color(0xFF4F8B60),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryPill(
                  label: 'Date',
                  value: assignment == null
                      ? 'Pending'
                      : _formatDateFromRaw(assignment!.deliveryDate),
                  color: const Color(0xFF35684B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accentColor = AppTheme.primaryBrown,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function() onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.outlineWarm.withAlpha(105)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppTheme.primaryBrownDark.withAlpha(10),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceTint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
        ),
      ],
    );
  }
}

class _FeaturedOrderCard extends StatelessWidget {
  const _FeaturedOrderCard({
    required this.order,
    required this.remainingStops,
    required this.onDeliverTap,
    required this.onShopReturnTap,
  });

  final AssignmentOrder order;
  final int remainingStops;
  final Future<void> Function() onDeliverTap;
  final Future<void> Function() onShopReturnTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.outlineWarm.withAlpha(105)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.primaryBrownDark.withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceTint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: AppTheme.primaryBrown,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      order.shopName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.orderCode,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSoft,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceTint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$remainingStops stops left',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryBrownDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (order.shopAddress != null &&
              order.shopAddress!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppTheme.textSoft,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.shopAddress!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
                  ),
                ),
              ],
            ),
          ],
          if (order.shopPhone != null &&
              order.shopPhone!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.phone_outlined,
                  size: 16,
                  color: AppTheme.textSoft,
                ),
                const SizedBox(width: 6),
                Text(
                  order.shopPhone!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _formatCurrency(order.totalAmount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryBrown,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShopReturnTap,
                  icon: const Icon(Icons.keyboard_return_outlined, size: 18),
                  label: const Text('Shop Return'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onDeliverTap,
                  icon: const Icon(Icons.check_outlined, size: 18),
                  label: const Text('Deliver'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.completedCount});

  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.outlineWarm.withAlpha(105)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.primaryBrownDark.withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.surfaceTint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: AppTheme.primaryBrownDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'All deliveries completed',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  completedCount == 0
                      ? 'There are no assigned stops on the current route.'
                      : 'Great work. You have completed $completedCount deliveries on this route.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  const _OrderHistoryCard({
    required this.order,
    required this.onTap,
    this.highlighted = false,
  });

  final AssignmentOrder order;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: highlighted
                ? AppTheme.primaryBrown.withAlpha(130)
                : AppTheme.outlineWarm.withAlpha(100),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppTheme.primaryBrownDark.withAlpha(10),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    order.shopName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: order.isCompleted
                        ? AppTheme.surfaceTint
                        : AppTheme.proceedOrderOlive.withAlpha(18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _friendlyStatus(order.status),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: order.isCompleted
                          ? AppTheme.primaryBrownDark
                          : AppTheme.proceedOrderOlive,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              order.orderCode,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSoft,
                fontFamily: 'monospace',
              ),
            ),
            if (order.shopAddress != null &&
                order.shopAddress!.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                order.shopAddress!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _formatCurrency(order.totalAmount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryBrown,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: highlighted
                      ? AppTheme.primaryBrown
                      : AppTheme.textSoft,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderDetailsSheet extends StatelessWidget {
  const _OrderDetailsSheet({
    required this.order,
    this.onDeliverTap,
    this.onShopReturnTap,
  });

  final AssignmentOrder order;
  final Future<void> Function()? onDeliverTap;
  final Future<void> Function()? onShopReturnTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                  'Order details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        order.shopName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceTint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _friendlyStatus(order.status),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryBrownDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  order.orderCode,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSoft,
                    fontFamily: 'monospace',
                  ),
                ),
                if (order.shopAddress != null &&
                    order.shopAddress!.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    order.shopAddress!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
                  ),
                ],
                if (order.shopPhone != null &&
                    order.shopPhone!.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    order.shopPhone!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceTint,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Total',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppTheme.textDark,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      Text(
                        _formatCurrency(order.totalAmount),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.primaryBrownDark,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.34,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: order.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = order.items[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWarm,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.outlineWarm.withAlpha(100),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    item.productName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: AppTheme.textDark,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.quantity} x ${_formatCurrency(item.unitPrice)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppTheme.textSoft),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatCurrency(item.lineTotal),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppTheme.primaryBrownDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                if (onDeliverTap != null &&
                    onShopReturnTap != null) ...<Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onShopReturnTap,
                          icon: const Icon(Icons.keyboard_return_outlined),
                          label: const Text('Shop Return'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onDeliverTap,
                          icon: const Icon(Icons.check_outlined),
                          label: const Text('Deliver'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityActionCard extends StatelessWidget {
  const _ActivityActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
    this.accentColor = AppTheme.primaryBrown,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final Future<void> Function() onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.outlineWarm.withAlpha(100)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.primaryBrownDark.withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: accentColor.withAlpha(18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(backgroundColor: accentColor),
                  child: Text(buttonLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarm,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineWarm.withAlpha(110)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.surfaceTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primaryBrownDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.outlineWarm.withAlpha(100)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.primaryBrownDark.withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
          ),
        ],
      ),
    );
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
                    Icon(
                      items[index].icon,
                      color: color,
                      size: isTablet ? 28 : 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[index].label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
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

String _friendlyStatus(String status) {
  final normalized = status.trim();
  if (normalized.isEmpty) {
    return 'Pending';
  }

  return normalized
      .toLowerCase()
      .split(RegExp(r'[_\s]+'))
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

String _formatCurrency(double value) {
  final normalized = value.toStringAsFixed(2);
  final parts = normalized.split('.');
  final whole = parts.first;
  final decimal = parts.last;
  final buffer = StringBuffer();

  for (var index = 0; index < whole.length; index++) {
    final reverseIndex = whole.length - index;
    buffer.write(whole[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }

  return 'LKR ${buffer.toString()}.$decimal';
}

String _formatDateFromRaw(String rawDate) {
  final parsed = DateTime.tryParse(rawDate);
  if (parsed == null) {
    return rawDate.trim().isEmpty ? 'Pending' : rawDate;
  }

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

  final localDate = parsed.toLocal();
  return '${localDate.day} ${months[localDate.month - 1]}';
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/sales_rep/data/services/route_service.dart';
import 'package:mobile/features/sales_rep/data/services/route_setup_service.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/route_cubit.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/route_setup_cubit.dart';

class StartRoutePage extends StatelessWidget {
  const StartRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RouteCubit()..loadRoute(),
      child: const _StartRouteView(),
    );
  }
}

class _StartRouteView extends StatefulWidget {
  const _StartRouteView();

  @override
  State<_StartRouteView> createState() => _StartRouteViewState();
}

class _StartRouteViewState extends State<_StartRouteView> {
  final TextEditingController _routeStartPinController = TextEditingController();

  @override
  void dispose() {
    _routeStartPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RouteCubit, RouteState>(
      listener: (context, state) {
        if (state is RouteError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is RouteActionSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.surfaceWarm,
        appBar: AppBar(
          title: const Text('Start Route'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () => context.read<RouteCubit>().loadRoute(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: BlocBuilder<RouteCubit, RouteState>(
          builder: (context, state) {
            final route = switch (state) {
              RouteLoaded(:final activeRoute) => activeRoute,
              RouteActionSuccess(:final route) => route,
              _ => context.read<RouteCubit>().currentRoute,
            };
            final isLoading = state is RouteLoading;

            if (isLoading && route == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              color: AppTheme.primaryBrown,
              onRefresh: () => context.read<RouteCubit>().loadRoute(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  _RouteHeroCard(route: route, isLoading: isLoading),
                  const SizedBox(height: 18),
                  if (route == null)
                    _NoRouteCard(
                      onCreate: isLoading
                          ? null
                          : () => _openCreateRouteSheet(context),
                    )
                  else
                    _buildRouteBody(context, route, isLoading),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRouteBody(
    BuildContext context,
    SalesRoute route,
    bool isLoading,
  ) {
    switch (route.status) {
      case 'DRAFT':
      case 'AWAITING_LOAD_APPROVAL':
        return Column(
          children: [
            _SelectionSummaryCard(route: route),
            const SizedBox(height: 14),
            _BeatPlanCard(
              route: route,
              isLoading: isLoading,
              onEdit: () => _openBeatPlanSheet(context, route),
            ),
            const SizedBox(height: 14),
            _DeliveryAlertsCard(
              route: route,
              isLoading: isLoading,
              onReviewAlerts: () => _openDeliveryApprovalSheet(context, route),
              onConfirmPin: () => _openDeliveryPinDialog(context, route),
            ),
            const SizedBox(height: 14),
            _LoadRequestCard(
              route: route,
              isLoading: isLoading,
              onOpen: () => _openLoadRequestSheet(context, route),
            ),
          ],
        );
      case 'APPROVED_TO_START':
        return _ApprovedToStartCard(
          route: route,
          pinController: _routeStartPinController,
          isLoading: isLoading,
          onStart: () async {
            final pin = _routeStartPinController.text.trim();
            if (pin.length != 6) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enter the 6-digit route PIN.')),
              );
              return;
            }

            await context.read<RouteCubit>().enterPin(
              routeId: route.id,
              pin: pin,
            );
          },
        );
      case 'IN_PROGRESS':
        return _InProgressCard(
          route: route,
          isLoading: isLoading,
          onClose: () => _openCloseRouteSheet(context, route),
        );
      case 'CLOSED':
        return _ClosedCard(route: route);
      default:
        return _SectionCard(
          title: 'Route Status',
          subtitle: 'Current status: ${_formatStatus(route.status)}',
          accentColor: AppTheme.securitySlate,
          child: const SizedBox.shrink(),
        );
    }
  }

  Future<void> _openCreateRouteSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => RouteSetupCubit()..loadSetupOptions(),
        child: _CreateRouteSheet(
          onSubmit: ({required warehouseId, required vehicleId}) {
            return context.read<RouteCubit>().createRoute(
              warehouseId: warehouseId,
              vehicleId: vehicleId,
            );
          },
        ),
      ),
    );
  }

  Future<void> _openBeatPlanSheet(BuildContext context, SalesRoute route) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BeatPlanSheet(
        route: route,
        onSubmit: (selectedOutletIds) {
          return context.read<RouteCubit>().updateBeatPlan(
            routeId: route.id,
            selectedOutletIds: selectedOutletIds,
          );
        },
      ),
    );
  }

  Future<void> _openDeliveryApprovalSheet(
    BuildContext context,
    SalesRoute route,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeliveryApprovalSheet(
        route: route,
        onSubmit: (orderIds) {
          return context.read<RouteCubit>().requestDeliveryApproval(
            routeId: route.id,
            orderIds: orderIds,
          );
        },
      ),
    );
  }

  Future<void> _openDeliveryPinDialog(
    BuildContext context,
    SalesRoute route,
  ) async {
    final approval = route.deliveryApproval;
    if (approval == null) {
      return;
    }

    final pinController = TextEditingController();

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Confirm TM PIN'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter the PIN shared by your Territory Manager to include ready-for-delivery orders in this route.',
                  style: Theme.of(dialogContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'TM PIN',
                    hintText: 'Enter 6 digits',
                    counterText: '',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return;
      }

      if (!context.mounted) {
        return;
      }

      final pin = pinController.text.trim();
      if (pin.length != 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter the 6-digit approval PIN.')),
        );
        return;
      }

      await context.read<RouteCubit>().confirmDeliveryApprovalPin(
        approvalRequestId: approval.id,
        pin: pin,
      );
    } finally {
      pinController.dispose();
    }
  }

  Future<void> _openLoadRequestSheet(BuildContext context, SalesRoute route) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LoadRequestSheet(
        route: route,
        onSubmit: (deliveryStock, freeSaleStock) {
          return context.read<RouteCubit>().submitLoadRequest(
            routeId: route.id,
            deliveryStock: deliveryStock,
            freeSaleStock: freeSaleStock,
          );
        },
      ),
    );
  }

  Future<void> _openCloseRouteSheet(BuildContext context, SalesRoute route) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CloseRouteSheet(
        route: route,
        onSubmit: ({
          required pin,
          required closingStock,
          required returnItems,
          varianceReason,
        }) {
          return context.read<RouteCubit>().closeRoute(
            routeId: route.id,
            pin: pin,
            closingStock: closingStock,
            returnItems: returnItems,
            varianceReason: varianceReason,
          );
        },
      ),
    );
  }
}

class _RouteHeroCard extends StatelessWidget {
  const _RouteHeroCard({required this.route, required this.isLoading});

  final SalesRoute? route;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final statusLabel = route == null ? 'Ready to plan' : _formatStatus(route!.status);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.headerGradientStart, AppTheme.headerGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBrownDark.withAlpha(25),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(28),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (isLoading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            route == null ? 'Start today with a clean route setup.' : 'Today\'s route is underway.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            route == null
                ? 'Choose a warehouse, lock an available vehicle, review your best plan, and move to approval with fewer steps.'
                : 'Warehouse, vehicle, best plan, delivery approvals, and van load status are all tracked here before you head out.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withAlpha(225),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroChip(
                icon: Icons.flag_rounded,
                label: statusLabel,
              ),
              _HeroChip(
                icon: Icons.warehouse_rounded,
                label: route?.warehouseName ?? 'No warehouse selected',
              ),
              _HeroChip(
                icon: Icons.local_shipping_rounded,
                label: route?.vehicleLabel ?? 'No vehicle selected',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoRouteCard extends StatelessWidget {
  const _NoRouteCard({required this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Route Setup',
      subtitle:
          'You do not have an active route yet. Choose a warehouse in your territory, select an available vehicle, then review the day before sending the load request.',
      accentColor: AppTheme.primaryBrown,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _InfoPill(label: 'Territory-safe warehouse list'),
              _InfoPill(label: 'Vehicle locking'),
              _InfoPill(label: 'Best plan + delivery alerts'),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.playlist_add_check_circle_rounded),
              label: const Text('Create Draft Route'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionSummaryCard extends StatelessWidget {
  const _SelectionSummaryCard({required this.route});

  final SalesRoute route;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Selected Setup',
      subtitle: 'Your warehouse and vehicle stay linked to this route until it is closed.',
      accentColor: AppTheme.primaryBrownDark,
      child: Column(
        children: [
          _KeyValueRow(
            icon: Icons.warehouse_rounded,
            label: 'Warehouse',
            value: route.warehouseName ?? route.warehouseId,
          ),
          const SizedBox(height: 12),
          _KeyValueRow(
            icon: Icons.local_shipping_rounded,
            label: 'Vehicle',
            value: route.vehicleLabel ?? route.vehicleId ?? 'Not assigned',
          ),
          const SizedBox(height: 12),
          _KeyValueRow(
            icon: Icons.flag_circle_rounded,
            label: 'Route status',
            value: _formatStatus(route.status),
          ),
        ],
      ),
    );
  }
}

class _BeatPlanCard extends StatelessWidget {
  const _BeatPlanCard({
    required this.route,
    required this.isLoading,
    required this.onEdit,
  });

  final SalesRoute route;
  final bool isLoading;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final selectedItems = route.beatPlanItems.where((item) => item.isSelected).toList();
    final dueCount = selectedItems.where((item) => item.source == 'DUE').length;
    final deliveryCount = selectedItems.where((item) => item.hasPendingDelivery).length;
    final manualCount = selectedItems.where((item) => item.source == 'MANUAL').length;

    return _SectionCard(
      title: 'Today\'s Best Plan',
      subtitle:
          'The plan blends due outlets, delivery-driven outlets, and manual additions. Saved selections auto-fill again every 4 weeks for the same warehouse.',
      accentColor: AppTheme.proceedOrderOlive,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatBadge(label: 'Selected', value: '${selectedItems.length}'),
              _StatBadge(label: 'Due', value: '$dueCount'),
              _StatBadge(label: 'Delivery', value: '$deliveryCount'),
              _StatBadge(label: 'Manual', value: '$manualCount'),
            ],
          ),
          const SizedBox(height: 16),
          if (selectedItems.isEmpty)
            const _EmptyMessage(
              icon: Icons.storefront_outlined,
              message:
                  'No outlets are selected yet. Review the list and tick the shops you want on today\'s route.',
            )
          else
            Column(
              children: selectedItems.take(4).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BeatPlanListTile(item: item),
                );
              }).toList(),
            ),
          if (selectedItems.length > 4)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${selectedItems.length - 4} more outlet(s) selected',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSoft,
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : onEdit,
              icon: const Icon(Icons.checklist_rtl_rounded),
              label: const Text('Review Best Plan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryAlertsCard extends StatelessWidget {
  const _DeliveryAlertsCard({
    required this.route,
    required this.isLoading,
    required this.onReviewAlerts,
    required this.onConfirmPin,
  });

  final SalesRoute route;
  final bool isLoading;
  final VoidCallback onReviewAlerts;
  final VoidCallback onConfirmPin;

  @override
  Widget build(BuildContext context) {
    final totalOrders = route.deliveryAlerts.fold<int>(
      0,
      (sum, alert) => sum + alert.orderCount,
    );
    final includedOutlets = route.deliveryOrderIds.isEmpty
        ? 0
        : route.deliveryAlerts
              .where(
                (alert) => alert.orderIds.any(route.deliveryOrderIds.contains),
              )
              .length;
    final approval = route.deliveryApproval;
    final approvalVerified = approval?.pinVerifiedAt != null;
    final approvalStatus = approval == null ? null : _formatStatus(approval.status);

    String message;
    Color accentColor;
    if (route.deliveryAlerts.isEmpty) {
      message = 'No ready-for-delivery orders are waiting in your territory right now.';
      accentColor = AppTheme.proceedOrderOlive;
    } else if (approvalVerified) {
      message =
          'Delivery approval is confirmed. Included orders can now flow into the van load request.';
      accentColor = AppTheme.proceedOrderOlive;
    } else if (approval?.status == 'APPROVED') {
      message =
          'TM approved the delivery request. Enter the shared PIN before continuing.';
      accentColor = AppTheme.addToCartClay;
    } else if (approval?.status == 'REJECTED') {
      message =
          'TM denied the latest delivery request, so those ready-for-delivery orders cannot be included in this route yet.';
      accentColor = AppTheme.promotionMutedRed;
    } else if (route.deliveryOrderIds.isNotEmpty) {
      message =
          'Delivery outlets were selected. TM approval is still required before the route can carry those orders.';
      accentColor = AppTheme.addToCartClay;
    } else {
      message =
          'Ready-for-delivery orders are available. Choose whether to carry them on this route and request TM approval if needed.';
      accentColor = AppTheme.addToCartClay;
    }

    return _SectionCard(
      title: 'Delivery Alerts',
      subtitle: message,
      accentColor: accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatBadge(label: 'Alerted outlets', value: '${route.deliveryAlerts.length}'),
              _StatBadge(label: 'Ready orders', value: '$totalOrders'),
              _StatBadge(label: 'Included', value: '$includedOutlets'),
              if (approvalStatus != null)
                _StatBadge(label: 'Approval', value: approvalStatus),
            ],
          ),
          const SizedBox(height: 16),
          if (route.deliveryAlerts.isEmpty)
            const _EmptyMessage(
              icon: Icons.inventory_2_outlined,
              message: 'No pending deliveries need action for this route.',
            )
          else
            Column(
              children: route.deliveryAlerts.take(3).map((alert) {
                final isIncluded = alert.orderIds.any(route.deliveryOrderIds.contains);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DeliveryAlertTile(
                    alert: alert,
                    isIncluded: isIncluded,
                  ),
                );
              }).toList(),
            ),
          if (route.deliveryAlerts.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${route.deliveryAlerts.length - 3} more delivery alert(s)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSoft,
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (approval?.status == 'APPROVED' && !approvalVerified)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isLoading ? null : onConfirmPin,
                icon: const Icon(Icons.pin_rounded),
                label: const Text('Enter TM PIN'),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isLoading || route.deliveryAlerts.isEmpty
                    ? null
                    : onReviewAlerts,
                icon: const Icon(Icons.local_shipping_outlined),
                label: Text(
                  route.deliveryOrderIds.isEmpty
                      ? 'Review Delivery Alerts'
                      : 'Update Delivery Selection',
                ),
              ),
            ),
          if (approval?.pinExpiresAt != null && !approvalVerified) ...[
            const SizedBox(height: 10),
            Text(
              'Approval PIN expires: ${_formatDateTime(approval?.pinExpiresAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSoft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadRequestCard extends StatelessWidget {
  const _LoadRequestCard({
    required this.route,
    required this.isLoading,
    required this.onOpen,
  });

  final SalesRoute route;
  final bool isLoading;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final reservedDeliveryStock = _buildReservedDeliveryStock(route);
    final freeSaleStock = route.vanLoadRequest?.freeSaleStock ?? const <StockLine>[];
    final deliveryApprovalSatisfied =
        route.deliveryOrderIds.isEmpty || route.deliveryApproval?.pinVerifiedAt != null;
    final loadStatus = route.vanLoadRequest == null
        ? 'Not submitted'
        : _formatStatus(route.vanLoadRequest!.status);

    return _SectionCard(
      title: 'Van Load Request',
      subtitle:
          'Reserved delivery stock and free-sale stock are handled separately. Inventory only moves after TM approval.',
      accentColor: AppTheme.securitySlate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatBadge(
                label: 'Reserved delivery',
                value: '${reservedDeliveryStock.length}',
              ),
              _StatBadge(
                label: 'Free-sale lines',
                value: '${freeSaleStock.length}',
              ),
              _StatBadge(label: 'Load status', value: loadStatus),
            ],
          ),
          const SizedBox(height: 16),
          if (reservedDeliveryStock.isNotEmpty) ...[
            Text(
              'Reserved delivery stock',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            ...reservedDeliveryStock.take(4).map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _StockLineTile(line: line),
              ),
            ),
            if (reservedDeliveryStock.length > 4)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '+${reservedDeliveryStock.length - 4} more reserved line(s)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSoft,
                  ),
                ),
              ),
            const SizedBox(height: 14),
          ],
          if (route.vanLoadRequest?.managerNotes?.trim().isNotEmpty == true)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceTint,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                route.vanLoadRequest!.managerNotes!.trim(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          if (!deliveryApprovalSatisfied) ...[
            const SizedBox(height: 12),
            const _EmptyMessage(
              icon: Icons.lock_clock_outlined,
              message:
                  'Confirm the delivery approval PIN before you submit the van load request.',
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isLoading || !deliveryApprovalSatisfied ? null : onOpen,
              icon: const Icon(Icons.inventory_2_rounded),
              label: Text(
                route.vanLoadRequest == null ||
                        route.vanLoadRequest?.status == 'REJECTED'
                    ? 'Create Load Request'
                    : 'Review Load Request',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovedToStartCard extends StatelessWidget {
  const _ApprovedToStartCard({
    required this.route,
    required this.pinController,
    required this.isLoading,
    required this.onStart,
  });

  final SalesRoute route;
  final TextEditingController pinController;
  final bool isLoading;
  final Future<void> Function() onStart;

  @override
  Widget build(BuildContext context) {
    final loadRequest = route.vanLoadRequest;

    return Column(
      children: [
        _SectionCard(
          title: 'Approved To Start',
          subtitle:
              'All required approvals are complete. Enter the route-start PIN from the approved load request to officially begin the route.',
          accentColor: AppTheme.proceedOrderOlive,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _StatBadge(label: 'Status', value: _formatStatus(route.status)),
                  if (route.routeStartPinExpiresAt != null)
                    _StatBadge(
                      label: 'PIN expires',
                      value: _formatShortDateTime(route.routeStartPinExpiresAt),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Route Start PIN',
                  hintText: 'Enter the 6-digit warehouse PIN',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This PIN is time-bound. If it expires, TM needs to review the load again so a new start PIN can be issued.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSoft,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isLoading ? null : onStart,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Route'),
                ),
              ),
            ],
          ),
        ),
        if (loadRequest != null) ...[
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Approved Load Summary',
            subtitle: 'Use this as a final check before leaving the warehouse.',
            accentColor: AppTheme.securitySlate,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (loadRequest.deliveryStock.isNotEmpty) ...[
                  Text(
                    'Reserved delivery stock',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...loadRequest.deliveryStock.take(4).map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _StockLineTile(line: line),
                    ),
                  ),
                ],
                if (loadRequest.freeSaleStock.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Free-sale stock',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...loadRequest.freeSaleStock.take(4).map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _StockLineTile(line: line),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _InProgressCard extends StatelessWidget {
  const _InProgressCard({
    required this.route,
    required this.isLoading,
    required this.onClose,
  });

  final SalesRoute route;
  final bool isLoading;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionCard(
          title: 'Route In Progress',
          subtitle:
              'The route is active. Close it only after stock, returns, and route-end PIN details are ready.',
          accentColor: AppTheme.proceedOrderOlive,
          child: Column(
            children: [
              _KeyValueRow(
                icon: Icons.schedule_rounded,
                label: 'Started at',
                value: _formatDateTime(route.startedAt),
              ),
              const SizedBox(height: 12),
              _KeyValueRow(
                icon: Icons.warehouse_rounded,
                label: 'Warehouse',
                value: route.warehouseName ?? route.warehouseId,
              ),
              const SizedBox(height: 12),
              _KeyValueRow(
                icon: Icons.local_shipping_rounded,
                label: 'Vehicle',
                value: route.vehicleLabel ?? route.vehicleId ?? 'Not assigned',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isLoading ? null : onClose,
                  icon: const Icon(Icons.task_alt_rounded),
                  label: const Text('Close Route'),
                ),
              ),
            ],
          ),
        ),
        if (route.vanLoadRequest != null) ...[
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Loaded Stock',
            subtitle: 'Opening stock was captured from the approved van load.',
            accentColor: AppTheme.securitySlate,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (route.vanLoadRequest!.deliveryStock.isNotEmpty) ...[
                  Text(
                    'Reserved delivery stock',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...route.vanLoadRequest!.deliveryStock.take(4).map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _StockLineTile(line: line),
                    ),
                  ),
                ],
                if (route.vanLoadRequest!.freeSaleStock.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Free-sale stock',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...route.vanLoadRequest!.freeSaleStock.take(4).map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _StockLineTile(line: line),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ClosedCard extends StatelessWidget {
  const _ClosedCard({required this.route});

  final SalesRoute route;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Route Closed',
      subtitle:
          'This route has been completed. Start a new draft route when you are ready for the next working day.',
      accentColor: AppTheme.securitySlate,
      child: Column(
        children: [
          _KeyValueRow(
            icon: Icons.event_available_rounded,
            label: 'Closed at',
            value: _formatDateTime(route.closedAt),
          ),
          const SizedBox(height: 12),
          _KeyValueRow(
            icon: Icons.warehouse_rounded,
            label: 'Warehouse',
            value: route.warehouseName ?? route.warehouseId,
          ),
          const SizedBox(height: 12),
          _KeyValueRow(
            icon: Icons.local_shipping_rounded,
            label: 'Vehicle',
            value: route.vehicleLabel ?? route.vehicleId ?? 'Not assigned',
          ),
        ],
      ),
    );
  }
}

class _CreateRouteSheet extends StatefulWidget {
  const _CreateRouteSheet({required this.onSubmit});

  final Future<bool> Function({
    required String warehouseId,
    required String vehicleId,
  }) onSubmit;

  @override
  State<_CreateRouteSheet> createState() => _CreateRouteSheetState();
}

class _CreateRouteSheetState extends State<_CreateRouteSheet> {
  String? _warehouseId;
  String? _vehicleId;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return _BottomSheetShell(
      title: 'Create Draft Route',
      subtitle:
          'Only warehouses in your territory are shown. Choose one warehouse, then pick an available vehicle from that warehouse.',
      child: BlocBuilder<RouteSetupCubit, RouteSetupState>(
        builder: (context, state) {
          if (state is RouteSetupLoading || state is RouteSetupInitial) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is RouteSetupError) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ErrorPanel(message: state.message),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.read<RouteSetupCubit>().loadSetupOptions(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                  ),
                ),
              ],
            );
          }

          final loadedState = state as RouteSetupLoaded;
          final options = loadedState.options;
          final warehouses = options.warehouses;
          final selectedWarehouse = _findWarehouse(warehouses, _warehouseId);
          final vehicles = selectedWarehouse?.vehicles ?? const <RouteSetupVehicle>[];
          final availableVehicles = vehicles.where((vehicle) => vehicle.isAvailable).toList();
          final unavailableVehicles = vehicles
              .where((vehicle) => !vehicle.isAvailable)
              .toList();

          if (_warehouseId != null && selectedWarehouse == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _warehouseId = null;
                  _vehicleId = null;
                });
              }
            });
          } else if (_vehicleId != null &&
              !vehicles.any((vehicle) => vehicle.id == _vehicleId && vehicle.isAvailable)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _vehicleId = null;
                });
              }
            });
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (warehouses.isEmpty)
                const _EmptyMessage(
                  icon: Icons.warehouse_outlined,
                  message:
                      'No warehouses are available in your territory yet. Contact your manager before starting a route.',
                )
              else ...[
                DropdownButtonFormField<String>(
                  initialValue: _warehouseId,
                  decoration: const InputDecoration(
                    labelText: 'Warehouse',
                    hintText: 'Select a warehouse',
                  ),
                  items: warehouses
                      .map(
                        (warehouse) => DropdownMenuItem<String>(
                          value: warehouse.id,
                          child: Text(warehouse.name),
                        ),
                      )
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _warehouseId = value;
                            _vehicleId = null;
                          });
                        },
                ),
                if (selectedWarehouse != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceTint,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      selectedWarehouse.address.isEmpty
                          ? 'Vehicle list is filtered to this warehouse.'
                          : selectedWarehouse.address,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Available vehicles',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (availableVehicles.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.outlineWarm),
                      ),
                      child: Text(
                        'No vehicles available in this warehouse',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    Column(
                      children: availableVehicles.map((vehicle) {
                        final isSelected = vehicle.id == _vehicleId;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SelectableVehicleCard(
                            vehicle: vehicle,
                            isSelected: isSelected,
                            enabled: !_isSubmitting,
                            onTap: () {
                              setState(() {
                                _vehicleId = vehicle.id;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  if (unavailableVehicles.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Unavailable vehicles',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...unavailableVehicles.map(
                      (vehicle) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SelectableVehicleCard(
                          vehicle: vehicle,
                          isSelected: false,
                          enabled: false,
                          onTap: null,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSubmitting || warehouses.isEmpty
                      ? null
                      : () => _submit(context),
                  icon: const Icon(Icons.playlist_add_circle_rounded),
                  label: Text(_isSubmitting ? 'Creating...' : 'Save Draft Route'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (_warehouseId == null || _warehouseId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a warehouse to continue.')),
      );
      return;
    }
    if (_vehicleId == null || _vehicleId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an available vehicle to continue.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final created = await widget.onSubmit(
      warehouseId: _warehouseId!,
      vehicleId: _vehicleId!,
    );

    if (!context.mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (created) {
      Navigator.of(context).pop();
    }
  }
}

class _BeatPlanSheet extends StatefulWidget {
  const _BeatPlanSheet({
    required this.route,
    required this.onSubmit,
  });

  final SalesRoute route;
  final Future<bool> Function(List<String> selectedOutletIds) onSubmit;

  @override
  State<_BeatPlanSheet> createState() => _BeatPlanSheetState();
}

class _BeatPlanSheetState extends State<_BeatPlanSheet> {
  late final Set<String> _selectedOutletIds;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedOutletIds = widget.route.beatPlanItems
        .where((item) => item.isSelected)
        .map((item) => item.outletId)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final options = _buildBeatPlanOptions(widget.route);

    return _BottomSheetShell(
      title: 'Review Best Plan',
      subtitle:
          'Tick the outlets you want to cover today. The saved template is reused again every 4 weeks for the same warehouse, and you can still add more shops at any time.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatBadge(label: 'Available outlets', value: '${options.length}'),
              _StatBadge(label: 'Selected today', value: '${_selectedOutletIds.length}'),
            ],
          ),
          const SizedBox(height: 16),
          if (options.isEmpty)
            const _EmptyMessage(
              icon: Icons.store_mall_directory_outlined,
              message: 'No eligible outlets are available for this warehouse right now.',
            )
          else
            ...options.map((option) {
              final isSelected = _selectedOutletIds.contains(option.outletId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BeatPlanOptionTile(
                  option: option,
                  isSelected: isSelected,
                  onChanged: _isSubmitting
                      ? null
                      : (checked) {
                          setState(() {
                            if (checked) {
                              _selectedOutletIds.add(option.outletId);
                            } else {
                              _selectedOutletIds.remove(option.outletId);
                            }
                          });
                        },
                ),
              );
            }),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : () => _submit(context),
              icon: const Icon(Icons.save_outlined),
              label: Text(_isSubmitting ? 'Saving...' : 'Save Best Plan'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    setState(() {
      _isSubmitting = true;
    });

    final saved = await widget.onSubmit(_selectedOutletIds.toList()..sort());

    if (!context.mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (saved) {
      Navigator.of(context).pop();
    }
  }
}

class _DeliveryApprovalSheet extends StatefulWidget {
  const _DeliveryApprovalSheet({
    required this.route,
    required this.onSubmit,
  });

  final SalesRoute route;
  final Future<bool> Function(List<String> orderIds) onSubmit;

  @override
  State<_DeliveryApprovalSheet> createState() => _DeliveryApprovalSheetState();
}

class _DeliveryApprovalSheetState extends State<_DeliveryApprovalSheet> {
  late final Set<String> _selectedOrderIds;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedOrderIds = widget.route.deliveryOrderIds.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final alerts = widget.route.deliveryAlerts;

    return _BottomSheetShell(
      title: 'Review Delivery Alerts',
      subtitle:
          'Pick the ready-for-delivery outlets you want to include on this route. If you choose any, TM approval and PIN confirmation are required before continuing.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (alerts.isEmpty)
            const _EmptyMessage(
              icon: Icons.inventory_outlined,
              message: 'No ready-for-delivery alerts are available right now.',
            )
          else ...[
            ...alerts.map((alert) {
              final isSelected = alert.orderIds.every(_selectedOrderIds.contains) &&
                  alert.orderIds.isNotEmpty;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DeliverySelectionTile(
                  alert: alert,
                  isSelected: isSelected,
                  onChanged: _isSubmitting
                      ? null
                      : (selected) {
                          setState(() {
                            if (selected) {
                              _selectedOrderIds.addAll(alert.orderIds);
                            } else {
                              _selectedOrderIds.removeAll(alert.orderIds);
                            }
                          });
                        },
                ),
              );
            }),
            const SizedBox(height: 8),
            Text(
              _selectedOrderIds.isEmpty
                  ? 'You can skip delivery inclusion and continue with a free-sale-only load request.'
                  : '${_selectedOrderIds.length} order(s) selected for approval.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSoft,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : () => _submit(context),
                icon: const Icon(Icons.send_rounded),
                label: Text(
                  _isSubmitting
                      ? 'Sending...'
                      : _selectedOrderIds.isEmpty
                          ? 'Save Without Deliveries'
                          : 'Request TM Approval',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final orderIds = _selectedOrderIds.toList()..sort();

    if (orderIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No delivery orders were selected. Leave this sheet if you do not want to request delivery approval yet.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final sent = await widget.onSubmit(orderIds);

    if (!context.mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (sent) {
      Navigator.of(context).pop();
    }
  }
}

class _LoadRequestSheet extends StatefulWidget {
  const _LoadRequestSheet({
    required this.route,
    required this.onSubmit,
  });

  final Future<bool> Function(
    List<StockLine> deliveryStock,
    List<StockLine> freeSaleStock,
  ) onSubmit;
  final SalesRoute route;

  @override
  State<_LoadRequestSheet> createState() => _LoadRequestSheetState();
}

class _LoadRequestSheetState extends State<_LoadRequestSheet> {
  late final List<_StockLineFormData> _freeSaleLines;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final existingFreeSaleStock =
        widget.route.vanLoadRequest?.freeSaleStock ?? const <StockLine>[];
    _freeSaleLines = existingFreeSaleStock.isEmpty
        ? [_StockLineFormData()]
        : existingFreeSaleStock
              .map(
                (line) => _StockLineFormData(
                  initialProductId: line.productId,
                  initialProductName: line.productName,
                  initialQuantityCases: line.quantityCases,
                ),
              )
              .toList();
  }

  @override
  void dispose() {
    for (final line in _freeSaleLines) {
      line.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reservedDeliveryStock = _buildReservedDeliveryStock(widget.route);

    return _BottomSheetShell(
      title: 'Create Van Load Request',
      subtitle:
          'Delivery stock is reserved from approved delivery orders. Add extra free-sale stock if needed, then send the request for TM approval.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reserved delivery stock',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (reservedDeliveryStock.isEmpty)
            const _EmptyMessage(
              icon: Icons.local_shipping_outlined,
              message:
                  'No delivery stock is reserved for this route yet. You can still request free-sale stock.',
            )
          else
            ...reservedDeliveryStock.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _StockLineTile(line: line),
              ),
            ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Free-sale stock',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        setState(() {
                          _freeSaleLines.add(_StockLineFormData());
                        });
                      },
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._freeSaleLines.asMap().entries.map((entry) {
            final index = entry.key;
            final formData = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _StockLineEditor(
                data: formData,
                onRemove: _freeSaleLines.length == 1
                    ? null
                    : () {
                        setState(() {
                          final removed = _freeSaleLines.removeAt(index);
                          removed.dispose();
                        });
                      },
              ),
            );
          }),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : () => _submit(context),
              icon: const Icon(Icons.send_rounded),
              label: Text(_isSubmitting ? 'Submitting...' : 'Submit Load Request'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final freeSaleStock = _freeSaleLines
        .map((line) => line.build())
        .whereType<StockLine>()
        .toList();
    final reservedDeliveryStock = _buildReservedDeliveryStock(widget.route);

    if (reservedDeliveryStock.isEmpty && freeSaleStock.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one stock line before submitting the request.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final submitted = await widget.onSubmit(
      reservedDeliveryStock,
      freeSaleStock,
    );

    if (!context.mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (submitted) {
      Navigator.of(context).pop();
    }
  }
}

class _CloseRouteSheet extends StatefulWidget {
  const _CloseRouteSheet({
    required this.route,
    required this.onSubmit,
  });

  final SalesRoute route;
  final Future<bool> Function({
    required String pin,
    required List<CloseStockLineInput> closingStock,
    required List<ReturnItemInput> returnItems,
    String? varianceReason,
  }) onSubmit;

  @override
  State<_CloseRouteSheet> createState() => _CloseRouteSheetState();
}

class _CloseRouteSheetState extends State<_CloseRouteSheet> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _varianceReasonController = TextEditingController();
  final List<_ClosingStockFormData> _closingStockLines = [_ClosingStockFormData()];
  final List<_ReturnItemFormData> _returnItemLines = [_ReturnItemFormData()];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _pinController.dispose();
    _varianceReasonController.dispose();
    for (final line in _closingStockLines) {
      line.dispose();
    }
    for (final line in _returnItemLines) {
      line.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetShell(
      title: 'Close Route',
      subtitle:
          'Enter the route-end PIN, record your closing stock, log return items, and capture any variance notes before closing the route.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Route End PIN',
              hintText: 'Enter 6 digits',
              counterText: '',
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Closing stock',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        setState(() {
                          _closingStockLines.add(_ClosingStockFormData());
                        });
                      },
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._closingStockLines.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ClosingStockEditor(
                data: data,
                onRemove: _closingStockLines.length == 1
                    ? null
                    : () {
                        setState(() {
                          final removed = _closingStockLines.removeAt(index);
                          removed.dispose();
                        });
                      },
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Return items',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        setState(() {
                          _returnItemLines.add(_ReturnItemFormData());
                        });
                      },
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._returnItemLines.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReturnItemEditor(
                data: data,
                onRemove: _returnItemLines.length == 1
                    ? null
                    : () {
                        setState(() {
                          final removed = _returnItemLines.removeAt(index);
                          removed.dispose();
                        });
                      },
              ),
            );
          }),
          const SizedBox(height: 12),
          TextField(
            controller: _varianceReasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Variance reason',
              hintText: 'Add a note if counts do not match expectations',
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : () => _submit(context),
              icon: const Icon(Icons.done_all_rounded),
              label: Text(_isSubmitting ? 'Closing...' : 'Submit Route Close'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final pin = _pinController.text.trim();
    if (pin.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit route end PIN.')),
      );
      return;
    }

    final closingStock = _closingStockLines
        .map((item) => item.build())
        .whereType<CloseStockLineInput>()
        .toList();
    final returnItems = _returnItemLines
        .map((item) => item.build())
        .whereType<ReturnItemInput>()
        .toList();
    final varianceReason = _varianceReasonController.text.trim();

    setState(() {
      _isSubmitting = true;
    });

    final closed = await widget.onSubmit(
      pin: pin,
      closingStock: closingStock,
      returnItems: returnItems,
      varianceReason: varianceReason.isEmpty ? null : varianceReason,
    );

    if (!context.mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (closed) {
      Navigator.of(context).pop();
    }
  }
}

class _BottomSheetShell extends StatelessWidget {
  const _BottomSheetShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceWarm,
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.outlineWarm,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSoft,
                  ),
                ),
                const SizedBox(height: 22),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.outlineWarm),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBrownDark.withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSoft,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _SelectableVehicleCard extends StatelessWidget {
  const _SelectableVehicleCard({
    required this.vehicle,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final RouteSetupVehicle vehicle;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppTheme.primaryBrown
        : enabled
            ? AppTheme.outlineWarm
            : AppTheme.outlineWarm.withAlpha(140);

    return Material(
      color: enabled ? Colors.white : AppTheme.surfaceTint,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: isSelected ? 1.8 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: enabled
                      ? AppTheme.primaryBrown.withAlpha(18)
                      : AppTheme.textSoft.withAlpha(18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.local_shipping_rounded,
                  color: enabled ? AppTheme.primaryBrownDark : AppTheme.textSoft,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.label.isEmpty ? vehicle.registrationNumber : vehicle.label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: enabled ? AppTheme.textDark : AppTheme.textSoft,
                      ),
                    ),
                    if (vehicle.registrationNumber.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        vehicle.registrationNumber,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSoft,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      enabled
                          ? 'Available for this route'
                          : vehicle.unavailableReason ?? 'Unavailable',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: enabled ? AppTheme.proceedOrderOlive : AppTheme.promotionMutedRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? AppTheme.primaryBrown : AppTheme.textSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BeatPlanOptionTile extends StatelessWidget {
  const _BeatPlanOptionTile({
    required this.option,
    required this.isSelected,
    required this.onChanged,
  });

  final _BeatPlanOption option;
  final bool isSelected;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!isSelected),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? AppTheme.primaryBrown : AppTheme.outlineWarm,
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isSelected,
                onChanged: onChanged == null ? null : (value) => onChanged!(value ?? false),
                activeColor: AppTheme.primaryBrown,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.outletName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if ((option.ownerName ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        option.ownerName!.trim(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSoft,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoPill(label: _formatSource(option.source)),
                        if (option.pendingDeliveryCount > 0)
                          _InfoPill(
                            label: '${option.pendingDeliveryCount} delivery order(s)',
                            color: AppTheme.addToCartClay,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BeatPlanListTile extends StatelessWidget {
  const _BeatPlanListTile({required this.item});

  final BeatPlanItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarm,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.outletName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if ((item.ownerName ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.ownerName!.trim(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSoft,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(label: _formatSource(item.source)),
              if (item.pendingDeliveryCount > 0)
                _InfoPill(
                  label: '${item.pendingDeliveryCount} delivery order(s)',
                  color: AppTheme.addToCartClay,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeliveryAlertTile extends StatelessWidget {
  const _DeliveryAlertTile({
    required this.alert,
    required this.isIncluded,
  });

  final DeliveryAlert alert;
  final bool isIncluded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarm,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  alert.outletName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isIncluded)
                const _InfoPill(
                  label: 'Included',
                  color: AppTheme.proceedOrderOlive,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${alert.orderCount} ready-for-delivery order(s)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSoft,
            ),
          ),
          if (alert.products.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...alert.products.take(3).map(
              (product) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${product.productName} · ${product.quantityCases} case(s)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeliverySelectionTile extends StatelessWidget {
  const _DeliverySelectionTile({
    required this.alert,
    required this.isSelected,
    required this.onChanged,
  });

  final DeliveryAlert alert;
  final bool isSelected;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!isSelected),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? AppTheme.addToCartClay : AppTheme.outlineWarm,
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isSelected,
                onChanged: onChanged == null ? null : (value) => onChanged!(value ?? false),
                activeColor: AppTheme.addToCartClay,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.outletName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${alert.orderCount} ready-for-delivery order(s)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSoft,
                      ),
                    ),
                    if (alert.products.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...alert.products.take(3).map(
                        (product) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '${product.productName} · ${product.quantityCases} case(s)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockLineTile extends StatelessWidget {
  const _StockLineTile({required this.line});

  final StockLine line;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarm,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.productName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  line.productId,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSoft,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${line.quantityCases} case(s)',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.primaryBrownDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSoft,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    this.color = AppTheme.primaryBrown,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryBrownDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.promotionMutedRed.withAlpha(16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.promotionMutedRed,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StockLineEditor extends StatelessWidget {
  const _StockLineEditor({required this.data, this.onRemove});

  final _StockLineFormData data;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarm,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: data.productIdController,
                  decoration: const InputDecoration(labelText: 'Product ID'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: data.quantityCasesController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Cases'),
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: data.productNameController,
            decoration: const InputDecoration(labelText: 'Product Name'),
          ),
        ],
      ),
    );
  }
}

class _ClosingStockEditor extends StatelessWidget {
  const _ClosingStockEditor({required this.data, this.onRemove});

  final _ClosingStockFormData data;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarm,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: data.productIdController,
                  decoration: const InputDecoration(labelText: 'Product ID'),
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: data.productNameController,
            decoration: const InputDecoration(labelText: 'Product Name'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: data.quantityCasesController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Cases'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: data.quantityUnitsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Units'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReturnItemEditor extends StatelessWidget {
  const _ReturnItemEditor({required this.data, this.onRemove});

  final _ReturnItemFormData data;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarm,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: data.productIdController,
                  decoration: const InputDecoration(labelText: 'Product ID'),
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: data.productNameController,
            decoration: const InputDecoration(labelText: 'Product Name'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: data.quantityCasesController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Cases'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: data.reasonController,
                  decoration: const InputDecoration(labelText: 'Reason'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StockLineFormData {
  _StockLineFormData({
    String? initialProductId,
    String? initialProductName,
    int? initialQuantityCases,
  }) {
    productIdController.text = initialProductId ?? '';
    productNameController.text = initialProductName ?? '';
    quantityCasesController.text =
        initialQuantityCases == null ? '' : initialQuantityCases.toString();
  }

  final TextEditingController productIdController = TextEditingController();
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController quantityCasesController = TextEditingController();

  StockLine? build() {
    final productId = productIdController.text.trim();
    final productName = productNameController.text.trim();
    final quantityCases = int.tryParse(quantityCasesController.text.trim()) ?? 0;

    if (productId.isEmpty && productName.isEmpty && quantityCases == 0) {
      return null;
    }
    if (productId.isEmpty || productName.isEmpty || quantityCases <= 0) {
      return null;
    }

    return StockLine(
      productId: productId,
      productName: productName,
      quantityCases: quantityCases,
    );
  }

  void dispose() {
    productIdController.dispose();
    productNameController.dispose();
    quantityCasesController.dispose();
  }
}

class _ClosingStockFormData {
  final TextEditingController productIdController = TextEditingController();
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController quantityCasesController = TextEditingController();
  final TextEditingController quantityUnitsController = TextEditingController();

  CloseStockLineInput? build() {
    final productId = productIdController.text.trim();
    final productName = productNameController.text.trim();
    final quantityCases = int.tryParse(quantityCasesController.text.trim()) ?? 0;
    final quantityUnits = int.tryParse(quantityUnitsController.text.trim()) ?? 0;

    if (productId.isEmpty &&
        productName.isEmpty &&
        quantityCases == 0 &&
        quantityUnits == 0) {
      return null;
    }
    if (productId.isEmpty || productName.isEmpty) {
      return null;
    }

    return CloseStockLineInput(
      productId: productId,
      productName: productName,
      quantityCases: quantityCases,
      quantityUnits: quantityUnits,
    );
  }

  void dispose() {
    productIdController.dispose();
    productNameController.dispose();
    quantityCasesController.dispose();
    quantityUnitsController.dispose();
  }
}

class _ReturnItemFormData {
  final TextEditingController productIdController = TextEditingController();
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController quantityCasesController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();

  ReturnItemInput? build() {
    final productId = productIdController.text.trim();
    final productName = productNameController.text.trim();
    final quantityCases = int.tryParse(quantityCasesController.text.trim()) ?? 0;
    final reason = reasonController.text.trim();

    if (productId.isEmpty &&
        productName.isEmpty &&
        quantityCases == 0 &&
        reason.isEmpty) {
      return null;
    }
    if (productId.isEmpty || productName.isEmpty || reason.isEmpty) {
      return null;
    }

    return ReturnItemInput(
      productId: productId,
      productName: productName,
      quantityCases: quantityCases,
      reason: reason,
    );
  }

  void dispose() {
    productIdController.dispose();
    productNameController.dispose();
    quantityCasesController.dispose();
    reasonController.dispose();
  }
}

class _BeatPlanOption {
  const _BeatPlanOption({
    required this.outletId,
    required this.outletName,
    required this.ownerName,
    required this.source,
    required this.pendingDeliveryCount,
  });

  final String outletId;
  final String outletName;
  final String? ownerName;
  final String source;
  final int pendingDeliveryCount;
}

RouteSetupWarehouse? _findWarehouse(
  List<RouteSetupWarehouse> warehouses,
  String? warehouseId,
) {
  if (warehouseId == null || warehouseId.isEmpty) {
    return null;
  }

  for (final warehouse in warehouses) {
    if (warehouse.id == warehouseId) {
      return warehouse;
    }
  }
  return null;
}

List<_BeatPlanOption> _buildBeatPlanOptions(SalesRoute route) {
  final optionsByOutletId = <String, _BeatPlanOption>{};

  for (final outlet in route.availableOutlets) {
    optionsByOutletId[outlet.id] = _BeatPlanOption(
      outletId: outlet.id,
      outletName: outlet.outletName,
      ownerName: outlet.ownerName,
      source: 'MANUAL',
      pendingDeliveryCount: 0,
    );
  }

  for (final item in route.beatPlanItems) {
    optionsByOutletId[item.outletId] = _BeatPlanOption(
      outletId: item.outletId,
      outletName: item.outletName,
      ownerName: item.ownerName,
      source: item.source,
      pendingDeliveryCount: item.pendingDeliveryCount,
    );
  }

  final options = optionsByOutletId.values.toList();
  options.sort(
    (left, right) => left.outletName.toLowerCase().compareTo(right.outletName.toLowerCase()),
  );
  return options;
}

List<StockLine> _buildReservedDeliveryStock(SalesRoute route) {
  if (route.deliveryOrderIds.isEmpty) {
    return const [];
  }

  final stockByProductId = <String, StockLine>{};

  for (final alert in route.deliveryAlerts) {
    final containsIncludedOrder = alert.orderIds.any(route.deliveryOrderIds.contains);
    if (!containsIncludedOrder) {
      continue;
    }

    for (final product in alert.products) {
      final existing = stockByProductId[product.productId];
      if (existing == null) {
        stockByProductId[product.productId] = StockLine(
          productId: product.productId,
          productName: product.productName,
          quantityCases: product.quantityCases,
        );
      } else {
        stockByProductId[product.productId] = StockLine(
          productId: existing.productId,
          productName: existing.productName,
          quantityCases: existing.quantityCases + product.quantityCases,
        );
      }
    }
  }

  final lines = stockByProductId.values.toList();
  lines.sort(
    (left, right) => left.productName.toLowerCase().compareTo(right.productName.toLowerCase()),
  );
  return lines;
}

String _formatStatus(String status) {
  return status
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0]}${part.substring(1).toLowerCase()}')
      .join(' ');
}

String _formatSource(String source) {
  switch (source) {
    case 'DUE':
      return 'Due outlet';
    case 'DELIVERY':
      return 'Pending delivery';
    case 'TEMPLATE':
      return 'Saved template';
    case 'MANUAL':
    default:
      return 'Manual';
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return 'Not available';
  }

  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}

String _formatShortDateTime(DateTime? value) {
  if (value == null) {
    return 'Not set';
  }

  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}

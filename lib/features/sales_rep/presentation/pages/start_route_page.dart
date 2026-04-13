import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/sales_rep/data/services/route_service.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/route_cubit.dart';
import 'package:mobile/features/sales_rep/data/services/route_setup_service.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/route_setup_cubit.dart';

class StartRoutePage extends StatefulWidget {
  const StartRoutePage({super.key});

  @override
  State<StartRoutePage> createState() => _StartRoutePageState();
}

class _StartRoutePageState extends State<StartRoutePage> {
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
  late final TextEditingController _pinController = TextEditingController(
    text: '123456',
  );

  @override
  void dispose() {
    _pinController.dispose();
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
        } else if (state is RouteActionSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
          if (state.route?.status != 'APPROVED_TO_START') {
            _pinController.clear();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.surfaceWarm,
        appBar: AppBar(title: const Text('Start Route')),
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

            if (state is RouteError && route == null) {
              return _EmptyStateScaffold(
                title: 'Unable to load route',
                subtitle: state.message,
                primaryLabel: 'Try again',
                onPrimaryPressed: () => context.read<RouteCubit>().loadRoute(),
              );
            }

            return RefreshIndicator(
              color: AppTheme.primaryBrown,
              onRefresh: () => context.read<RouteCubit>().loadRoute(),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _OverviewCard(route: route, isLoading: isLoading),
                  const SizedBox(height: 18),
                  if (route == null)
                    _NoRouteSection(
                      onCreate: isLoading
                          ? null
                          : () => _openCreateRouteSheet(context),
                    )
                  else
                    _buildRouteStateSection(context, route, isLoading),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRouteStateSection(
    BuildContext context,
    SalesRoute route,
    bool isLoading,
  ) {
    switch (route.status) {
      case 'DRAFT':
      case 'AWAITING_LOAD_APPROVAL':
        return _DraftRouteSection(
          route: route,
          isLoading: isLoading,
          onSubmitLoadRequest: () => _openLoadRequestSheet(context, route),
        );
      case 'APPROVED_TO_START':
        return _ApprovedRouteSection(
          route: route,
          pinController: _pinController,
          isLoading: isLoading,
          onStart: () async {
            final pin = _pinController.text.trim();
            if (pin.length != 6) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enter the 6-digit start PIN.')),
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
        return _ActiveRouteSection(
          route: route,
          isLoading: isLoading,
          onEndRoute: () => _openCloseRouteSheet(context, route),
        );
      case 'CLOSED':
        return _ClosedRouteSection(route: route);
      default:
        return _StatusCard(
          title: 'Route status',
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
      builder: (_) => _CreateRouteSheet(
        onSubmit: ({required warehouseId, String? vehicleId}) {
          return context.read<RouteCubit>().createRoute(
            warehouseId: warehouseId,
            vehicleId: vehicleId,
          );
        },
      ),
    );
  }

  Future<void> _openLoadRequestSheet(
    BuildContext context,
    SalesRoute route,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LoadRequestSheet(
        onSubmit: ({required deliveryStock, required freeSaleStock}) {
          return context.read<RouteCubit>().submitLoadRequest(
            routeId: route.id,
            deliveryStock: deliveryStock,
            freeSaleStock: freeSaleStock,
          );
        },
      ),
    );
  }

  Future<void> _openCloseRouteSheet(
    BuildContext context,
    SalesRoute route,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CloseRouteSheet(
        onSubmit:
            ({
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

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.route, required this.isLoading});

  final SalesRoute? route;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.headerGradientStart, AppTheme.headerGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.alt_route_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Route Control',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            route == null
                ? 'No active route yet. Create one to request stock and begin your day.'
                : 'Current route status: ${_formatStatus(route!.status)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          if (route != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoPill(label: 'Warehouse', value: route!.warehouseId),
                _InfoPill(
                  label: 'Vehicle',
                  value: route!.vehicleId ?? 'Not assigned',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NoRouteSection extends StatelessWidget {
  const _NoRouteSection({required this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return _StatusCard(
      title: 'Ready to begin',
      subtitle:
          'Create a route, assign a warehouse, and request your van load.',
      accentColor: AppTheme.addToCartClay,
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onCreate,
          child: const Text('Start New Route'),
        ),
      ),
    );
  }
}

class _DraftRouteSection extends StatelessWidget {
  const _DraftRouteSection({
    required this.route,
    required this.isLoading,
    required this.onSubmitLoadRequest,
  });

  final SalesRoute route;
  final bool isLoading;
  final VoidCallback onSubmitLoadRequest;

  @override
  Widget build(BuildContext context) {
    final request = route.vanLoadRequest;
    final isAwaitingApproval = route.status == 'AWAITING_LOAD_APPROVAL';

    return _StatusCard(
      title: isAwaitingApproval ? 'Awaiting load approval' : 'Draft route',
      subtitle: isAwaitingApproval
          ? 'Your load request has been sent for review. You can reopen the sheet to resubmit if needed.'
          : 'Add delivery and free-sale stock to send this route for approval.',
      accentColor: isAwaitingApproval
          ? AppTheme.securitySlate
          : AppTheme.addToCartClay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (request != null) ...[
            _StockSummaryRow(
              title: 'Delivery stock lines',
              countLabel: '${request.deliveryStock.length} item(s)',
            ),
            const SizedBox(height: 8),
            _StockSummaryRow(
              title: 'Free-sale stock lines',
              countLabel: '${request.freeSaleStock.length} item(s)',
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: isLoading ? null : onSubmitLoadRequest,
                  child: Text(
                    isAwaitingApproval
                        ? 'Update Load Request'
                        : 'Submit Load Request',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () => context.read<RouteCubit>().loadRoute(),
                  child: const Text('Refresh'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ApprovedRouteSection extends StatelessWidget {
  const _ApprovedRouteSection({
    required this.route,
    required this.pinController,
    required this.isLoading,
    required this.onStart,
  });

  final SalesRoute route;
  final TextEditingController pinController;
  final bool isLoading;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final request = route.vanLoadRequest;

    return _StatusCard(
      title: 'Approved to start',
      subtitle:
          'Enter the 6-digit warehouse PIN to activate this route and begin selling.',
      accentColor: AppTheme.proceedOrderOlive,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (request != null) ...[
            _StockSummaryRow(
              title: 'Delivery stock lines',
              countLabel: '${request.deliveryStock.length} item(s)',
            ),
            const SizedBox(height: 8),
            _StockSummaryRow(
              title: 'Free-sale stock lines',
              countLabel: '${request.freeSaleStock.length} item(s)',
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.build, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🛠️ Dev Mode: Use PIN 123456 for testing',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.amber[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Start PIN',
              hintText: 'Enter 6 digits',
              prefixIcon: Icon(Icons.password_rounded),
              counterText: '',
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isLoading ? null : onStart,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.proceedOrderOlive,
              ),
              child: const Text('Start Route'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveRouteSection extends StatelessWidget {
  const _ActiveRouteSection({
    required this.route,
    required this.isLoading,
    required this.onEndRoute,
  });

  final SalesRoute route;
  final bool isLoading;
  final VoidCallback onEndRoute;

  @override
  Widget build(BuildContext context) {
    return _StatusCard(
      title: 'Route Active',
      subtitle:
          'Your route is currently live. When you finish the trip, submit closing stock and the warehouse PIN.',
      accentColor: const Color(0xFF2B8A57),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1FBF4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFAADABA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF2B8A57)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    route.startedAt == null
                        ? 'Route started successfully.'
                        : 'Started at ${_formatDateTime(route.startedAt)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF215D3E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isLoading ? null : onEndRoute,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2B8A57),
              ),
              child: const Text('End Route'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosedRouteSection extends StatelessWidget {
  const _ClosedRouteSection({required this.route});

  final SalesRoute route;

  @override
  Widget build(BuildContext context) {
    return _StatusCard(
      title: 'Route Closed',
      subtitle: 'This trip has already been closed and is ready for reporting.',
      accentColor: AppTheme.primaryBrownDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StockSummaryRow(title: 'Warehouse', countLabel: route.warehouseId),
          const SizedBox(height: 8),
          _StockSummaryRow(
            title: 'Vehicle',
            countLabel: route.vehicleId ?? 'Not assigned',
          ),
          const SizedBox(height: 8),
          _StockSummaryRow(
            title: 'Started at',
            countLabel: _formatDateTime(route.startedAt),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.read<RouteCubit>().loadRoute(),
              child: const Text('Refresh Summary'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockSummaryRow extends StatelessWidget {
  const _StockSummaryRow({required this.title, required this.countLabel});

  final String title;
  final String countLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          countLabel,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
        ),
      ],
    );
  }
}

class _EmptyStateScaffold extends StatelessWidget {
  const _EmptyStateScaffold({
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimaryPressed,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.route_outlined,
              size: 56,
              color: AppTheme.primaryBrown,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onPrimaryPressed,
              child: Text(primaryLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateRouteSheet extends StatelessWidget {
  const _CreateRouteSheet({required this.onSubmit});

  final Future<bool> Function({required String warehouseId, String? vehicleId})
  onSubmit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RouteSetupCubit()..loadTerritories(),
      child: _CreateRouteSheetContent(onSubmit: onSubmit),
    );
  }
}

class _CreateRouteSheetContent extends StatefulWidget {
  const _CreateRouteSheetContent({required this.onSubmit});

  final Future<bool> Function({required String warehouseId, String? vehicleId})
  onSubmit;

  @override
  State<_CreateRouteSheetContent> createState() =>
      _CreateRouteSheetContentState();
}

class _CreateRouteSheetContentState extends State<_CreateRouteSheetContent> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _vehicleController = TextEditingController();
  String? _selectedWarehouseId;
  bool _submitting = false;

  @override
  void dispose() {
    _vehicleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a warehouse.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final success = await widget.onSubmit(
      warehouseId: _selectedWarehouseId!,
      vehicleId: _vehicleController.text.trim().isEmpty
          ? null
          : _vehicleController.text.trim(),
    );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    if (success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Start a New Route',
      subtitle: 'Select your territory, warehouse, and optional vehicle.',
      child: Form(
        key: _formKey,
        child: BlocBuilder<RouteSetupCubit, RouteSetupState>(
          builder: (context, state) {
            return Column(
              children: [
                // Territory Dropdown
                _TerritoryDropdown(
                  state: state,
                  onTerritorySelected: (territoryId) {
                    context.read<RouteSetupCubit>().selectTerritory(
                      territoryId,
                    );
                  },
                ),
                const SizedBox(height: 14),
                // Warehouse Dropdown
                _WarehouseDropdown(
                  state: state,
                  selectedWarehouseId: _selectedWarehouseId,
                  onWarehouseSelected: (warehouseId) {
                    setState(() => _selectedWarehouseId = warehouseId);
                  },
                ),
                const SizedBox(height: 14),
                // Vehicle Field
                TextFormField(
                  controller: _vehicleController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle ID (optional)',
                    prefixIcon: Icon(Icons.local_shipping_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submitting || state is RouteSetupLoading
                            ? null
                            : _submit,
                        child: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                ),
                              )
                            : const Text('Create Route'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TerritoryDropdown extends StatelessWidget {
  const _TerritoryDropdown({
    required this.state,
    required this.onTerritorySelected,
  });

  final RouteSetupState state;
  final Function(String) onTerritorySelected;

  @override
  Widget build(BuildContext context) {
    if (state is RouteSetupLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.outlineWarm),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (state is RouteSetupError) {
      // 👇 This line is the magic fix. It creates a local "error" variable.
      final error = state as RouteSetupError;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          // 👇 Change this to 'error.message' instead of 'state.message'
          'Error: ${error.message}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.red[700]),
        ),
      );
    }

    final territories = switch (state) {
      RouteSetupTeritoriesLoaded(:final territories) => territories,
      RouteSetupWarehousesLoaded(:final territories) => territories,
      _ => <Territory>[],
    };

    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Territory',
        prefixIcon: Icon(Icons.map_outlined),
        hintText: 'Select a territory',
      ),
      items: territories.map((territory) {
        return DropdownMenuItem(
          value: territory.id,
          child: Text(territory.name),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onTerritorySelected(value);
        }
      },
      validator: (value) => value == null ? 'Territory is required.' : null,
    );
  }
}

class _WarehouseDropdown extends StatelessWidget {
  const _WarehouseDropdown({
    required this.state,
    required this.selectedWarehouseId,
    required this.onWarehouseSelected,
  });

  final RouteSetupState state;
  final String? selectedWarehouseId;
  final Function(String) onWarehouseSelected;

  @override
  Widget build(BuildContext context) {
    final isWarehouseLoadingState =
        state is RouteSetupLoading && state is! RouteSetupTeritoriesLoaded;
    final warehouses = switch (state) {
      RouteSetupWarehousesLoaded(:final warehouses) => warehouses,
      _ => <Warehouse>[],
    };
    final isDisabled =
        warehouses.isEmpty && state is! RouteSetupWarehousesLoaded;

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Warehouse',
        prefixIcon: isWarehouseLoadingState
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : const Icon(Icons.warehouse_outlined),
      ),
      items: warehouses.length > 0
          ? warehouses.map((warehouse) {
              return DropdownMenuItem(
                value: warehouse.id,
                child: Text(warehouse.name),
              );
            }).toList()
          : (state is! RouteSetupWarehousesLoaded
                ? [
                    DropdownMenuItem(
                      enabled: false,
                      value: '',
                      child: Text(
                        isWarehouseLoadingState
                            ? 'Loading warehouses...'
                            : 'Select a territory first',
                      ),
                    ),
                  ]
                : []),
      disabledHint: Text(
        isWarehouseLoadingState
            ? 'Loading warehouses...'
            : 'Select a territory first',
      ),
      value: selectedWarehouseId,
      onChanged: isDisabled
          ? null
          : (value) {
              if (value != null && value.isNotEmpty) {
                onWarehouseSelected(value);
              }
            },
      validator: (value) =>
          value == null || value.isEmpty ? 'Warehouse is required.' : null,
    );
  }
}

class _LoadRequestSheet extends StatefulWidget {
  const _LoadRequestSheet({required this.onSubmit});

  final Future<bool> Function({
    required List<StockLine> deliveryStock,
    required List<StockLine> freeSaleStock,
  })
  onSubmit;

  @override
  State<_LoadRequestSheet> createState() => _LoadRequestSheetState();
}

class _LoadRequestSheetState extends State<_LoadRequestSheet> {
  final List<_StockLineFormData> _deliveryItems = [_StockLineFormData()];
  final List<_StockLineFormData> _freeSaleItems = [_StockLineFormData()];
  bool _submitting = false;

  @override
  void dispose() {
    for (final item in [..._deliveryItems, ..._freeSaleItems]) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final deliveryStock = _deliveryItems
        .map((item) => item.build())
        .whereType<StockLine>()
        .toList();
    final freeSaleStock = _freeSaleItems
        .map((item) => item.build())
        .whereType<StockLine>()
        .toList();

    if (deliveryStock.isEmpty && freeSaleStock.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one stock line to continue.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final success = await widget.onSubmit(
      deliveryStock: deliveryStock,
      freeSaleStock: freeSaleStock,
    );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    if (success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Submit Load Request',
      subtitle: 'Add delivery stock and free-sale stock lines.',
      child: Column(
        children: [
          _EditableStockSection(
            title: 'Delivery Stock',
            items: _deliveryItems,
            addLabel: 'Add delivery item',
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 18),
          _EditableStockSection(
            title: 'Free Sale Stock',
            items: _freeSaleItems,
            addLabel: 'Add free-sale item',
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Text('Submit Request'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CloseRouteSheet extends StatefulWidget {
  const _CloseRouteSheet({required this.onSubmit});

  final Future<bool> Function({
    required String pin,
    required List<CloseStockLineInput> closingStock,
    required List<ReturnItemInput> returnItems,
    String? varianceReason,
  })
  onSubmit;

  @override
  State<_CloseRouteSheet> createState() => _CloseRouteSheetState();
}

class _CloseRouteSheetState extends State<_CloseRouteSheet> {
  late final TextEditingController _pinController = TextEditingController(
    text: '123456',
  );
  final TextEditingController _varianceReasonController =
      TextEditingController();
  final List<_ClosingStockFormData> _closingStock = [_ClosingStockFormData()];
  final List<_ReturnItemFormData> _returnItems = [_ReturnItemFormData()];
  bool _submitting = false;

  @override
  void dispose() {
    _pinController.dispose();
    _varianceReasonController.dispose();
    for (final item in _closingStock) {
      item.dispose();
    }
    for (final item in _returnItems) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _pinController.text.trim();
    if (pin.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit warehouse PIN.')),
      );
      return;
    }

    final closingStock = _closingStock
        .map((item) => item.build())
        .whereType<CloseStockLineInput>()
        .toList();
    if (closingStock.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one closing stock line.')),
      );
      return;
    }

    final returnItems = _returnItems
        .map((item) => item.build())
        .whereType<ReturnItemInput>()
        .toList();

    setState(() => _submitting = true);
    final success = await widget.onSubmit(
      pin: pin,
      closingStock: closingStock,
      returnItems: returnItems,
      varianceReason: _varianceReasonController.text.trim().isEmpty
          ? null
          : _varianceReasonController.text.trim(),
    );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    if (success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'End Route',
      subtitle:
          'Record closing stock, any return items, and confirm with the warehouse PIN.',
      child: Column(
        children: [
          _EditableClosingStockSection(
            title: 'Closing Stock',
            items: _closingStock,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 18),
          _EditableReturnSection(
            title: 'Return Items',
            items: _returnItems,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _varianceReasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Variance reason (optional)',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.build, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🛠️ Dev Mode: Use PIN 123456 for testing',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.amber[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Warehouse PIN',
              prefixIcon: Icon(Icons.password_outlined),
              counterText: '',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2B8A57),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Text('Close Route'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 54,
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
                const SizedBox(height: 18),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditableStockSection extends StatelessWidget {
  const _EditableStockSection({
    required this.title,
    required this.items,
    required this.addLabel,
    required this.onChanged,
  });

  final String title;
  final List<_StockLineFormData> items;
  final String addLabel;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarm,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < items.length; index++) ...[
            _StockLineEditor(
              data: items[index],
              onRemove: items.length == 1
                  ? null
                  : () {
                      items[index].dispose();
                      items.removeAt(index);
                      onChanged();
                    },
            ),
            if (index != items.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              items.add(_StockLineFormData());
              onChanged();
            },
            icon: const Icon(Icons.add_circle_outline),
            label: Text(addLabel),
          ),
        ],
      ),
    );
  }
}

class _EditableClosingStockSection extends StatelessWidget {
  const _EditableClosingStockSection({
    required this.title,
    required this.items,
    required this.onChanged,
  });

  final String title;
  final List<_ClosingStockFormData> items;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarm,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < items.length; index++) ...[
            _ClosingStockEditor(
              data: items[index],
              onRemove: items.length == 1
                  ? null
                  : () {
                      items[index].dispose();
                      items.removeAt(index);
                      onChanged();
                    },
            ),
            if (index != items.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              items.add(_ClosingStockFormData());
              onChanged();
            },
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add closing stock item'),
          ),
        ],
      ),
    );
  }
}

class _EditableReturnSection extends StatelessWidget {
  const _EditableReturnSection({
    required this.title,
    required this.items,
    required this.onChanged,
  });

  final String title;
  final List<_ReturnItemFormData> items;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarm,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < items.length; index++) ...[
            _ReturnItemEditor(
              data: items[index],
              onRemove: items.length == 1
                  ? null
                  : () {
                      items[index].dispose();
                      items.removeAt(index);
                      onChanged();
                    },
            ),
            if (index != items.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              items.add(_ReturnItemFormData());
              onChanged();
            },
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add return item'),
          ),
        ],
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
        color: Colors.white,
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
        color: Colors.white,
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
        color: Colors.white,
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
  final TextEditingController productIdController = TextEditingController();
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController quantityCasesController = TextEditingController();

  StockLine? build() {
    final productId = productIdController.text.trim();
    final productName = productNameController.text.trim();
    final quantityCases =
        int.tryParse(quantityCasesController.text.trim()) ?? 0;
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
    final quantityCases =
        int.tryParse(quantityCasesController.text.trim()) ?? 0;
    final quantityUnits =
        int.tryParse(quantityUnitsController.text.trim()) ?? 0;
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
    final quantityCases =
        int.tryParse(quantityCasesController.text.trim()) ?? 0;
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

String _formatStatus(String status) {
  return status
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0]}${part.substring(1).toLowerCase()}')
      .join(' ');
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

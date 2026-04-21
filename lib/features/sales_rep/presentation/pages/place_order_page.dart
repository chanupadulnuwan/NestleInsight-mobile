import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/sales_rep/data/services/route_service.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/rep_order_cubit.dart';

import 'order_page.dart';

class PlaceOrderPage extends StatefulWidget {
  const PlaceOrderPage({super.key, required this.routeId});

  final String routeId;

  @override
  State<PlaceOrderPage> createState() => _PlaceOrderPageState();
}

class _PlaceOrderPageState extends State<PlaceOrderPage> {
  final RouteService _routeService = RouteService();
  final TextEditingController _searchController = TextEditingController();

  SalesRoute? _route;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRoute() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final route = await _routeService.fetchMyRoute();
      if (!mounted) return;
      setState(() {
        _route = route;
        _isLoading = false;
      });
    } on RouteServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    }
  }

  List<_OrderOutletOption> get _outlets {
    final route = _route;
    if (route == null) {
      return const <_OrderOutletOption>[];
    }

    final byId = <String, _OrderOutletOption>{};

    void put(_OrderOutletOption option) {
      if (option.id.trim().isEmpty) return;
      byId.putIfAbsent(option.id, () => option);
    }

    for (final item in route.beatPlanItems.where((item) => item.isSelected)) {
      put(
        _OrderOutletOption(
          id: item.outletId,
          name: item.outletName,
          ownerName: item.ownerName,
          source: 'Today\'s Beat Plan',
          isBeatPlan: true,
        ),
      );
    }

    for (final outlet in route.warehouseShopOutlets) {
      put(
        _OrderOutletOption(
          id: outlet.id,
          name: outlet.outletName,
          ownerName: outlet.ownerName,
          source: 'Warehouse Shop',
        ),
      );
    }

    for (final outlet in route.allWarehouseOutlets) {
      put(
        _OrderOutletOption(
          id: outlet.id,
          name: outlet.outletName,
          ownerName: outlet.ownerName,
          source: 'Warehouse Shop',
        ),
      );
    }

    for (final outlet in route.availableOutlets) {
      put(
        _OrderOutletOption(
          id: outlet.id,
          name: outlet.outletName,
          ownerName: outlet.ownerName,
          source: 'Territory Outlet',
        ),
      );
    }

    final result = byId.values.toList();
    result.sort((left, right) {
      if (left.isBeatPlan != right.isBeatPlan) {
        return left.isBeatPlan ? -1 : 1;
      }
      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });
    return result;
  }

  List<_OrderOutletOption> get _filteredOutlets {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _outlets;
    }

    return _outlets
        .where((outlet) => outlet.searchText.contains(query))
        .toList(growable: false);
  }

  Future<void> _openOrder(_OrderOutletOption outlet) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) => RepOrderCubit(),
          child: OrderPage(
            routeId: widget.routeId,
            shopId: outlet.id,
            shopName: outlet.name,
          ),
        ),
      ),
    );
    await _loadRoute();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWarm,
      appBar: AppBar(title: const Text('Place an Order')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _ErrorState(message: _error!, onRetry: _loadRoute)
            : RefreshIndicator(
                onRefresh: _loadRoute,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search assigned shops',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_filteredOutlets.isEmpty)
                      const _EmptyState()
                    else
                      ..._filteredOutlets.map(
                        (outlet) => _OutletTile(
                          outlet: outlet,
                          onTap: () => _openOrder(outlet),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _OrderOutletOption {
  const _OrderOutletOption({
    required this.id,
    required this.name,
    required this.source,
    this.ownerName,
    this.isBeatPlan = false,
  });

  final String id;
  final String name;
  final String? ownerName;
  final String source;
  final bool isBeatPlan;

  String get searchText =>
      [name, ownerName ?? '', source].join(' ').toLowerCase();
}

class _OutletTile extends StatelessWidget {
  const _OutletTile({required this.outlet, required this.onTap});

  final _OrderOutletOption outlet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.outlineWarm),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.kCream,
                    borderRadius: BorderRadius.circular(14),
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
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              outlet.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppTheme.textDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          if (outlet.isBeatPlan)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.proceedOrderOlive.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Today',
                                style: TextStyle(
                                  color: AppTheme.proceedOrderOlive,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if ((outlet.ownerName ?? '').trim().isNotEmpty)
                            outlet.ownerName!.trim(),
                          outlet.source,
                        ].join(' - '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSoft,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppTheme.primaryBrown,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: const Text(
        'No assigned shops found for this route warehouse.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTheme.textSoft),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.promotionMutedRed),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

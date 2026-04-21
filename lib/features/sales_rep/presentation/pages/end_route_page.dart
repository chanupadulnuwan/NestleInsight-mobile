import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/sales_rep/data/services/route_return_progress_store.dart';
import 'package:mobile/features/sales_rep/data/services/route_service.dart';
import 'package:mobile/features/sales_rep/data/services/route_visit_progress_store.dart';

class EndRoutePage extends StatefulWidget {
  const EndRoutePage({super.key, this.routeId});

  final String? routeId;

  @override
  State<EndRoutePage> createState() => _EndRoutePageState();
}

class _EndRoutePageState extends State<EndRoutePage> {
  final RouteService _routeService = RouteService();
  final RouteReturnProgressStore _returnProgressStore =
      RouteReturnProgressStore();
  final RouteVisitProgressStore _visitProgressStore = RouteVisitProgressStore();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _varianceController = TextEditingController();
  final List<_ClosingLineData> _closingLines = [];

  SalesRoute? _route;
  Set<String> _completedOutletIds = {};
  List<RouteReturnItem> _localReturnItems = const [];
  bool _isLoading = true;
  bool _isRequestingPin = false;
  bool _isClosing = false;
  bool _pinRequested = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _varianceController.dispose();
    for (final line in _closingLines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _loadRoute() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final route = await _routeService.fetchMyRoute();
      final completedOutletIds = route == null
          ? <String>{}
          : await _visitProgressStore.completedOutletIds(route.id);
      final localReturnItems = route == null
          ? const <RouteReturnItem>[]
          : await _returnProgressStore.returnItems(route.id);
      if (!mounted) return;

      setState(() {
        _route = route;
        _completedOutletIds = completedOutletIds;
        _localReturnItems = localReturnItems;
        _pinRequested =
            route?.status == 'IN_PROGRESS' &&
            route?.routeStartPinExpiresAt != null;
        _replaceClosingLines(route);
        _isLoading = false;
      });
    } on RouteServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _completedOutletIds = {};
        _localReturnItems = const [];
        _isLoading = false;
      });
    }
  }

  void _replaceClosingLines(SalesRoute? route) {
    for (final line in _closingLines) {
      line.dispose();
    }
    _closingLines
      ..clear()
      ..addAll(_buildClosingLines(route));
  }

  List<_ClosingLineData> _buildClosingLines(SalesRoute? route) {
    final byProductId = <String, _ClosingLineData>{};
    final load = route?.vanLoadRequest;
    final sourceLines = [...?load?.deliveryStock, ...?load?.freeSaleStock];

    for (final stock in sourceLines) {
      final existing = byProductId[stock.productId];
      if (existing == null) {
        byProductId[stock.productId] = _ClosingLineData(
          productId: stock.productId,
          productName: stock.productName,
          quantityCases: stock.quantityCases,
        );
      } else {
        existing.setCases(existing.quantityCases + stock.quantityCases);
      }
    }

    return byProductId.values.toList()
      ..sort((a, b) => a.productName.compareTo(b.productName));
  }

  int get _pendingVisitCount {
    final route = _route;
    if (route == null) return 0;

    return route.beatPlanItems
        .where((item) => item.isSelected)
        .where(
          (item) =>
              item.visitStatus.toUpperCase() != 'COMPLETED' &&
              !_completedOutletIds.contains(item.outletId),
        )
        .length;
  }

  List<RouteReturnItem> get _combinedReturnItems {
    final route = _route;
    final items = <RouteReturnItem>[];
    final seen = <String>{};

    void add(RouteReturnItem item) {
      final key = [
        item.productId,
        item.productName,
        item.quantityCases,
        item.quantityUnits,
        item.reason,
        item.notes ?? '',
      ].join('|');
      if (seen.add(key)) {
        items.add(item);
      }
    }

    for (final item in route?.returnItems ?? const <RouteReturnItem>[]) {
      add(item);
    }
    for (final item in _localReturnItems) {
      add(item);
    }

    return items;
  }

  Future<void> _requestHandoverPin() async {
    final route = _route;
    if (route == null) return;

    setState(() {
      _isRequestingPin = true;
      _error = null;
    });

    try {
      final result = await _routeService.requestPinRefresh(routeId: route.id);
      if (!mounted) return;
      setState(() {
        _pinRequested = true;
        _isRequestingPin = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppTheme.proceedOrderOlive,
        ),
      );
      await _loadRoute();
    } on RouteServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _isRequestingPin = false;
      });
    }
  }

  Future<void> _closeRoute() async {
    final route = _route;
    if (route == null) return;

    final pin = _pinController.text.trim();
    if (pin.length != 6) {
      setState(() => _error = 'Enter the 6-digit handover PIN from your TM.');
      return;
    }

    final closingStock = _closingLines.map((line) => line.build()).toList();
    final returnItems = _combinedReturnItems
        .map(
          (item) => ReturnItemInput(
            productId: item.productId,
            productName: item.productName,
            quantityCases: item.quantityCases,
            quantityUnits: item.quantityUnits,
            unitType: item.unitType.isEmpty
                ? (item.quantityUnits > 0 ? 'UNIT' : 'CASE')
                : item.unitType,
            reason: item.reason.isEmpty ? 'RETURNED' : item.reason,
            notes: item.notes,
          ),
        )
        .toList();

    setState(() {
      _isClosing = true;
      _error = null;
    });

    try {
      final result = await _routeService.closeRoute(
        routeId: route.id,
        pin: pin,
        closingStock: closingStock,
        returnItems: returnItems,
        varianceReason: _varianceController.text.trim().isEmpty
            ? null
            : _varianceController.text.trim(),
      );
      await _visitProgressStore.clearRoute(route.id);
      await _returnProgressStore.clearRoute(route.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppTheme.proceedOrderOlive,
        ),
      );
      Navigator.of(context).pop(true);
    } on RouteServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _isClosing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = _route;

    return Scaffold(
      backgroundColor: AppTheme.surfaceWarm,
      appBar: AppBar(title: const Text('End Route')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : route == null
          ? _EmptyState(
              message: _error ?? 'No active route found.',
              onRetry: _loadRoute,
            )
          : RefreshIndicator(
              onRefresh: _loadRoute,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _RouteSummaryCard(route: route),
                  const SizedBox(height: 14),
                  if (_pendingVisitCount > 0)
                    _WarningPanel(
                      message:
                          'Complete $_pendingVisitCount remaining store visit(s) before route handover.',
                    ),
                  if (_pendingVisitCount > 0) const SizedBox(height: 14),
                  _ReturnItemsSection(items: _combinedReturnItems),
                  const SizedBox(height: 14),
                  _LoadLeftSection(
                    lines: _closingLines,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _varianceController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Variance notes (optional)',
                      hintText:
                          'Add a note if the final handover count has a gap',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  if (_pinRequested) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'TM handover PIN',
                        hintText: 'Enter 6 digits',
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.promotionMutedRed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed:
                        _pendingVisitCount > 0 || _isRequestingPin || _isClosing
                        ? null
                        : _requestHandoverPin,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.proceedOrderOlive,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.password_rounded),
                    label: Text(
                      _isRequestingPin
                          ? 'Requesting TM PIN...'
                          : _pinRequested
                          ? 'Request New TM PIN'
                          : 'Request TM PIN',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed:
                        _pendingVisitCount > 0 ||
                            !_pinRequested ||
                            _isRequestingPin ||
                            _isClosing
                        ? null
                        : _closeRoute,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryBrown,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.lock_open_rounded),
                    label: Text(
                      _isClosing ? 'Ending route...' : 'Confirm & End Route',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ClosingLineData {
  _ClosingLineData({
    required this.productId,
    required this.productName,
    required int quantityCases,
  }) {
    casesController.text = quantityCases.toString();
    unitsController.text = '0';
  }

  final String productId;
  final String productName;
  final TextEditingController casesController = TextEditingController();
  final TextEditingController unitsController = TextEditingController();

  int get quantityCases => int.tryParse(casesController.text.trim()) ?? 0;
  int get quantityUnits => int.tryParse(unitsController.text.trim()) ?? 0;

  void setCases(int value) {
    casesController.text = value.toString();
  }

  CloseStockLineInput build() {
    return CloseStockLineInput(
      productId: productId,
      productName: productName,
      quantityCases: quantityCases,
      quantityUnits: quantityUnits,
    );
  }

  void dispose() {
    casesController.dispose();
    unitsController.dispose();
  }
}

class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({required this.route});

  final SalesRoute route;

  @override
  Widget build(BuildContext context) {
    final startedAt = route.startedAt;
    final startedLabel = startedAt == null
        ? 'Not started'
        : '${startedAt.day}/${startedAt.month}/${startedAt.year} ${startedAt.hour.toString().padLeft(2, '0')}:${startedAt.minute.toString().padLeft(2, '0')}';

    return _SectionCard(
      title: 'Route Handover',
      subtitle: route.warehouseName ?? route.warehouseId,
      child: Column(
        children: [
          _SummaryRow(
            icon: Icons.schedule_rounded,
            label: 'Started',
            value: startedLabel,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            icon: Icons.storefront_outlined,
            label: 'Today shops',
            value:
                '${route.beatPlanItems.where((item) => item.isSelected).length} selected',
          ),
        ],
      ),
    );
  }
}

class _ReturnItemsSection extends StatelessWidget {
  const _ReturnItemsSection({required this.items});

  final List<RouteReturnItem> items;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Return Products',
      subtitle: 'Products collected from shops during the route',
      child: items.isEmpty
          ? const _InlineEmpty(
              message: 'No return products have been logged today.',
            )
          : Column(
              children: items
                  .map((item) => _ReturnItemTile(item: item))
                  .toList(),
            ),
    );
  }
}

class _ReturnItemTile extends StatelessWidget {
  const _ReturnItemTile({required this.item});

  final RouteReturnItem item;

  @override
  Widget build(BuildContext context) {
    final quantities = [
      if (item.quantityCases > 0) '${item.quantityCases} case(s)',
      if (item.quantityUnits > 0) '${item.quantityUnits} product(s)',
    ].join(' + ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.kCream.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.assignment_return_outlined,
            color: AppTheme.primaryBrown,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${quantities.isEmpty ? 'Returned stock' : quantities} - ${item.reason}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.notes != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.notes!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.textSoft),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadLeftSection extends StatelessWidget {
  const _LoadLeftSection({required this.lines, required this.onChanged});

  final List<_ClosingLineData> lines;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Load Left Products',
      subtitle: 'Final lorry stock to hand back to the warehouse',
      child: lines.isEmpty
          ? const _InlineEmpty(
              message: 'No approved lorry stock was found for this route.',
            )
          : Column(
              children: lines
                  .map(
                    (line) =>
                        _ClosingLineEditor(line: line, onChanged: onChanged),
                  )
                  .toList(),
            ),
    );
  }
}

class _ClosingLineEditor extends StatelessWidget {
  const _ClosingLineEditor({required this.line, required this.onChanged});

  final _ClosingLineData line;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            line.productName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: line.casesController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(
                    labelText: 'Cases',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: line.unitsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(
                    labelText: 'Products',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
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
        Icon(icon, size: 20, color: AppTheme.primaryBrown),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _WarningPanel extends StatelessWidget {
  const _WarningPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.promotionMutedRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.promotionMutedRed.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.promotionMutedRed,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.promotionMutedRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.kCream.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textSoft,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onRetry});

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
            const Icon(
              Icons.route_outlined,
              size: 42,
              color: AppTheme.primaryBrown,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

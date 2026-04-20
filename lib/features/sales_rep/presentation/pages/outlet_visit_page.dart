import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/promotions/domain/promotion.dart';
import 'package:mobile/features/promotions/presentation/pages/shop_promotion_detail_page.dart';
import 'package:mobile/features/sales_rep/data/services/outlet_visit_service.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/outlet_visit_cubit.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/rep_order_cubit.dart';
import 'package:mobile/features/sales_rep/presentation/pages/order_page.dart';
import 'package:mobile/features/sales_rep/presentation/widgets/visit/osa_product_card.dart';
import 'package:mobile/features/sales_rep/presentation/widgets/visit/visit_tab_bar.dart';

// ─────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────

const _kOsaIssueTags = [
  'Insufficient facing / shelf space',
  'Improper product placement',
  'No price tag displayed',
  'Damaged or dirty shelf',
  'Competitor blocking Nestlé space',
  'Shop owner reluctant to reorder',
  'Out-of-date stock on shelf',
];

const _kCompetitorQuestions = [
  'Competitor products dominating shelf',
  'Competitor pricing lower than Nestlé',
  'Competitor running active promotions',
  'Shop received better offer from competitor',
  'Competitor recently introduced new SKU',
];

const _kPlanogramQuestions = [
  'Planogram correctly implemented',
  'Products placed at correct eye level',
  'Brand block maintained as per guidelines',
  'All shelf labels and price cards in place',
  'Shelf cleanliness and product facing correct',
];

const _kPosmQuestions = [
  'All POS materials (shelf talkers, wobblers) in place',
  'POS materials in good condition (no tears/fading)',
  'Brand display and signage correctly set up',
  'Promotional materials updated for current campaign',
];

const _kFeedbackQuestions = [
  'Shop owner satisfaction with Nestlé products (1-5)',
  'Main customer complaint or request?',
  'Interest in expanding the Nestlé portfolio?',
  'Awareness of current Nestlé promotions?',
  'Recommended products to introduce to this outlet?',
];

const _kAnswerOptions = ['Yes', 'No', 'Partial'];

// ─────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────

class OutletVisitPage extends StatefulWidget {
  const OutletVisitPage({
    super.key,
    required this.routeId,
    required this.territoryId,
    this.initialOutlet,
    this.beatPlanOutlets = const [],
  });

  final String routeId;
  final String territoryId;
  final TerritoryOutlet? initialOutlet;

  /// Pre-populated from today's beat plan for shop selector
  final List<TerritoryOutlet> beatPlanOutlets;

  @override
  State<OutletVisitPage> createState() => _OutletVisitPageState();
}

class _OutletVisitPageState extends State<OutletVisitPage> {
  VisitTab _activeTab = VisitTab.stock;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = OutletVisitCubit();
        final outlet = widget.initialOutlet;
        if (outlet != null) {
          cubit.startVisit(
            routeId: widget.routeId,
            territoryId: widget.territoryId,
            outlet: outlet,
          );
        } else {
          cubit.loadOutlets();
        }
        return cubit;
      },
      child: Scaffold(
        backgroundColor: AppTheme.surfaceWarm,
        body: BlocConsumer<OutletVisitCubit, OutletVisitState>(
          listener: (context, state) {
            if (state is OutletVisitError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.promotionMutedRed,
              ));
            }
          },
          builder: (context, state) {
            if (state is OutletVisitInitial ||
                state is OutletVisitLoadingOutlets) {
              return _buildLoading();
            }
            if (state is OutletVisitError) {
              return _buildError(context, state);
            }
            if (state is OutletVisitOutletsLoaded) {
              return _buildOutletSelector(context, state);
            }
            if (state is OutletVisitInProgress) {
              return _buildVisitScreen(context, state);
            }
            if (state is OutletVisitCompleted) {
              return _buildCompleted(context, state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  // ── Loading ───────────────────────────────────────────────

  Widget _buildLoading() {
    return Column(
      children: [
        _VisitTopBar(shopName: 'Loading…', ownerName: '', address: ''),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Outlet Selector ───────────────────────────────────────

  Widget _buildOutletSelector(
    BuildContext context,
    OutletVisitOutletsLoaded state,
  ) {
    final outlets = state.outlets;
    return Column(
      children: [
        _VisitTopBar(shopName: 'Select Shop', ownerName: '', address: ''),
        if (outlets.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                'No outlets found in your territory.',
                style: TextStyle(color: AppTheme.textSoft),
              ),
            ),
          )
        else
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    "Today's Beat Plan",
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: outlets.length,
                    itemBuilder: (context, index) {
                      final outlet = outlets[index];
                      return _OutletCard(
                        outlet: outlet,
                        onTap: () {
                          context.read<OutletVisitCubit>().startVisit(
                                routeId: widget.routeId,
                                territoryId: widget.territoryId,
                                outlet: outlet,
                              );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Visit Screen ──────────────────────────────────────────

  Widget _buildVisitScreen(BuildContext context, OutletVisitInProgress state) {
    final outlet = state.selectedOutlet;
    final visit = state.visit;

    return Column(
      children: [
        _VisitTopBar(
          shopName: outlet?.outletName ?? visit.shopNameSnapshot,
          ownerName: outlet?.ownerName ?? '',
          address: outlet?.address ?? '',
          startTime: visit.visitStartedAt,
          lastOrderDate: visit.lastOrderDateSnapshot,
          recentOrders: state.recentOrders,
        ),
        VisitTabBar(
          activeTab: _activeTab,
          hasDelivery: visit.hasPendingDelivery,
          onTabChanged: (tab) => setState(() => _activeTab = tab),
        ),
        Expanded(child: _buildTabContent(context, state)),
        _buildBottomBar(context, state),
      ],
    );
  }

  Widget _buildTabContent(BuildContext context, OutletVisitInProgress state) {
    final cubit = context.read<OutletVisitCubit>();
    switch (_activeTab) {
      case VisitTab.stock:
        return _StockTabContent(
          state: state,
          cubit: cubit,
          onNext: () => setState(() => _activeTab = VisitTab.expiry),
        );
      case VisitTab.expiry:
        return _ExpiryTabContent(
          state: state,
          cubit: cubit,
          onNext: () => setState(() => _activeTab = VisitTab.issues),
        );
      case VisitTab.issues:
        return _IssuesTabContent(
          state: state,
          cubit: cubit,
          onNext: () => setState(() => _activeTab = VisitTab.promotions),
        );
      case VisitTab.promotions:
        return _PromotionsTabContent(
          state: state,
          cubit: cubit,
          onNext: () => setState(() => _activeTab = VisitTab.display),
        );
      case VisitTab.display:
        return _DisplayTabContent(
          state: state,
          cubit: cubit,
          onNext: () => setState(() => _activeTab = VisitTab.feedback),
        );
      case VisitTab.feedback:
        return _FeedbackTabContent(
          state: state,
          cubit: cubit,
          onNext: state.visit.hasPendingDelivery
              ? () => setState(() => _activeTab = VisitTab.delivery)
              : null,
        );
      case VisitTab.delivery:
        return _DeliveryTabContent(state: state, cubit: cubit);
    }
  }

  Widget _buildBottomBar(BuildContext context, OutletVisitInProgress state) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider(
                        create: (_) => RepOrderCubit(),
                        child: OrderPage(
                          routeId: state.routeId,
                          shopId: state.selectedOutlet?.id ?? '',
                          shopName: state.selectedOutlet?.outletName ??
                              state.visit.shopNameSnapshot,
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart_outlined, size: 16),
                label: const Text('Place Order'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryBrown,
                  side: const BorderSide(color: AppTheme.primaryBrown),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () =>
                    context.read<OutletVisitCubit>().completeVisit(state.visit.id),
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Done & Next Shop'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryBrown,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Completed ─────────────────────────────────────────────

  Widget _buildCompleted(BuildContext context, OutletVisitCompleted state) {
    final int min = state.durationSeconds ~/ 60;
    final int sec = state.durationSeconds % 60;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Color(0xFF88977F)),
            const SizedBox(height: 24),
            const Text(
              'Visit Completed!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBrown.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Duration: ${min.toString().padLeft(2, '0')}m ${sec.toString().padLeft(2, '0')}s',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.primaryBrown,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryBrown),
                child: const Text('Back to Route'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                // UI-only placeholder until smart route completes
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Smart route navigation coming soon.'),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryBrown,
                side: const BorderSide(color: AppTheme.primaryBrown),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Move to Next Shop →'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────

  Widget _buildError(BuildContext context, OutletVisitError state) {
    return Column(
      children: [
        _VisitTopBar(shopName: 'Error', ownerName: '', address: ''),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppTheme.promotionMutedRed, fontSize: 15)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      final outlet = widget.initialOutlet;
                      if (outlet != null) {
                        context.read<OutletVisitCubit>().startVisit(
                              routeId: widget.routeId,
                              territoryId: widget.territoryId,
                              outlet: outlet,
                            );
                      } else {
                        context.read<OutletVisitCubit>().loadOutlets();
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Top bar with timer
// ─────────────────────────────────────────────────────────────

class _VisitTopBar extends StatefulWidget {
  const _VisitTopBar({
    required this.shopName,
    required this.ownerName,
    required this.address,
    this.startTime,
    this.lastOrderDate,
    this.recentOrders = const [],
  });

  final String shopName;
  final String ownerName;
  final String address;
  final DateTime? startTime;
  final DateTime? lastOrderDate;
  final List<Map<String, dynamic>> recentOrders;

  @override
  State<_VisitTopBar> createState() => _VisitTopBarState();
}

class _VisitTopBarState extends State<_VisitTopBar> {
  Timer? _timer;
  int _seconds = 0;
  bool _showOrders = false;

  @override
  void initState() {
    super.initState();
    if (widget.startTime != null) {
      _seconds =
          DateTime.now().difference(widget.startTime!).inSeconds.abs();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _seconds++);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timerLabel {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryBrown,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.shopName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.ownerName.isNotEmpty)
                          Text(
                            widget.ownerName,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        if (widget.address.isNotEmpty)
                          Text(
                            widget.address,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (widget.startTime != null) ...[
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showOrders = !_showOrders),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_outlined,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  _timerLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.lastOrderDate != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Last order: ${_fmt(widget.lastOrderDate!)}',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                              ),
                            ),
                          ],
                          if (widget.recentOrders.isNotEmpty)
                            Text(
                              'History ▾',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white54,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Expandable recent order history
            if (_showOrders && widget.recentOrders.isNotEmpty)
              Container(
                color: Colors.white.withValues(alpha: 0.08),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Orders',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...widget.recentOrders.take(3).map((o) {
                      final date = o['placedAt'] != null
                          ? DateTime.tryParse(o['placedAt'].toString())
                          : null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          children: [
                            Text(
                              date != null ? _fmt(date) : '—',
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 11),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${o['currencyCode'] ?? 'LKR'} ${o['totalAmount'] ?? '—'}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${o['itemCount'] ?? 0} items',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 10),
                            ),
                            const Spacer(),
                            _OrderStatusBadge(
                                status: o['status']?.toString() ?? ''),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year.toString().substring(2)}';
}

class _OrderStatusBadge extends StatelessWidget {
  const _OrderStatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'SHIPPED':
      case 'READY_FOR_DELIVERY':
        color = Colors.greenAccent;
        break;
      case 'DELIVERED':
        color = Colors.white70;
        break;
      default:
        color = Colors.white38;
    }
    return Text(
      status.toLowerCase().replaceAll('_', ' '),
      style: TextStyle(color: color, fontSize: 10),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Outlet selector card
// ─────────────────────────────────────────────────────────────

class _OutletCard extends StatelessWidget {
  const _OutletCard({required this.outlet, required this.onTap});

  final TerritoryOutlet outlet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.outlineWarm),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBrown.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.store_outlined,
                    color: AppTheme.primaryBrown, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(outlet.outletName,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark)),
                    Text(outlet.ownerName,
                        style: const TextStyle(
                            color: AppTheme.textSoft, fontSize: 12)),
                    if (outlet.address != null && outlet.address!.isNotEmpty)
                      Text(outlet.address!,
                          style: const TextStyle(
                              color: AppTheme.textSoft, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill,
                  color: AppTheme.primaryBrown, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared section card
// ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineWarm, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSoft)),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.outlineWarm),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Next button
// ─────────────────────────────────────────────────────────────

class _NextButton extends StatelessWidget {
  const _NextButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryBrown,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 1 — Stock (OSA + Shelf/Backroom counts + Estimated Sales)
// ─────────────────────────────────────────────────────────────

class _StockTabContent extends StatelessWidget {
  const _StockTabContent({
    required this.state,
    required this.cubit,
    required this.onNext,
  });

  final OutletVisitInProgress state;
  final OutletVisitCubit cubit;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final oosCount = state.osaStatuses.values
        .where((v) => v.$1 == OSAStatus.outOfStock)
        .length;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: _SectionCard(
              title: 'Shelf Availability & Stock',
              subtitle: 'Mark each product and enter shelf + backroom counts',
              child: Column(
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: state.products.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFF5F0EB)),
                    itemBuilder: (context, index) {
                      final product = state.products[index];
                      final osa = state.osaStatuses[product.id] ??
                          (OSAStatus.none, null as String?);
                      final entry =
                          state.stockEntries[product.id] ?? const StockEntry();
                      final hist =
                          state.productQuantitiesSinceLastVisit[product.id] ??
                              0;

                      return OSAProductCard(
                        product: product,
                        status: osa.$1,
                        reason: osa.$2,
                        onStatusChanged: (status, reason) =>
                            cubit.updateOSAStatus(product.id, status, reason),
                        stockEntry: entry,
                        historicalQty: hist,
                        onStockChanged: (shelf, back) =>
                            cubit.updateStockEntry(product.id, shelf, back),
                      );
                    },
                  ),
                  InkWell(
                    onTap: () => cubit.markAllInStock(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(
                            top: BorderSide(color: AppTheme.outlineWarm)),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '✓ Mark All Products In Stock',
                        style: TextStyle(
                          color: AppTheme.textSoft,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (oosCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_outlined,
                    color: Color(0xFFD9B696), size: 16),
                const SizedBox(width: 6),
                Text(
                  '$oosCount product${oosCount > 1 ? 's' : ''} out of stock',
                  style: const TextStyle(
                      color: Color(0xFFD9B696),
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        _NextButton(label: 'Next: Expiry Check →', onTap: onNext),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 2 — Expiry Check
// ─────────────────────────────────────────────────────────────

class _ExpiryTabContent extends StatelessWidget {
  const _ExpiryTabContent({
    required this.state,
    required this.cubit,
    required this.onNext,
  });

  final OutletVisitInProgress state;
  final OutletVisitCubit cubit;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final flaggedCount =
        state.expiryFlags.values.where((v) => v).length;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: _SectionCard(
              title: 'Expiry Check',
              subtitle: 'Flag any products with expired or near-expiry items',
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: state.products.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF5F0EB)),
                itemBuilder: (context, index) {
                  final product = state.products[index];
                  final hasExpiry = state.expiryFlags[product.id] ?? false;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.outlineWarm),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: product.imageUrl != null
                              ? Image.network(product.imageUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.inventory_2_outlined,
                                      color: AppTheme.textSoft,
                                      size: 18))
                              : const Icon(Icons.inventory_2_outlined,
                                  color: AppTheme.textSoft, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(product.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                  fontSize: 13)),
                        ),
                        GestureDetector(
                          onTap: () =>
                              cubit.toggleExpiryFlag(product.id, !hasExpiry),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: hasExpiry
                                  ? const Color(0xFFD9534F).withValues(alpha: 0.12)
                                  : const Color(0xFF88977F).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: hasExpiry
                                    ? const Color(0xFFD9534F)
                                    : const Color(0xFF88977F),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  hasExpiry
                                      ? Icons.warning_amber
                                      : Icons.check_circle_outline,
                                  size: 14,
                                  color: hasExpiry
                                      ? const Color(0xFFD9534F)
                                      : const Color(0xFF88977F),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  hasExpiry ? 'Issue Found' : 'No Issues',
                                  style: TextStyle(
                                    color: hasExpiry
                                        ? const Color(0xFFD9534F)
                                        : const Color(0xFF88977F),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (flaggedCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.warning_amber,
                    color: Color(0xFFD9534F), size: 15),
                const SizedBox(width: 6),
                Text(
                  '$flaggedCount product${flaggedCount > 1 ? 's' : ''} with expiry issues',
                  style: const TextStyle(
                      color: Color(0xFFD9534F),
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        _NextButton(label: 'Next: OSA Issues →', onTap: onNext),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 3 — Issues & Competitor Insights
// ─────────────────────────────────────────────────────────────

class _IssuesTabContent extends StatefulWidget {
  const _IssuesTabContent({
    required this.state,
    required this.cubit,
    required this.onNext,
  });

  final OutletVisitInProgress state;
  final OutletVisitCubit cubit;
  final VoidCallback onNext;

  @override
  State<_IssuesTabContent> createState() => _IssuesTabContentState();
}

class _IssuesTabContentState extends State<_IssuesTabContent> {
  late final TextEditingController _competitorCtrl;

  @override
  void initState() {
    super.initState();
    _competitorCtrl =
        TextEditingController(text: widget.state.competitorNotes);
  }

  @override
  void dispose() {
    _competitorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                _SectionCard(
                  title: 'OSA Issues',
                  subtitle: 'Select all that apply',
                  child: Column(
                    children: [
                      ..._kOsaIssueTags.map((tag) {
                        final selected =
                            widget.state.selectedOsaIssueTags.contains(tag);
                        return _IssueCheckTile(
                          label: tag,
                          selected: selected,
                          onTap: () =>
                              widget.cubit.toggleOsaIssueTag(tag),
                        );
                      }),
                    ],
                  ),
                ),
                _SectionCard(
                  title: 'Competitor Insights',
                  subtitle: 'Tick all observed competitor activity',
                  child: Column(
                    children: [
                      ..._kCompetitorQuestions.map((q) {
                        final selected =
                            widget.state.selectedOsaIssueTags.contains(q);
                        return _IssueCheckTile(
                          label: q,
                          selected: selected,
                          onTap: () => widget.cubit.toggleOsaIssueTag(q),
                          activeColor: const Color(0xFF5B7FA6),
                        );
                      }),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: TextField(
                          controller: _competitorCtrl,
                          decoration: InputDecoration(
                            labelText: 'Additional competitor notes',
                            hintText:
                                'e.g. competitor brand name, specific offer…',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          maxLines: 3,
                          onChanged: widget.cubit.updateCompetitorNotes,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _NextButton(label: 'Next: Promotions →', onTap: widget.onNext),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _IssueCheckTile extends StatelessWidget {
  const _IssueCheckTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.activeColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppTheme.primaryBrown;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              onChanged: (_) => onTap(),
              activeColor: color,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontSize: 13,
                    color: selected ? color : AppTheme.textDark,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 4 — Promotions
// ─────────────────────────────────────────────────────────────

class _PromotionsTabContent extends StatelessWidget {
  const _PromotionsTabContent({
    required this.state,
    required this.cubit,
    required this.onNext,
  });

  final OutletVisitInProgress state;
  final OutletVisitCubit cubit;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final promotions = state.activePromotions;
    return Column(
      children: [
        Expanded(
          child: promotions.isEmpty
              ? const Center(
                  child: Text(
                    'No active promotions assigned to this territory.',
                    style: TextStyle(color: AppTheme.textSoft),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: promotions.length,
                  itemBuilder: (context, index) {
                    final promo = promotions[index];
                    final check = state.promotionChecks[promo.id] ??
                        const PromoCheckEntry();
                    return _PromoCheckCard(
                      promotion: promo,
                      check: check,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ShopPromotionDetailPage(promotion: promo),
                        ),
                      ),
                      onInformedChanged: (v) => cubit.updatePromoCheck(
                          promo.id,
                          informed: v),
                      onFeedbackChanged: (v) => cubit.updatePromoCheck(
                          promo.id,
                          feedback: v),
                    );
                  },
                ),
        ),
        _NextButton(label: 'Next: Display Check →', onTap: onNext),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _PromoCheckCard extends StatefulWidget {
  const _PromoCheckCard({
    required this.promotion,
    required this.check,
    required this.onTap,
    required this.onInformedChanged,
    required this.onFeedbackChanged,
  });

  final Promotion promotion;
  final PromoCheckEntry check;
  final VoidCallback onTap;
  final ValueChanged<bool> onInformedChanged;
  final ValueChanged<String> onFeedbackChanged;

  @override
  State<_PromoCheckCard> createState() => _PromoCheckCardState();
}

class _PromoCheckCardState extends State<_PromoCheckCard> {
  late final TextEditingController _feedbackCtrl;

  @override
  void initState() {
    super.initState();
    _feedbackCtrl =
        TextEditingController(text: widget.check.feedback);
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promo = widget.promotion;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: widget.onTap,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _PromoStatusChip(promotion: promo),
                      const Spacer(),
                      Text(promo.offerSummary,
                          style: const TextStyle(
                              color: AppTheme.primaryBrown,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      const SizedBox(width: 4),
                      const Icon(Icons.open_in_new,
                          size: 12, color: AppTheme.textSoft),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(promo.name,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark)),
                  if (promo.description != null &&
                      promo.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(promo.description!,
                        style: const TextStyle(
                            color: AppTheme.textSoft, fontSize: 12)),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    '${_fmtDate(promo.startDate)} → ${_fmtDate(promo.endDate)}',
                    style: const TextStyle(
                        color: AppTheme.textSoft, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.outlineWarm),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.record_voice_over_outlined,
                        size: 14, color: AppTheme.textSoft),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Did you educate the shop owner about this promotion?',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark),
                      ),
                    ),
                    Switch(
                      value: widget.check.informed,
                      onChanged: widget.onInformedChanged,
                      activeThumbColor: AppTheme.primaryBrown,
                      activeTrackColor: AppTheme.primaryBrown.withValues(alpha: 0.4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _feedbackCtrl,
                  decoration: InputDecoration(
                    labelText: 'Shop owner / customer feedback on this promo',
                    hintText: 'e.g. customers love the discount, no awareness…',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13),
                  onChanged: widget.onFeedbackChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _PromoStatusChip extends StatelessWidget {
  const _PromoStatusChip({required this.promotion});
  final Promotion promotion;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (promotion.normalizedStatus) {
      case 'scheduled':
        bg = const Color(0xFFE8F0FE);
        fg = const Color(0xFF2952CC);
        break;
      case 'disabled':
        bg = const Color(0xFFF3E5E5);
        fg = AppTheme.promotionMutedRed;
        break;
      case 'expired':
        bg = const Color(0xFFEDEDED);
        fg = AppTheme.textSoft;
        break;
      default:
        bg = const Color(0xFFE4F4E8);
        fg = const Color(0xFF4A7C59);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(promotion.statusLabel,
          style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 5 — Planogram & POSM Display
// ─────────────────────────────────────────────────────────────

class _DisplayTabContent extends StatelessWidget {
  const _DisplayTabContent({
    required this.state,
    required this.cubit,
    required this.onNext,
  });

  final OutletVisitInProgress state;
  final OutletVisitCubit cubit;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                _SectionCard(
                  title: 'Planogram Compliance',
                  subtitle: 'Assess shelf arrangement against brand guidelines',
                  child: _QuestionGroup(
                    questions: _kPlanogramQuestions,
                    answers: state.planogramAnswers,
                    onAnswerChanged: cubit.updatePlanogramAnswer,
                  ),
                ),
                _SectionCard(
                  title: 'POSM & Display Materials',
                  subtitle: 'Check point-of-sale materials',
                  child: _QuestionGroup(
                    questions: _kPosmQuestions,
                    answers: state.posmAnswers,
                    onAnswerChanged: cubit.updatePosmAnswer,
                  ),
                ),
                _SectionCard(
                  title: 'Photos',
                  subtitle: 'Capture shelf / display photos (saved locally until report upload)',
                  child: _PhotoGrid(
                    localPhotoPaths: state.localPhotoPaths,
                    onAddPhoto: (path) => cubit.addLocalPhoto(path),
                    onRemovePhoto: (path) => cubit.removeLocalPhoto(path),
                  ),
                ),
              ],
            ),
          ),
        ),
        _NextButton(label: 'Next: Outlet Feedback →', onTap: onNext),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _QuestionGroup extends StatelessWidget {
  const _QuestionGroup({
    required this.questions,
    required this.answers,
    required this.onAnswerChanged,
  });

  final List<String> questions;
  final Map<String, String> answers;
  final Function(String question, String answer) onAnswerChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: questions.map((q) {
        final current = answers[q];
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(q,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark)),
              const SizedBox(height: 8),
              Row(
                children: _kAnswerOptions.map((opt) {
                  final isSelected = current == opt;
                  Color bg, fg;
                  if (!isSelected) {
                    bg = const Color(0xFFF2E8DF);
                    fg = AppTheme.textSoft;
                  } else if (opt == 'Yes') {
                    bg = const Color(0xFFE4F4E8);
                    fg = const Color(0xFF4A7C59);
                  } else if (opt == 'No') {
                    bg = const Color(0xFFF3E5E5);
                    fg = AppTheme.promotionMutedRed;
                  } else {
                    bg = const Color(0xFFFFF3CD);
                    fg = const Color(0xFF9B6F00);
                  }
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onAnswerChanged(q, opt),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected
                              ? Border.all(color: fg.withValues(alpha: 0.5))
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(opt,
                            style: TextStyle(
                                color: fg,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Divider(height: 20, color: Color(0xFFF5F0EB)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.localPhotoPaths,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  final List<String> localPhotoPaths;
  final ValueChanged<String> onAddPhoto;
  final ValueChanged<String> onRemovePhoto;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.camera, imageQuality: 75);
    if (picked != null) onAddPhoto(picked.path);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (localPhotoPaths.isEmpty)
            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBrown.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.primaryBrown.withValues(alpha: 0.3),
                      style: BorderStyle.solid),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_camera_outlined,
                        color: AppTheme.primaryBrown),
                    SizedBox(width: 8),
                    Text('Tap to take a photo',
                        style: TextStyle(color: AppTheme.primaryBrown)),
                  ],
                ),
              ),
            )
          else ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: localPhotoPaths.length + 1,
              itemBuilder: (context, index) {
                if (index == localPhotoPaths.length) {
                  return GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBrown.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.primaryBrown.withValues(alpha: 0.3)),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              color: AppTheme.primaryBrown),
                          SizedBox(height: 4),
                          Text('Add',
                              style: TextStyle(
                                  color: AppTheme.primaryBrown, fontSize: 11)),
                        ],
                      ),
                    ),
                  );
                }
                final path = localPhotoPaths[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(File(path), fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => onRemovePhoto(path),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '${localPhotoPaths.length} photo${localPhotoPaths.length != 1 ? 's' : ''} — will upload when you submit the daily report',
            style: const TextStyle(color: AppTheme.textSoft, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 6 — Outlet Feedback
// ─────────────────────────────────────────────────────────────

class _FeedbackTabContent extends StatefulWidget {
  const _FeedbackTabContent({
    required this.state,
    required this.cubit,
    this.onNext,
  });

  final OutletVisitInProgress state;
  final OutletVisitCubit cubit;
  final VoidCallback? onNext;

  @override
  State<_FeedbackTabContent> createState() => _FeedbackTabContentState();
}

class _FeedbackTabContentState extends State<_FeedbackTabContent> {
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _noteCtrl =
        TextEditingController(text: widget.state.outletFeedbackNote);
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: _SectionCard(
              title: 'Outlet Feedback',
              subtitle: 'Capture shop owner insights for the daily report',
              child: Column(
                children: [
                  _QuestionGroup(
                    questions: _kFeedbackQuestions,
                    answers: widget.state.outletFeedbackAnswers,
                    onAnswerChanged: widget.cubit.updateOutletFeedbackAnswer,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: TextField(
                      controller: _noteCtrl,
                      decoration: InputDecoration(
                        labelText: 'Additional notes from shop owner',
                        hintText: 'Any specific requests, complaints, or suggestions…',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      maxLines: 4,
                      onChanged: widget.cubit.updateOutletFeedbackNote,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.onNext != null)
          _NextButton(
              label: 'Next: Delivery →', onTap: widget.onNext!),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 7 — Delivery (conditional)
// ─────────────────────────────────────────────────────────────

class _DeliveryTabContent extends StatelessWidget {
  const _DeliveryTabContent({
    required this.state,
    required this.cubit,
  });

  final OutletVisitInProgress state;
  final OutletVisitCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_shipping_outlined,
                size: 52, color: AppTheme.primaryBrown),
            const SizedBox(height: 16),
            const Text(
              'Pending Delivery',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'This outlet has a pending delivery order. Use the assisted order delivery flow to process it and record any returns.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSoft, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider(
                        create: (_) => RepOrderCubit(),
                        child: OrderPage(
                          routeId: state.routeId,
                          shopId: state.selectedOutlet?.id ?? '',
                          shopName: state.selectedOutlet?.outletName ??
                              state.visit.shopNameSnapshot,
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.delivery_dining_outlined),
                label: const Text('Process Delivery & Returns'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryBrown,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

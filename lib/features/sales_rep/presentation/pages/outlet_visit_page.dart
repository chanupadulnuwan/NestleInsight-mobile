import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mobile/features/promotions/data/services/promotion_service.dart';
import 'package:mobile/features/promotions/domain/promotion.dart';
import 'package:mobile/features/promotions/presentation/pages/shop_promotion_detail_page.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/rep_order_cubit.dart';
import 'package:mobile/features/sales_rep/presentation/pages/order_page.dart';

import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/sales_rep/data/services/outlet_visit_service.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/outlet_visit_cubit.dart';
import 'package:mobile/features/sales_rep/presentation/widgets/visit/visit_header.dart';
import 'package:mobile/features/sales_rep/presentation/widgets/visit/visit_summary_bar.dart';
import 'package:mobile/features/sales_rep/presentation/widgets/visit/visit_tab_bar.dart';
import 'package:mobile/features/sales_rep/presentation/widgets/visit/osa_tab_view.dart';

class OutletVisitPage extends StatefulWidget {
  const OutletVisitPage({
    super.key,
    required this.routeId,
    required this.territoryId,
    this.initialOutlet,
    this.smartRouteStopId,
    this.smartRouteSessionId,
  });

  final String routeId;
  final String territoryId;
  final TerritoryOutlet? initialOutlet;
  final String? smartRouteStopId;
  final String? smartRouteSessionId;

  @override
  State<OutletVisitPage> createState() => _OutletVisitPageState();
}

class _OutletVisitPageState extends State<OutletVisitPage> {
  VisitTab _activeTab = VisitTab.osa;
  late final Future<List<Promotion>> _promotionsFuture;

  @override
  void initState() {
    super.initState();
    _promotionsFuture = PromotionService().fetchTerritoryPromotions(
      widget.territoryId,
    );
  }

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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.promotionMutedRed,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is OutletVisitInitial ||
                state is OutletVisitLoadingOutlets) {
              return Column(
                children: [
                  const VisitHeader(shopName: 'Loading...', address: ''),
                  Expanded(child: _buildShimmerLoading()),
                ],
              );
            }

            if (state is OutletVisitError) {
              return Column(
                children: [
                  const VisitHeader(shopName: 'Error', address: ''),
                  Expanded(child: _buildErrorState(context, state)),
                ],
              );
            }

            if (state is OutletVisitOutletsLoaded) {
              return Column(
                children: [
                  const VisitHeader(shopName: 'Select Outlet', address: ''),
                  Expanded(child: _buildOutletsList(context, state)),
                ],
              );
            }

            if (state is OutletVisitInProgress) {
              return _buildInProgress(context, state);
            }

            if (state is OutletVisitCompleted) {
              return _buildSuccessState(context, state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildInProgress(BuildContext context, OutletVisitInProgress state) {
    final visit = state.visit;
    final shopName = state.selectedOutlet?.outletName ?? visit.shopNameSnapshot;
    final address = state.selectedOutlet?.address ?? '';

    // Formatting date as DD/M/YY like in mockup
    final lastOrderDateStr = visit.lastOrderDateSnapshot != null
        ? '${visit.lastOrderDateSnapshot!.day}/${visit.lastOrderDateSnapshot!.month}/${visit.lastOrderDateSnapshot!.year.toString().substring(2)}'
        : 'N/A';

    final suggestedOrderStr = visit.suggestedOrderJson != null
        ? 'LKR ${visit.suggestedOrderJson!['totalAmount']} | ${visit.suggestedOrderJson!['itemCount']} Items'
        : '24 Cases | No history';

    return Column(
      children: [
        VisitHeader(shopName: shopName, address: address),
        VisitSummaryBar(
          suggestedOrder: suggestedOrderStr,
          lastOrderDate: lastOrderDateStr,
          startTime: visit.visitStartedAt,
        ),
        VisitTabBar(
          activeTab: _activeTab,
          hasDelivery: visit.hasPendingDelivery,
          onTabChanged: (tab) => setState(() => _activeTab = tab),
        ),
        Expanded(child: _buildTabContent(context, state)),
      ],
    );
  }

  Widget _buildTabContent(BuildContext context, OutletVisitInProgress state) {
    switch (_activeTab) {
      case VisitTab.osa:
        return OSATabView(
          state: state,
          cubit: context.read<OutletVisitCubit>(),
          onNext: () => setState(() => _activeTab = VisitTab.order),
        );
      case VisitTab.order:
        return _buildOrderPlaceholder(context, state);
      case VisitTab.delivery:
        return _buildDeliveryPlaceholder();
      case VisitTab.promotions:
        return _buildPromotionsPlaceholder();
    }
  }

  Widget _buildOrderPlaceholder(
    BuildContext context,
    OutletVisitInProgress state,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: AppTheme.textSoft,
          ),
          const SizedBox(height: 16),
          const Text(
            'Order creation flow is ready.',
            style: TextStyle(color: AppTheme.textSoft),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider(
                    create: (_) => RepOrderCubit(),
                    child: OrderPage(
                      routeId: state.routeId,
                      shopId: state.selectedOutlet?.id ?? '',
                      shopName:
                          state.selectedOutlet?.outletName ??
                          state.visit.shopNameSnapshot,
                    ),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBrown,
            ),
            child: const Text(
              'Start Assisted Order',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 48),
          TextButton(
            onPressed: () {
              context.read<OutletVisitCubit>().completeVisit(
                visitId: state.visit.id,
                planogramOk: true,
                posmOk: true,
              );
            },
            child: const Text(
              'Complete Visit (Skip Order)',
              style: TextStyle(color: AppTheme.textSoft),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryPlaceholder() {
    return const Center(
      child: Text(
        'Active Deliveries will appear here.',
        style: TextStyle(color: AppTheme.textSoft),
      ),
    );
  }

  Widget _buildPromotionsPlaceholder() {
    return FutureBuilder<List<Promotion>>(
      future: _promotionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_offer_outlined,
                    size: 52,
                    color: AppTheme.textSoft,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textSoft),
                  ),
                ],
              ),
            ),
          );
        }

        final promotions = snapshot.data ?? const <Promotion>[];
        if (promotions.isEmpty) {
          return const Center(
            child: Text(
              'No promotions are assigned to this territory right now.',
              style: TextStyle(color: AppTheme.textSoft),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: promotions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final promotion = promotions[index];
            return InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ShopPromotionDetailPage(promotion: promotion),
                ),
              ),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.outlineWarm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _PromotionStatusChip(promotion: promotion),
                        const Spacer(),
                        Text(
                          promotion.offerSummary,
                          style: const TextStyle(
                            color: AppTheme.primaryBrown,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      promotion.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    if (promotion.description != null &&
                        promotion.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        promotion.description!,
                        style: const TextStyle(color: AppTheme.textSoft),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: AppTheme.textSoft,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${_formatPromotionDate(promotion.startDate)} - ${_formatPromotionDate(promotion.endDate)}',
                            style: const TextStyle(
                              color: AppTheme.textSoft,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatPromotionDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, OutletVisitError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state.message,
              style: const TextStyle(
                color: AppTheme.promotionMutedRed,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final outlet = widget.initialOutlet;
                if (outlet != null) {
                  context.read<OutletVisitCubit>().startVisit(
                    routeId: widget.routeId,
                    territoryId: widget.territoryId,
                    outlet: outlet,
                  );
                  return;
                }
                context.read<OutletVisitCubit>().loadOutlets();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutletsList(
    BuildContext context,
    OutletVisitOutletsLoaded state,
  ) {
    if (state.outlets.isEmpty) {
      return const Center(child: Text('No outlets found in your territory.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Select an outlet to visit',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSoft,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: state.outlets.length,
            itemBuilder: (context, index) {
              final outlet = state.outlets[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: AppTheme.outlineWarm),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: InkWell(
                  onTap: () {
                    context.read<OutletVisitCubit>().startVisit(
                      routeId: widget.routeId,
                      territoryId: widget.territoryId,
                      outlet: outlet,
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          outlet.outletName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 16,
                              color: AppTheme.textSoft,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              outlet.ownerName,
                              style: const TextStyle(color: AppTheme.textSoft),
                            ),
                          ],
                        ),
                        if (outlet.address != null &&
                            outlet.address!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: AppTheme.textSoft,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  outlet.address!,
                                  style: const TextStyle(
                                    color: AppTheme.textSoft,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState(BuildContext context, OutletVisitCompleted state) {
    final int minutes = state.durationSeconds ~/ 60;
    final int seconds = state.durationSeconds % 60;
    final String timeStr =
        '${minutes.toString().padLeft(2, '0')} min ${seconds.toString().padLeft(2, '0')} sec';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 80,
              color: AppTheme.proceedOrderOlive,
            ),
            const SizedBox(height: 24),
            Text(
              state.message,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.securitySlate.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Duration: $timeStr',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.securitySlate,
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
                  backgroundColor: AppTheme.primaryBrown,
                ),
                child: const Text('Back to Route'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromotionStatusChip extends StatelessWidget {
  const _PromotionStatusChip({required this.promotion});

  final Promotion promotion;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color textColor;

    switch (promotion.normalizedStatus) {
      case 'scheduled':
        backgroundColor = const Color(0xFFE8F0FE);
        textColor = const Color(0xFF2952CC);
        break;
      case 'disabled':
        backgroundColor = const Color(0xFFF3E5E5);
        textColor = AppTheme.promotionMutedRed;
        break;
      case 'expired':
        backgroundColor = const Color(0xFFEDEDED);
        textColor = AppTheme.textSoft;
        break;
      case 'draft':
        backgroundColor = const Color(0xFFF8EEDB);
        textColor = AppTheme.primaryBrown;
        break;
      default:
        backgroundColor = const Color(0xFFE4F4E8);
        textColor = AppTheme.proceedOrderOlive;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        promotion.statusLabel,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

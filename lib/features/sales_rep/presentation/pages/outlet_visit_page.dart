import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/place_order_cubit.dart';
import 'package:mobile/features/sales_rep/presentation/pages/order_page.dart';

import '../../../../core/theme/app_theme.dart';
import '../cubit/outlet_visit_cubit.dart';

class OutletVisitPage extends StatelessWidget {
  final String routeId;
  final String territoryId;

  const OutletVisitPage({
    super.key,
    required this.routeId,
    required this.territoryId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OutletVisitCubit()..loadOutlets(),
      child: Scaffold(
        backgroundColor: AppTheme.surfaceWarm,
        appBar: AppBar(title: const Text('Outlet Visit')),
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
            if (state is OutletVisitInitial || state is OutletVisitLoadingOutlets) {
              return _buildShimmerLoading();
            }

            if (state is OutletVisitError) {
              return _buildErrorState(context, state);
            }

            if (state is OutletVisitOutletsLoaded) {
              return _buildOutletsList(context, state);
            }

            if (state is OutletVisitInProgress) {
              return _buildInProgressForm(context, state);
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
              style: const TextStyle(color: AppTheme.promotionMutedRed, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<OutletVisitCubit>().loadOutlets(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutletsList(BuildContext context, OutletVisitOutletsLoaded state) {
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
            style: TextStyle(fontSize: 16, color: AppTheme.textSoft, fontWeight: FontWeight.bold),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    context.read<OutletVisitCubit>().startVisit(
                          routeId: routeId,
                          territoryId: territoryId,
                          outlet: outlet,
                        );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          outlet.outletName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 16, color: AppTheme.textSoft),
                            const SizedBox(width: 4),
                            Text(outlet.ownerName, style: const TextStyle(color: AppTheme.textSoft)),
                          ],
                        ),
                        if (outlet.address != null && outlet.address!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, size: 16, color: AppTheme.textSoft),
                              const SizedBox(width: 4),
                              Expanded(child: Text(outlet.address!, style: const TextStyle(color: AppTheme.textSoft))),
                            ],
                          ),
                        ]
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

  Widget _buildInProgressForm(BuildContext context, OutletVisitInProgress state) {
    return _InProgressFormContent(
      state: state,
      onSubmit: (planogramOk, posmOk, osaNote, feedback) {
        context.read<OutletVisitCubit>().completeVisit(
              visitId: state.visit.id,
              planogramOk: planogramOk,
              posmOk: posmOk,
              osaNote: osaNote,
              feedback: feedback,
            );
      },
    );
  }

  Widget _buildSuccessState(BuildContext context, OutletVisitCompleted state) {
    final int minutes = state.durationSeconds ~/ 60;
    final int seconds = state.durationSeconds % 60;
    final String timeStr = '${minutes.toString().padLeft(2, '0')} min ${seconds.toString().padLeft(2, '0')} sec';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: AppTheme.proceedOrderOlive),
            const SizedBox(height: 24),
            Text(
              state.message,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.securitySlate.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Duration: $timeStr',
                style: const TextStyle(fontSize: 16, color: AppTheme.securitySlate, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryBrown),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InProgressFormContent extends StatefulWidget {
  final OutletVisitInProgress state;
  final void Function(bool planogramOk, bool posmOk, String? osaNote, String? feedback) onSubmit;

  const _InProgressFormContent({required this.state, required this.onSubmit});

  @override
  State<_InProgressFormContent> createState() => _InProgressFormContentState();
}

class _InProgressFormContentState extends State<_InProgressFormContent> {
  bool _planogramOk = false;
  bool _posmOk = false;
  final TextEditingController _osaController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void dispose() {
    _osaController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outletName = widget.state.selectedOutlet?.outletName ?? widget.state.visit.shopNameSnapshot;
    final canPlaceAssistedOrder = widget.state.selectedOutlet != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.proceedOrderOlive.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.proceedOrderOlive),
            ),
            child: Row(
              children: [
                const Icon(Icons.play_circle_fill, color: AppTheme.proceedOrderOlive),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Visit in progress — $outletName',
                    style: const TextStyle(color: AppTheme.proceedOrderOlive, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (canPlaceAssistedOrder) ...[
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BlocProvider(
                      create: (_) => PlaceOrderCubit(),
                      child: OrderPage(
                        routeId: widget.state.routeId,
                        shopId: widget.state.selectedOutlet!.id,
                        shopName: outletName,
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_cart_checkout),
              label: const Text('Place Assisted Order'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryBrownDark,
                side: const BorderSide(color: AppTheme.primaryBrown),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
          ],
          const Text('OSA Notes', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          TextField(
            controller: _osaController,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter Out of Stock availability notes...',
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Planogram OK'),
            value: _planogramOk,
            onChanged: (val) => setState(() => _planogramOk = val ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppTheme.primaryBrown,
          ),
          CheckboxListTile(
            title: const Text('POSM OK'),
            value: _posmOk,
            onChanged: (val) => setState(() => _posmOk = val ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppTheme.primaryBrown,
          ),
          const SizedBox(height: 16),
          const Text('Store Feedback', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          TextField(
            controller: _feedbackController,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Any specific feedback from the outlet?',
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () {
              widget.onSubmit(_planogramOk, _posmOk, _osaController.text, _feedbackController.text);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.proceedOrderOlive,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Complete Visit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

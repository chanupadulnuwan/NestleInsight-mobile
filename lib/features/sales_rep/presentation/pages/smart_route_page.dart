import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/smart_route_cubit.dart';

class SmartRoutePage extends StatelessWidget {
  const SmartRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SmartRouteCubit()..loadSession(),
      child: Scaffold(
        backgroundColor: AppTheme.surfaceWarm,
        appBar: AppBar(title: const Text('Smart Route')),
        body: BlocConsumer<SmartRouteCubit, SmartRouteState>(
          listener: (context, state) {
            if (state is SmartRouteError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.promotionMutedRed,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is SmartRouteInitial || state is SmartRouteLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SmartRouteError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message, style: const TextStyle(color: AppTheme.promotionMutedRed)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<SmartRouteCubit>().loadSession(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is SmartRouteLoaded) {
              if (state.isAllDone) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, size: 64, color: AppTheme.proceedOrderOlive),
                      const SizedBox(height: 16),
                      const Text(
                        'All stops completed for today!',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Great work!',
                        style: TextStyle(fontSize: 16, color: AppTheme.textSoft),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryBrown),
                        child: const Text('Back to Home'),
                      ),
                    ],
                  ),
                );
              }

              final stop = state.currentStop;
              if (stop == null) {
                return const Center(child: Text('No next stop available.'));
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: AppTheme.outlineWarm),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Date: ${state.session.routeDate.toLocal().toString().split(' ')[0]}',
                              style: const TextStyle(color: AppTheme.textDark),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.securitySlate.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                state.session.status.toUpperCase(),
                                style: const TextStyle(color: AppTheme.securitySlate, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: AppTheme.outlineWarm),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stop.outletId,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.securitySlate.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${stop.distanceKm ?? 0.0} km away',
                                    style: const TextStyle(color: AppTheme.securitySlate),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBrown.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '~${stop.etaMinutes ?? 0} min',
                                    style: const TextStyle(color: AppTheme.primaryBrown),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text('Priority Score', style: TextStyle(color: AppTheme.textSoft, fontSize: 12)),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: stop.priorityScore ?? 0.0,
                              backgroundColor: AppTheme.outlineWarm,
                              color: AppTheme.primaryBrown,
                            ),
                            const SizedBox(height: 24),
                            if (stop.status == 'pending') ...[
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () {
                                    context.read<SmartRouteCubit>().startCurrentStop(stop.id);
                                  },
                                  style: FilledButton.styleFrom(backgroundColor: AppTheme.proceedOrderOlive),
                                  child: const Text('Start Visit'),
                                ),
                              ),
                            ] else if (stop.status == 'in_progress') ...[
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () {
                                    context.read<SmartRouteCubit>().completeCurrentStop(stop.id);
                                  },
                                  style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryBrown),
                                  child: const Text('Complete'),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  _showSkipBottomSheet(context, stop.id);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.promotionMutedRed,
                                  side: const BorderSide(color: AppTheme.promotionMutedRed),
                                ),
                                child: const Text('Skip'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showSkipBottomSheet(BuildContext parentContext, String stopId) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
          ),
          child: SkipBottomSheetContent(
            onSubmit: (reasonCode, freeText) {
              parentContext.read<SmartRouteCubit>().skipCurrentStop(
                stopId: stopId,
                reasonCode: reasonCode,
                freeText: freeText,
              );
              Navigator.of(bottomSheetContext).pop();
            },
          ),
        );
      },
    );
  }
}

class SkipBottomSheetContent extends StatefulWidget {
  final void Function(String reasonCode, String freeText) onSubmit;

  const SkipBottomSheetContent({super.key, required this.onSubmit});

  @override
  State<SkipBottomSheetContent> createState() => _SkipBottomSheetContentState();
}

class _SkipBottomSheetContentState extends State<SkipBottomSheetContent> {
  String? _selectedReason;
  final TextEditingController _noteController = TextEditingController();

  final List<String> _reasons = [
    'CUSTOMER_CLOSED',
    'NO_STOCK_NEEDED',
    'ALREADY_VISITED',
    'OTHER',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Skip Stop',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedReason,
            decoration: const InputDecoration(
              labelText: 'Reason',
              border: OutlineInputBorder(),
            ),
            items: _reasons.map((reason) {
              return DropdownMenuItem(
                value: reason,
                child: Text(reason),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedReason = value;
              });
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Note (Optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _selectedReason == null
                ? null
                : () {
                    widget.onSubmit(_selectedReason!, _noteController.text);
                  },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.promotionMutedRed),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

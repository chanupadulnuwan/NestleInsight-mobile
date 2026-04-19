import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/services/outlet_visit_service.dart';
import '../../data/services/smart_route_service.dart';
import 'outlet_visit_page.dart';
import '../cubit/smart_route_cubit.dart';

class SmartRoutePage extends StatelessWidget {
  const SmartRoutePage({super.key, this.routeId, this.territoryId});

  final String? routeId;
  final String? territoryId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SmartRouteCubit()..loadSession(),
      child: Scaffold(
        backgroundColor: AppTheme.surfaceWarm,
        appBar: AppBar(
          title: const Text('Smart Route'),
          actions: <Widget>[
            Builder(
              builder: (context) {
                return IconButton(
                  tooltip: 'Refresh suggestions',
                  onPressed: () {
                    context.read<SmartRouteCubit>().refreshSuggestion();
                  },
                  icon: const Icon(Icons.refresh),
                );
              },
            ),
          ],
        ),
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
              return _SmartRouteErrorState(message: state.message);
            }

            if (state is! SmartRouteLoaded) {
              return const SizedBox.shrink();
            }

            final session = state.session;
            final progress = state.progress;
            final stop = state.currentStop;

            return RefreshIndicator(
              onRefresh: () =>
                  context.read<SmartRouteCubit>().refreshSuggestion(),
              color: AppTheme.primaryBrown,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  _RouteHeroCard(session: session),
                  const SizedBox(height: 16),
                  _ProgressHeaderCard(
                    progress: progress,
                    isAllDone: state.isAllDone,
                  ),
                  const SizedBox(height: 16),
                  if (state.isAllDone || stop == null)
                    _AllDoneCard(session: session, progress: progress)
                  else
                    _SuggestedStopCard(stop: stop),
                  const SizedBox(height: 16),
                  if (!state.isAllDone && stop != null)
                    _ActionPanel(
                      stop: stop,
                      routeId: routeId,
                      territoryId: territoryId,
                    ),
                  if (!state.isAllDone && stop != null)
                    const SizedBox(height: 16),
                  _AssignedOutletsCard(outlets: state.rankedOutlets),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

Future<void> _openMapsNavigation({
  required BuildContext context,
  required String outletName,
  String? address,
  double? latitude,
  double? longitude,
}) async {
  final hasCoordinates = latitude != null && longitude != null;
  final safeAddress = (address ?? '').trim();

  if (!hasCoordinates && safeAddress.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No map location is available for this outlet yet.'),
      ),
    );
    return;
  }

  final query = hasCoordinates
      ? '$latitude,$longitude'
      : <String>[
          outletName,
          safeAddress,
        ].where((part) => part.isNotEmpty).join(', ');

  final directionsUrl = Uri.https(
    'www.google.com',
    '/maps/dir/',
    <String, String>{'api': '1', 'destination': query, 'travelmode': 'driving'},
  );
  final searchUrl = Uri.https(
    'www.google.com',
    '/maps/search/',
    <String, String>{'api': '1', 'query': query},
  );

  final candidates = <Uri>[directionsUrl, searchUrl];

  for (final candidate in candidates) {
    final didLaunch = await launchUrl(
      candidate,
      mode: LaunchMode.platformDefault,
    );
    if (didLaunch) {
      return;
    }
  }

  if (!context.mounted) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Could not open a maps app on this device.')),
  );
}

class _SmartRouteErrorState extends StatelessWidget {
  const _SmartRouteErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.route_outlined,
              size: 56,
              color: AppTheme.promotionMutedRed,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.read<SmartRouteCubit>().loadSession(),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryBrown,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteHeroCard extends StatelessWidget {
  const _RouteHeroCard({required this.session});

  final SmartRouteSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: <Color>[AppTheme.primaryBrownDark, AppTheme.primaryBrown],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.primaryBrownDark.withAlpha(38),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Today\'s route',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(session.routeDate),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withAlpha(220),
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(
                label: _formatStatus(session.status),
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withAlpha(32),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _MetricBadge(label: 'Assigned', value: '${session.totalStops}'),
              _MetricBadge(label: 'Pending', value: '${session.pendingStops}'),
              _MetricBadge(
                label: 'In Progress',
                value: '${session.inProgressStops}',
              ),
              _MetricBadge(label: 'Done', value: '${session.completedStops}'),
              if (session.skippedStops > 0)
                _MetricBadge(
                  label: 'Skipped',
                  value: '${session.skippedStops}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressHeaderCard extends StatelessWidget {
  const _ProgressHeaderCard({required this.progress, required this.isAllDone});

  final SmartRouteProgress progress;
  final bool isAllDone;

  @override
  Widget build(BuildContext context) {
    final displayStopNumber = _displayStopNumber(progress, isAllDone);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            progress.totalStops == 0
                ? 'No assigned stops yet'
                : 'Stop $displayStopNumber of ${progress.totalStops}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress.totalStops == 0
                ? 'Assigned outlets will appear here once a smart-route session is ready.'
                : 'Visited: ${progress.completedStops} | Skipped: ${progress.skippedStops} | In progress: ${progress.inProgressStops}',
            style: const TextStyle(color: AppTheme.textSoft, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _AllDoneCard extends StatelessWidget {
  const _AllDoneCard({required this.session, required this.progress});

  final SmartRouteSession session;
  final SmartRouteProgress progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(
                Icons.check_circle,
                color: AppTheme.proceedOrderOlive,
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Smart route finished for today',
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            session.totalStops == 0
                ? 'No assigned outlets were found for today.'
                : 'All suggested outlets have been completed or skipped. Completed: ${progress.completedStops}. Skipped: ${progress.skippedStops}.',
            style: const TextStyle(color: AppTheme.textSoft, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _SuggestedStopCard extends StatelessWidget {
  const _SuggestedStopCard({required this.stop});

  final SmartRouteStop stop;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(stop.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineWarm),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.primaryBrownDark.withAlpha(12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _headlineForRecommendation(stop.recommendation),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stop.outletName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
              _StatusPill(
                label: _formatStatus(stop.status),
                foregroundColor: statusColor,
                backgroundColor: statusColor.withAlpha(24),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Owner: ${stop.ownerName}',
            style: const TextStyle(
              color: AppTheme.textSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
          if ((stop.address ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: AppTheme.primaryBrown,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    stop.address!,
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _InfoChip(
                icon: Icons.format_list_numbered,
                label: 'Stop ${stop.suggestedSeq}',
              ),
              _InfoChip(
                icon: Icons.assignment_turned_in_outlined,
                label: stop.purpose,
              ),
              _InfoChip(icon: Icons.flag_outlined, label: stop.priorityBand),
              if (stop.distanceKm != null)
                _InfoChip(
                  icon: Icons.near_me_outlined,
                  label: '${stop.distanceKm!.toStringAsFixed(1)} km away',
                ),
              if (stop.etaMinutes != null)
                _InfoChip(
                  icon: Icons.schedule,
                  label: '~${stop.etaMinutes} min',
                ),
            ],
          ),
          if (stop.priorityScore != null) ...<Widget>[
            const SizedBox(height: 18),
            const Text(
              'Recommendation score',
              style: TextStyle(
                color: AppTheme.textSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: stop.priorityScore!.clamp(0.0, 1.0).toDouble(),
                minHeight: 10,
                backgroundColor: AppTheme.outlineWarm,
                color: AppTheme.primaryBrown,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.stop,
    required this.routeId,
    required this.territoryId,
  });

  final SmartRouteStop stop;
  final String? routeId;
  final String? territoryId;

  bool get _hasVisitContext {
    final safeRouteId = routeId?.trim() ?? '';
    final safeTerritoryId = territoryId?.trim() ?? '';
    return safeRouteId.isNotEmpty && safeTerritoryId.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Next action',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            stop.status == 'in_progress'
                ? 'The stop is already in progress. Re-open the store visit or mark the smart-route stop complete after the visit is done.'
                : 'Start this suggested visit, navigate to the outlet, or skip it with a reason if it cannot be served now.',
            style: const TextStyle(color: AppTheme.textSoft, height: 1.4),
          ),
          if (!_hasVisitContext) ...<Widget>[
            const SizedBox(height: 10),
            const Text(
              'A sales route must be active before the visit handoff can open.',
              style: TextStyle(
                color: AppTheme.promotionMutedRed,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    await _handleVisitAction(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.proceedOrderOlive,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: Icon(
                    stop.status == 'in_progress'
                        ? Icons.storefront_outlined
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    stop.status == 'in_progress' ? 'Open Visit' : 'Start Visit',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _openMapsNavigation(
                      context: context,
                      outletName: stop.outletName,
                      address: stop.address,
                      latitude: stop.latitude,
                      longitude: stop.longitude,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBrown,
                    side: const BorderSide(color: AppTheme.primaryBrown),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.navigation_outlined),
                  label: const Text('Start Navigation'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: stop.status == 'in_progress'
                      ? () {
                          context.read<SmartRouteCubit>().completeCurrentStop(
                            stop.id,
                          );
                        }
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.proceedOrderOlive,
                    side: const BorderSide(color: AppTheme.proceedOrderOlive),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark Stop Complete'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<SmartRouteCubit>().refreshSuggestion();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBrown,
                    side: const BorderSide(color: AppTheme.primaryBrown),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.sync),
                  label: const Text('Refresh'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _showSkipBottomSheet(context, stop.id);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.promotionMutedRed,
                side: const BorderSide(color: AppTheme.promotionMutedRed),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.skip_next_outlined),
              label: const Text('Skip Suggested Outlet'),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Skip alerts are saved and shared with territory leadership so route changes remain visible.',
            style: TextStyle(
              color: AppTheme.textSoft,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVisitAction(BuildContext context) async {
    if (!_hasVisitContext) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start a route first so the store visit can open.'),
        ),
      );
      return;
    }

    SmartRouteStop? activeStop = stop;
    if (stop.status != 'in_progress') {
      activeStop = await context.read<SmartRouteCubit>().startCurrentStop(
        stop.id,
      );
      if (!context.mounted || activeStop == null) {
        return;
      }
    }

    if (!context.mounted) {
      return;
    }

    final selectedStop = activeStop;

    final initialOutlet = TerritoryOutlet(
      id: selectedStop.outletId,
      outletName: selectedStop.outletName,
      ownerName: selectedStop.ownerName,
      address: selectedStop.address,
      latitude: selectedStop.latitude,
      longitude: selectedStop.longitude,
    );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OutletVisitPage(
          routeId: routeId!.trim(),
          territoryId: territoryId!.trim(),
          initialOutlet: initialOutlet,
          smartRouteStopId: selectedStop.id,
          smartRouteSessionId: selectedStop.routeSessionId,
        ),
      ),
    );
  }

  void _showSkipBottomSheet(BuildContext parentContext, String stopId) {
    showModalBottomSheet<void>(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 12,
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

class _AssignedOutletsCard extends StatelessWidget {
  const _AssignedOutletsCard({required this.outlets});

  final List<SmartRouteRankedOutlet> outlets;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Today\'s assigned outlets',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            outlets.isEmpty
                ? 'No outlets were assigned to this smart-route session yet.'
                : 'Live GPS distance is shown in kilometers and the list is ranked from the nearest stop to the farthest when location is available.',
            style: const TextStyle(color: AppTheme.textSoft, height: 1.4),
          ),
          if (outlets.isNotEmpty) const SizedBox(height: 16),
          if (outlets.isEmpty)
            const _EmptyAssignedState()
          else
            ...outlets.asMap().entries.map(
              (entry) => _AssignedOutletTile(
                outlet: entry.value,
                displayOrder: entry.key + 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _AssignedOutletTile extends StatelessWidget {
  const _AssignedOutletTile({required this.outlet, required this.displayOrder});

  final SmartRouteRankedOutlet outlet;
  final int displayOrder;

  @override
  Widget build(BuildContext context) {
    final summary = outlet.outlet;
    final statusColor = _statusColor(summary.stopStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarm,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: outlet.isSuggestedStop
              ? AppTheme.primaryBrown
              : AppTheme.outlineWarm,
          width: outlet.isSuggestedStop ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBrown.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$displayOrder',
                  style: const TextStyle(
                    color: AppTheme.primaryBrownDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      summary.outletName,
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.ownerName,
                      style: const TextStyle(
                        color: AppTheme.textSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if ((summary.address ?? '').trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        summary.address!,
                        style: const TextStyle(
                          color: AppTheme.textSoft,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  _StatusPill(
                    label: _formatStatus(summary.stopStatus),
                    foregroundColor: statusColor,
                    backgroundColor: statusColor.withAlpha(22),
                  ),
                  const SizedBox(height: 8),
                  IconButton.filledTonal(
                    tooltip: 'Start navigation',
                    onPressed: () async {
                      await _openMapsNavigation(
                        context: context,
                        outletName: summary.outletName,
                        address: summary.address,
                        latitude: summary.latitude,
                        longitude: summary.longitude,
                      );
                    },
                    style: IconButton.styleFrom(
                      foregroundColor: AppTheme.primaryBrown,
                      backgroundColor: AppTheme.primaryBrown.withAlpha(18),
                    ),
                    icon: const Icon(Icons.navigation_outlined),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (outlet.isSuggestedStop)
                const _ListBadge(
                  label: 'Suggested now',
                  foregroundColor: Colors.white,
                  backgroundColor: AppTheme.primaryBrown,
                ),
              if (outlet.isNearest)
                const _ListBadge(
                  label: 'Nearest',
                  foregroundColor: AppTheme.primaryBrownDark,
                  backgroundColor: AppTheme.surfaceTint,
                ),
              _ListBadge(
                label: outlet.distanceKm == null
                    ? 'Distance unavailable'
                    : '${outlet.distanceKm!.toStringAsFixed(1)} km',
                foregroundColor: AppTheme.textDark,
                backgroundColor: Colors.white,
              ),
              _ListBadge(
                label: outlet.etaMinutes == null
                    ? 'ETA unavailable'
                    : '~${outlet.etaMinutes} min',
                foregroundColor: AppTheme.textDark,
                backgroundColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyAssignedState extends StatelessWidget {
  const _EmptyAssignedState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarm,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: const Row(
        children: <Widget>[
          Icon(Icons.inbox_outlined, color: AppTheme.textSoft),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No outlets available yet.',
              style: TextStyle(color: AppTheme.textSoft),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListBadge extends StatelessWidget {
  const _ListBadge({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Text(
        label,
        style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(42)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(220),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: AppTheme.primaryBrown),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class SkipBottomSheetContent extends StatefulWidget {
  const SkipBottomSheetContent({super.key, required this.onSubmit});

  final void Function(String reasonCode, String freeText) onSubmit;

  @override
  State<SkipBottomSheetContent> createState() => _SkipBottomSheetContentState();
}

class _SkipBottomSheetContentState extends State<SkipBottomSheetContent> {
  static const List<_SkipReasonOption> _reasons = <_SkipReasonOption>[
    _SkipReasonOption(
      code: 'CUSTOMER_CLOSED',
      label: 'Customer branch closed early',
      helper: 'The outlet is closed or cannot receive the visit right now.',
    ),
    _SkipReasonOption(
      code: 'NO_STOCK_NEEDED',
      label: 'No stock needed',
      helper: 'The owner confirmed they do not need stock today.',
    ),
    _SkipReasonOption(
      code: 'ALREADY_VISITED',
      label: 'Already visited',
      helper: 'The outlet was already covered through another visit.',
    ),
    _SkipReasonOption(
      code: 'OTHER',
      label: 'Other reason',
      helper: 'Add a short note so the route update is understandable later.',
    ),
  ];

  String? _selectedReasonCode;
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedReason = _reasons.cast<_SkipReasonOption?>().firstWhere(
      (reason) => reason?.code == _selectedReasonCode,
      orElse: () => null,
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Skip suggested outlet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose the reason for skipping. This update is shared with route managers so the next suggestion stays accurate.',
                style: TextStyle(color: AppTheme.textSoft, height: 1.4),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: _selectedReasonCode,
                decoration: const InputDecoration(labelText: 'Skip reason'),
                items: _reasons
                    .map(
                      (reason) => DropdownMenuItem<String>(
                        value: reason.code,
                        child: Text(reason.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  setState(() {
                    _selectedReasonCode = value;
                  });
                },
              ),
              if (selectedReason != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  selectedReason.helper,
                  style: const TextStyle(
                    color: AppTheme.textSoft,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: _selectedReasonCode == 'OTHER'
                      ? 'Short note'
                      : 'Short note (optional)',
                  hintText: 'Add any extra context for the route team.',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canSubmit
                      ? () {
                          widget.onSubmit(
                            _selectedReasonCode!,
                            _noteController.text.trim(),
                          );
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.promotionMutedRed,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Submit skip'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canSubmit {
    if (_selectedReasonCode == null) {
      return false;
    }

    if (_selectedReasonCode != 'OTHER') {
      return true;
    }

    return _noteController.text.trim().length >= 5;
  }
}

class _SkipReasonOption {
  const _SkipReasonOption({
    required this.code,
    required this.label,
    required this.helper,
  });

  final String code;
  final String label;
  final String helper;
}

int _displayStopNumber(SmartRouteProgress progress, bool isAllDone) {
  if (progress.totalStops <= 0) {
    return 0;
  }

  if (isAllDone) {
    return progress.totalStops;
  }

  if (progress.inProgressStops > 0) {
    return _clampInt(progress.currentStopNumber, 1, progress.totalStops);
  }

  return _clampInt(progress.currentStopNumber + 1, 1, progress.totalStops);
}

int _clampInt(int value, int min, int max) {
  if (value < min) {
    return min;
  }
  if (value > max) {
    return max;
  }
  return value;
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final monthNames = <String>[
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
  final month = monthNames[local.month - 1];
  return '${local.day} $month ${local.year}';
}

String _headlineForRecommendation(String recommendation) {
  switch (recommendation) {
    case 'resume-current-visit':
      return 'Current visit in progress';
    case 'next-best-stop':
      return 'Recommended next outlet';
    case 'follow-sequence':
      return 'Next outlet in sequence';
    default:
      return 'Suggested outlet';
  }
}

String _formatStatus(String status) {
  switch (status) {
    case 'in_progress':
      return 'In Progress';
    case 'completed':
      return 'Completed';
    case 'skipped':
      return 'Skipped';
    case 'pending':
      return 'Pending';
    default:
      return status
          .replaceAll('_', ' ')
          .split(' ')
          .map((part) {
            if (part.isEmpty) {
              return part;
            }
            return '${part[0].toUpperCase()}${part.substring(1)}';
          })
          .join(' ');
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'completed':
      return AppTheme.proceedOrderOlive;
    case 'in_progress':
      return AppTheme.primaryBrown;
    case 'skipped':
      return AppTheme.promotionMutedRed;
    default:
      return AppTheme.securitySlate;
  }
}

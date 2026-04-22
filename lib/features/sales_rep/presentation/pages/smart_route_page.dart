import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/sales_rep/data/services/outlet_visit_service.dart';
import 'package:mobile/features/sales_rep/data/services/smart_route_service.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/smart_route_cubit.dart';

import 'outlet_visit_page.dart';

class SmartRoutePage extends StatefulWidget {
  const SmartRoutePage({super.key, this.routeId, this.territoryId});

  final String? routeId;
  final String? territoryId;

  @override
  State<SmartRoutePage> createState() => _SmartRoutePageState();
}

class _SmartRoutePageState extends State<SmartRoutePage> {
  late final SmartRouteCubit _cubit;
  bool _mapStarted = false;

  @override
  void initState() {
    super.initState();
    _cubit = SmartRouteCubit()..loadSession(routeId: widget.routeId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppTheme.surfaceWarm,
        appBar: AppBar(
          title: const Text('Smart Route'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _cubit.refreshSuggestion,
              icon: const Icon(Icons.refresh_rounded),
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
              return _ErrorView(
                message: state.message,
                onRetry: () => _cubit.loadSession(routeId: widget.routeId),
              );
            }

            if (state is! SmartRouteLoaded) {
              return const SizedBox.shrink();
            }

            final shouldShowMap =
                _mapStarted ||
                state.currentStop?.status == 'in_progress' ||
                state.progress.currentStopNumber > 0;

            if (state.isAllDone) {
              return _AllDoneView(
                progress: state.progress,
                onRefresh: _cubit.refreshSuggestion,
              );
            }

            if (!shouldShowMap) {
              return _ShopSelectionView(
                state: state,
                onNext: () => _showOptimizedList(context, state),
              );
            }

            return _SmartRouteMapView(
              state: state,
              routeId: widget.routeId,
              territoryId: widget.territoryId,
              onVisitFinished: () => setState(() => _mapStarted = true),
              onBackToList: () => setState(() => _mapStarted = false),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showOptimizedList(
    BuildContext context,
    SmartRouteLoaded state,
  ) async {
    final pendingStops = state.rankedOutlets
        .where(
          (entry) =>
              entry.outlet.stopStatus != 'completed' &&
              entry.outlet.stopStatus != 'skipped',
        )
        .toList(growable: false);

    if (pendingStops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No remaining shops in today route.')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _OptimizedRouteSheet(
          stops: pendingStops,
          onStart: () {
            Navigator.of(sheetContext).pop();
            setState(() => _mapStarted = true);
          },
        );
      },
    );
  }
}

class _ShopSelectionView extends StatelessWidget {
  const _ShopSelectionView({required this.state, required this.onNext});

  final SmartRouteLoaded state;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final shops = state.rankedOutlets;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              children: [
                _IntroCard(
                  title: 'Today shops',
                  message:
                      'Review the shops in your Beat Plan. The route will be ordered from your current location, nearest to farthest.',
                  total: state.session.totalStops,
                  completed: state.session.completedStops,
                  skipped: state.session.skippedStops,
                ),
                const SizedBox(height: 14),
                if (shops.isEmpty)
                  const _EmptyCard(
                    title: 'No shops selected',
                    message:
                        'Add shops to today Beat Plan from Start Route first.',
                  )
                else
                  ...shops.asMap().entries.map(
                    (entry) => _ShopListTile(
                      index: entry.key + 1,
                      outlet: entry.value,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: shops.isEmpty ? null : onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryBrown,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Next'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptimizedRouteSheet extends StatelessWidget {
  const _OptimizedRouteSheet({required this.stops, required this.onStart});

  final List<SmartRouteRankedOutlet> stops;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(26),
            bottom: Radius.circular(22),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outlineWarm,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Optimized order',
              style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Nearest shop first, then the next closest remaining shop.',
              style: TextStyle(color: AppTheme.textSoft, height: 1.35),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: stops.length,
                separatorBuilder: (_, _) => const Divider(height: 18),
                itemBuilder: (context, index) {
                  final stop = stops[index];
                  final outlet = stop.outlet;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBrown.withAlpha(22),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AppTheme.primaryBrownDark,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              outlet.outletName,
                              style: const TextStyle(
                                color: AppTheme.textDark,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if ((outlet.address ?? '').trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  outlet.address!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.textSoft,
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        stop.distanceKm == null
                            ? '-- km'
                            : '${stop.distanceKm!.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          color: AppTheme.primaryBrown,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.promotionMutedRed,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Start'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmartRouteMapView extends StatelessWidget {
  const _SmartRouteMapView({
    required this.state,
    required this.routeId,
    required this.territoryId,
    required this.onVisitFinished,
    required this.onBackToList,
  });

  final SmartRouteLoaded state;
  final String? routeId;
  final String? territoryId;
  final VoidCallback onVisitFinished;
  final VoidCallback onBackToList;

  @override
  Widget build(BuildContext context) {
    final stop = state.currentStop;
    if (stop == null) {
      return _AllDoneView(
        progress: state.progress,
        onRefresh: context.read<SmartRouteCubit>().refreshSuggestion,
      );
    }

    final currentLatLng = _latLng(
      state.currentLatitude,
      state.currentLongitude,
    );
    final stopLatLng = _latLng(stop.latitude, stop.longitude);
    final cameraTarget =
        currentLatLng ?? stopLatLng ?? const LatLng(6.0535, 80.2210);
    final markers = <Marker>{
      if (currentLatLng != null)
        Marker(
          markerId: const MarkerId('current-location'),
          position: currentLatLng,
          infoWindow: const InfoWindow(title: 'Current location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      if (stopLatLng != null)
        Marker(
          markerId: MarkerId(stop.outletId),
          position: stopLatLng,
          infoWindow: InfoWindow(title: stop.outletName),
        ),
      ...state.rankedOutlets
          .where((entry) {
            final outlet = entry.outlet;
            return outlet.latitude != null &&
                outlet.longitude != null &&
                outlet.id != stop.outletId;
          })
          .map(
            (entry) => Marker(
              markerId: MarkerId(entry.outlet.id),
              position: LatLng(entry.outlet.latitude!, entry.outlet.longitude!),
              infoWindow: InfoWindow(title: entry.outlet.outletName),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
            ),
          ),
    };
    final polylines = <Polyline>{
      if (currentLatLng != null && stopLatLng != null)
        Polyline(
          polylineId: const PolylineId('route-preview'),
          points: [currentLatLng, stopLatLng],
          color: AppTheme.primaryBrown,
          width: 5,
          patterns: [PatternItem.dash(18), PatternItem.gap(8)],
        ),
    };

    return Stack(
      children: [
        Positioned.fill(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: cameraTarget,
              zoom: currentLatLng != null && stopLatLng != null ? 14.5 : 13,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: markers,
            polylines: polylines,
          ),
        ),
        Positioned(
          left: 14,
          top: 14,
          right: 14,
          child: _MapProgressPill(
            completed: state.progress.completedStops,
            skipped: state.progress.skippedStops,
            total: state.progress.totalStops,
            onBackToList: onBackToList,
          ),
        ),
        Positioned(
          left: 14,
          right: 14,
          bottom: 14,
          child: _MapStopCard(
            stop: stop,
            stopNumber: _nextDisplayNumber(state.progress),
            totalStops: state.progress.totalStops,
            onNavigate: () => _openMapsNavigation(
              context: context,
              outletName: stop.outletName,
              address: stop.address,
              latitude: stop.latitude,
              longitude: stop.longitude,
            ),
            onSkip: () => _showSkipSheet(context, stop.id),
            onStartVisit: () => _startVisit(context, stop),
          ),
        ),
      ],
    );
  }

  Future<void> _startVisit(BuildContext context, SmartRouteStop stop) async {
    final safeRouteId = routeId?.trim() ?? '';
    final safeTerritoryId = territoryId?.trim() ?? '';
    if (safeRouteId.isEmpty || safeTerritoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start the route before opening visits.')),
      );
      return;
    }

    var activeStop = stop;
    if (stop.status != 'in_progress') {
      final started = await context.read<SmartRouteCubit>().startCurrentStop(
        stop.id,
      );
      if (!context.mounted || started == null) {
        return;
      }
      activeStop = started;
    }

    final visitResult = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => OutletVisitPage(
          routeId: safeRouteId,
          territoryId: safeTerritoryId,
          initialOutlet: TerritoryOutlet(
            id: activeStop.outletId,
            outletName: activeStop.outletName,
            ownerName: activeStop.ownerName,
            address: activeStop.address,
            latitude: activeStop.latitude,
            longitude: activeStop.longitude,
            isBeatPlanOutlet: true,
          ),
          smartRouteStopId: activeStop.id,
          smartRouteSessionId: activeStop.routeSessionId,
        ),
      ),
    );

    if (!context.mounted) {
      return;
    }

    if (visitResult == true) {
      await context.read<SmartRouteCubit>().completeCurrentStop(activeStop.id);
      onVisitFinished();
    } else {
      await context.read<SmartRouteCubit>().refreshSuggestion();
    }
  }

  Future<void> _showSkipSheet(BuildContext context, String stopId) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 12,
          ),
          child: SkipBottomSheetContent(
            onSubmit: (reasonCode, freeText) {
              context.read<SmartRouteCubit>().skipCurrentStop(
                stopId: stopId,
                reasonCode: reasonCode,
                freeText: freeText,
              );
              Navigator.of(sheetContext).pop();
            },
          ),
        );
      },
    );
  }
}

class _MapStopCard extends StatelessWidget {
  const _MapStopCard({
    required this.stop,
    required this.stopNumber,
    required this.totalStops,
    required this.onNavigate,
    required this.onSkip,
    required this.onStartVisit,
  });

  final SmartRouteStop stop;
  final int stopNumber;
  final int totalStops;
  final VoidCallback onNavigate;
  final VoidCallback onSkip;
  final VoidCallback onStartVisit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2E7D8),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(42),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stop.outletName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.local_shipping_outlined, size: 20),
              const SizedBox(width: 4),
              Text(
                stop.distanceKm == null
                    ? '-- km'
                    : '${stop.distanceKm!.toStringAsFixed(1)} km',
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            (stop.address ?? '').trim().isEmpty
                ? 'Address not available'
                : stop.address!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.textSoft),
          ),
          const SizedBox(height: 8),
          Text(
            'Stop $stopNumber of $totalStops',
            style: const TextStyle(
              color: AppTheme.primaryBrown,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onStartVisit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryBrown,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Start visit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onSkip,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryBrown,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Open Google Maps',
                onPressed: onNavigate,
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.promotionMutedRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                icon: const Icon(Icons.navigation_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapProgressPill extends StatelessWidget {
  const _MapProgressPill({
    required this.completed,
    required this.skipped,
    required this.total,
    required this.onBackToList,
  });

  final int completed;
  final int skipped;
  final int total;
  final VoidCallback onBackToList;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          tooltip: 'Back to shop list',
          onPressed: onBackToList,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primaryBrown,
          ),
          icon: const Icon(Icons.list_alt_rounded),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(24),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              'Completed $completed | Skipped $skipped | Total $total',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShopListTile extends StatelessWidget {
  const _ShopListTile({required this.index, required this.outlet});

  final int index;
  final SmartRouteRankedOutlet outlet;

  @override
  Widget build(BuildContext context) {
    final item = outlet.outlet;
    final statusColor = _statusColor(item.stopStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primaryBrown.withAlpha(20),
            child: Text(
              '$index',
              style: const TextStyle(
                color: AppTheme.primaryBrownDark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.outletName,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  (item.address ?? '').trim().isEmpty
                      ? item.ownerName
                      : item.address!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSoft,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _SmallStatusPill(
                label: _formatStatus(item.stopStatus),
                color: statusColor,
              ),
              const SizedBox(height: 8),
              Text(
                outlet.distanceKm == null
                    ? '-- km'
                    : '${outlet.distanceKm!.toStringAsFixed(1)} km',
                style: const TextStyle(
                  color: AppTheme.primaryBrown,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.title,
    required this.message,
    required this.total,
    required this.completed,
    required this.skipped,
  });

  final String title;
  final String message;
  final int total;
  final int completed;
  final int skipped;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
            style: const TextStyle(
              color: AppTheme.textDark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            style: const TextStyle(color: AppTheme.textSoft, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricTile(label: 'Shops', value: '$total'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(label: 'Done', value: '$completed'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(label: 'Skipped', value: '$skipped'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarm,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSoft, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _AllDoneView extends StatelessWidget {
  const _AllDoneView({required this.progress, required this.onRefresh});

  final SmartRouteProgress progress;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              size: 72,
              color: AppTheme.proceedOrderOlive,
            ),
            const SizedBox(height: 18),
            const Text(
              'All shops completed. Good job!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completed ${progress.completedStops}, skipped ${progress.skippedStops}. End Route is now eligible from the dashboard.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSoft, height: 1.4),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_outlined, color: AppTheme.textSoft),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppTheme.textSoft,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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
              size: 56,
              color: AppTheme.promotionMutedRed,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _SmallStatusPill extends StatelessWidget {
  const _SmallStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
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
  static const _reasons = [
    _SkipReason('SHOP_CLOSED', 'Shop closed'),
    _SkipReason('OWNER_UNAVAILABLE', 'Owner unavailable'),
    _SkipReason('NO_TIME', 'No time today'),
    _SkipReason('ROAD_ACCESS_ISSUE', 'Road/access issue'),
    _SkipReason('WRONG_LOCATION', 'Wrong location'),
    _SkipReason('NO_DELIVERY_OR_ORDER', 'No delivery/order needed'),
    _SkipReason('OTHER', 'Other'),
  ];

  String? _selectedReasonCode;
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Why skip this shop?',
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _reasons.map((reason) {
                  final selected = reason.code == _selectedReasonCode;
                  return FilterChip(
                    label: Text(reason.label),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedReasonCode = reason.code);
                    },
                    selectedColor: AppTheme.primaryBrown.withAlpha(22),
                    checkmarkColor: AppTheme.primaryBrown,
                  );
                }).toList(),
              ),
              if (_selectedReasonCode == 'OTHER') ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Enter reason',
                    hintText: 'Write the skip reason',
                  ),
                ),
              ],
              const SizedBox(height: 18),
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
                  child: const Text('Save skip reason'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkipReason {
  const _SkipReason(this.code, this.label);

  final String code;
  final String label;
}

LatLng? _latLng(double? latitude, double? longitude) {
  if (latitude == null || longitude == null) {
    return null;
  }
  return LatLng(latitude, longitude);
}

int _nextDisplayNumber(SmartRouteProgress progress) {
  final touched = progress.completedStops + progress.skippedStops;
  final next = touched + 1;
  if (progress.totalStops <= 0) {
    return 0;
  }
  return next.clamp(1, progress.totalStops);
}

String _formatStatus(String status) {
  switch (status) {
    case 'in_progress':
      return 'In progress';
    case 'completed':
      return 'Done';
    case 'skipped':
      return 'Skipped';
    case 'pending':
      return 'Pending';
    default:
      return status.replaceAll('_', ' ');
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
      const SnackBar(content: Text('No map location is available yet.')),
    );
    return;
  }

  final query = hasCoordinates
      ? '$latitude,$longitude'
      : [outletName, safeAddress].where((part) => part.isNotEmpty).join(', ');

  final directionsUrl = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': query,
    'travelmode': 'driving',
  });

  final launched = await launchUrl(
    directionsUrl,
    mode: LaunchMode.platformDefault,
  );
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open Google Maps.')),
    );
  }
}

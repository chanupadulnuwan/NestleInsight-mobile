import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/distributor/data/services/distributor_service.dart';
import 'package:mobile/features/distributor/domain/delivery_assignment.dart';

import 'deliver_order_page.dart';

class DistributorSmartRoutePage extends StatefulWidget {
  const DistributorSmartRoutePage({super.key, this.assignment});

  final DeliveryAssignment? assignment;

  @override
  State<DistributorSmartRoutePage> createState() =>
      _DistributorSmartRoutePageState();
}

class _DistributorSmartRoutePageState extends State<DistributorSmartRoutePage> {
  final DistributorService _service = DistributorService();
  final Set<String> _skippedOrderIds = <String>{};
  DeliveryAssignment? _assignment;
  Position? _position;
  bool _loading = true;
  bool _mapStarted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _assignment = widget.assignment;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Future.wait([_loadLocation(), _loadAssignment()]);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadAssignment() async {
    if (_assignment != null) {
      return;
    }
    try {
      _assignment = await _service.getMyAssignment();
    } on DistributorServiceException catch (error) {
      _error = error.message;
    }
  }

  Future<void> _refreshAssignment() async {
    try {
      final assignment = await _service.getMyAssignment();
      if (mounted) {
        setState(() => _assignment = assignment);
      }
    } on DistributorServiceException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    }
  }

  Future<void> _loadLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    try {
      _position = await Geolocator.getCurrentPosition();
    } catch (_) {
      _position = null;
    }
  }

  List<_DistributorRouteStop> get _rankedStops {
    final assignment = _assignment;
    if (assignment == null) {
      return const <_DistributorRouteStop>[];
    }

    final stops = assignment.orders
        .where(
          (order) =>
              !order.isCompleted && !_skippedOrderIds.contains(order.orderId),
        )
        .map(
          (order) => _DistributorRouteStop(
            order: order,
            distanceKm: _distanceKm(order.shopLatitude, order.shopLongitude),
          ),
        )
        .toList(growable: false);

    stops.sort((left, right) {
      final distanceCompare = (left.distanceKm ?? double.infinity).compareTo(
        right.distanceKm ?? double.infinity,
      );
      if (distanceCompare != 0) {
        return distanceCompare;
      }
      return left.order.sortOrder.compareTo(right.order.sortOrder);
    });

    return stops;
  }

  double? _distanceKm(double? latitude, double? longitude) {
    final position = _position;
    if (position == null || latitude == null || longitude == null) {
      return null;
    }
    final meters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      latitude,
      longitude,
    );
    return meters / 1000;
  }

  @override
  Widget build(BuildContext context) {
    final assignment = _assignment;
    final rankedStops = _rankedStops;

    return Scaffold(
      backgroundColor: AppTheme.surfaceWarm,
      appBar: AppBar(
        title: const Text('Smart Route'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _bootstrap,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorView(message: _error!, onRetry: _bootstrap)
          : assignment == null
          ? const _EmptyCard(
              title: 'No assignment today',
              message: 'Your TM has not assigned a delivery route yet.',
            )
          : rankedStops.isEmpty
          ? _DoneView(
              completed: assignment.completedCount,
              skipped: _skippedOrderIds.length,
            )
          : _mapStarted
          ? _DistributorMapView(
              assignment: assignment,
              stops: rankedStops,
              position: _position,
              onBackToList: () => setState(() => _mapStarted = false),
              onNavigate: _openMapsNavigation,
              onSkip: _showSkipSheet,
              onStartDelivery: _startDelivery,
            )
          : _DistributorShopList(
              assignment: assignment,
              stops: rankedStops,
              onNext: () => _showOptimizedSheet(rankedStops),
            ),
    );
  }

  Future<void> _showOptimizedSheet(List<_DistributorRouteStop> stops) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _OptimizedDistributorSheet(
        stops: stops,
        onStart: () {
          Navigator.of(sheetContext).pop();
          setState(() => _mapStarted = true);
        },
      ),
    );
  }

  Future<void> _startDelivery(AssignmentOrder order) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => DeliverOrderPage(order: order)),
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      await _refreshAssignment();
      setState(() => _mapStarted = true);
    }
  }

  Future<void> _showSkipSheet(AssignmentOrder order) async {
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
          child: _DistributorSkipSheet(
            onSubmit: (reasonCode, note) async {
              Navigator.of(sheetContext).pop();
              setState(() => _skippedOrderIds.add(order.orderId));
              final reason = _skipReasonLabel(reasonCode);
              final extra = note.trim().isEmpty ? '' : ' Note: ${note.trim()}';
              try {
                await _service.addNote(
                  assignmentId: _assignment?.id,
                  category: 'SMART_ROUTE_SKIP',
                  message:
                      'Skipped ${order.shopName} (${order.orderCode}). Reason: $reason.$extra',
                );
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Skip saved locally. Manager note failed.'),
                    ),
                  );
                }
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _openMapsNavigation(AssignmentOrder order) async {
    final hasCoordinates =
        order.shopLatitude != null && order.shopLongitude != null;
    final safeAddress = (order.shopAddress ?? '').trim();
    if (!hasCoordinates && safeAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No map location is available yet.')),
      );
      return;
    }

    final query = hasCoordinates
        ? '${order.shopLatitude},${order.shopLongitude}'
        : [
            order.shopName,
            safeAddress,
          ].where((part) => part.trim().isNotEmpty).join(', ');
    final url = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': query,
      'travelmode': 'driving',
    });
    final launched = await launchUrl(url, mode: LaunchMode.platformDefault);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }
}

class _DistributorShopList extends StatelessWidget {
  const _DistributorShopList({
    required this.assignment,
    required this.stops,
    required this.onNext,
  });

  final DeliveryAssignment assignment;
  final List<_DistributorRouteStop> stops;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _IntroCard(
                  title: 'Assigned delivery shops',
                  message:
                      'This list comes from the shops your TM assigned for today. The next step orders them from your current location.',
                  total: assignment.totalCount,
                  completed: assignment.completedCount,
                  skipped: 0,
                ),
                const SizedBox(height: 14),
                ...stops.asMap().entries.map(
                  (entry) => _DistributorOrderTile(
                    index: entry.key + 1,
                    stop: entry.value,
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
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryBrown,
                  padding: const EdgeInsets.symmetric(vertical: 15),
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

class _DistributorMapView extends StatelessWidget {
  const _DistributorMapView({
    required this.assignment,
    required this.stops,
    required this.position,
    required this.onBackToList,
    required this.onNavigate,
    required this.onSkip,
    required this.onStartDelivery,
  });

  final DeliveryAssignment assignment;
  final List<_DistributorRouteStop> stops;
  final Position? position;
  final VoidCallback onBackToList;
  final Future<void> Function(AssignmentOrder order) onNavigate;
  final Future<void> Function(AssignmentOrder order) onSkip;
  final Future<void> Function(AssignmentOrder order) onStartDelivery;

  @override
  Widget build(BuildContext context) {
    final stop = stops.first;
    final order = stop.order;
    final currentLatLng = position == null
        ? null
        : LatLng(position!.latitude, position!.longitude);
    final targetLatLng =
        order.shopLatitude == null || order.shopLongitude == null
        ? null
        : LatLng(order.shopLatitude!, order.shopLongitude!);
    final cameraTarget =
        currentLatLng ?? targetLatLng ?? const LatLng(6.0535, 80.2210);

    return Stack(
      children: [
        Positioned.fill(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: cameraTarget,
              zoom: currentLatLng != null && targetLatLng != null ? 14.5 : 13,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: {
              if (currentLatLng != null)
                Marker(
                  markerId: const MarkerId('current'),
                  position: currentLatLng,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                  infoWindow: const InfoWindow(title: 'Current location'),
                ),
              if (targetLatLng != null)
                Marker(
                  markerId: MarkerId(order.orderId),
                  position: targetLatLng,
                  infoWindow: InfoWindow(title: order.shopName),
                ),
              ...stops
                  .skip(1)
                  .where((entry) {
                    return entry.order.shopLatitude != null &&
                        entry.order.shopLongitude != null;
                  })
                  .map(
                    (entry) => Marker(
                      markerId: MarkerId(entry.order.orderId),
                      position: LatLng(
                        entry.order.shopLatitude!,
                        entry.order.shopLongitude!,
                      ),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange,
                      ),
                      infoWindow: InfoWindow(title: entry.order.shopName),
                    ),
                  ),
            },
            polylines: {
              if (currentLatLng != null && targetLatLng != null)
                Polyline(
                  polylineId: const PolylineId('route-preview'),
                  points: [currentLatLng, targetLatLng],
                  color: AppTheme.primaryBrown,
                  width: 5,
                  patterns: [PatternItem.dash(18), PatternItem.gap(8)],
                ),
            },
          ),
        ),
        Positioned(
          left: 14,
          top: 14,
          right: 14,
          child: _MapProgressPill(
            completed: assignment.completedCount,
            skipped:
                assignment.totalCount -
                assignment.completedCount -
                stops.length,
            total: assignment.totalCount,
            onBackToList: onBackToList,
          ),
        ),
        Positioned(
          left: 14,
          right: 14,
          bottom: 14,
          child: _DistributorStopCard(
            order: order,
            stopNumber: assignment.completedCount + 1,
            totalStops: assignment.totalCount,
            distanceKm: stop.distanceKm,
            onNavigate: () => onNavigate(order),
            onSkip: () => onSkip(order),
            onStartDelivery: () => onStartDelivery(order),
          ),
        ),
      ],
    );
  }
}

class _OptimizedDistributorSheet extends StatelessWidget {
  const _OptimizedDistributorSheet({
    required this.stops,
    required this.onStart,
  });

  final List<_DistributorRouteStop> stops;
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
            const Text(
              'Optimized delivery order',
              style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: stops.length,
                separatorBuilder: (_, _) => const Divider(height: 18),
                itemBuilder: (context, index) {
                  final stop = stops[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: AppTheme.primaryBrown.withAlpha(22),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AppTheme.primaryBrown,
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
                              stop.order.shopName,
                              style: const TextStyle(
                                color: AppTheme.textDark,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              stop.order.shopAddress ?? 'Address unavailable',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textSoft,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        stop.distanceKm == null
                            ? '-- km'
                            : '${stop.distanceKm!.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          color: AppTheme.primaryBrown,
                          fontWeight: FontWeight.w900,
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

class _DistributorStopCard extends StatelessWidget {
  const _DistributorStopCard({
    required this.order,
    required this.stopNumber,
    required this.totalStops,
    required this.distanceKm,
    required this.onNavigate,
    required this.onSkip,
    required this.onStartDelivery,
  });

  final AssignmentOrder order;
  final int stopNumber;
  final int totalStops;
  final double? distanceKm;
  final VoidCallback onNavigate;
  final VoidCallback onSkip;
  final VoidCallback onStartDelivery;

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
                  order.shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(Icons.local_shipping_outlined, size: 20),
              const SizedBox(width: 4),
              Text(
                distanceKm == null
                    ? '-- km'
                    : '${distanceKm!.toStringAsFixed(1)} km',
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
            order.shopAddress ?? 'Address unavailable',
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
                  onPressed: onStartDelivery,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryBrown,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Start delivery'),
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

class _DistributorOrderTile extends StatelessWidget {
  const _DistributorOrderTile({required this.index, required this.stop});

  final int index;
  final _DistributorRouteStop stop;

  @override
  Widget build(BuildContext context) {
    final order = stop.order;
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
                  order.shopName,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  order.shopAddress ?? 'Address unavailable',
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
          Text(
            stop.distanceKm == null
                ? '-- km'
                : '${stop.distanceKm!.toStringAsFixed(1)} km',
            style: const TextStyle(
              color: AppTheme.primaryBrown,
              fontWeight: FontWeight.w900,
            ),
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

class _DoneView extends StatelessWidget {
  const _DoneView({required this.completed, required this.skipped});

  final int completed;
  final int skipped;

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
              'All assigned shops handled. Good job!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completed $completed, skipped $skipped.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSoft),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.route_outlined,
              size: 56,
              color: AppTheme.textSoft,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSoft),
            ),
          ],
        ),
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
              style: const TextStyle(color: AppTheme.textDark),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _DistributorSkipSheet extends StatefulWidget {
  const _DistributorSkipSheet({required this.onSubmit});

  final Future<void> Function(String reasonCode, String note) onSubmit;

  @override
  State<_DistributorSkipSheet> createState() => _DistributorSkipSheetState();
}

class _DistributorSkipSheetState extends State<_DistributorSkipSheet> {
  static const _reasons = [
    _SkipReason('SHOP_CLOSED', 'Shop closed'),
    _SkipReason('OWNER_UNAVAILABLE', 'Owner unavailable'),
    _SkipReason('NO_TIME', 'No time today'),
    _SkipReason('ROAD_ACCESS_ISSUE', 'Road/access issue'),
    _SkipReason('WRONG_LOCATION', 'Wrong location'),
    _SkipReason('NO_DELIVERY_POSSIBLE', 'Delivery not possible'),
    _SkipReason('OTHER', 'Other'),
  ];

  String? _selectedReasonCode;
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _selectedReasonCode != null &&
      (_selectedReasonCode != 'OTHER' ||
          _noteController.text.trim().length >= 5);

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
                  return FilterChip(
                    label: Text(reason.label),
                    selected: reason.code == _selectedReasonCode,
                    selectedColor: AppTheme.primaryBrown.withAlpha(22),
                    checkmarkColor: AppTheme.primaryBrown,
                    onSelected: (_) {
                      setState(() => _selectedReasonCode = reason.code);
                    },
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
                      ? () => widget.onSubmit(
                          _selectedReasonCode!,
                          _noteController.text.trim(),
                        )
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

class _DistributorRouteStop {
  const _DistributorRouteStop({required this.order, required this.distanceKm});

  final AssignmentOrder order;
  final double? distanceKm;
}

String _skipReasonLabel(String code) {
  switch (code) {
    case 'SHOP_CLOSED':
      return 'Shop closed';
    case 'OWNER_UNAVAILABLE':
      return 'Owner unavailable';
    case 'NO_TIME':
      return 'No time today';
    case 'ROAD_ACCESS_ISSUE':
      return 'Road/access issue';
    case 'WRONG_LOCATION':
      return 'Wrong location';
    case 'NO_DELIVERY_POSSIBLE':
      return 'Delivery not possible';
    default:
      return 'Other';
  }
}

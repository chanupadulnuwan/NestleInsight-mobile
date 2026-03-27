import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/services/location_picker_service.dart';
import 'package:mobile/core/theme/app_theme.dart';

class MapLocationPickerSheet extends StatefulWidget {
  const MapLocationPickerSheet({super.key, this.initialSelection});

  final LocationSelection? initialSelection;

  @override
  State<MapLocationPickerSheet> createState() => _MapLocationPickerSheetState();
}

class _MapLocationPickerSheetState extends State<MapLocationPickerSheet> {
  static const LatLng _fallbackLocation = LatLng(6.9271, 79.8612);

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng? _selectedPoint;
  String _summary = 'Selected location';
  String _addressLine = '';
  String? _statusMessage;
  bool _isLoading = true;
  bool _isResolvingAddress = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initializeSelection();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeSelection() async {
    final initialSelection = widget.initialSelection;

    if (initialSelection != null) {
      final initialPoint = LatLng(
        initialSelection.latitude,
        initialSelection.longitude,
      );

      setState(() {
        _selectedPoint = initialPoint;
        _summary = initialSelection.summary;
        _addressLine = initialSelection.addressLine;
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _moveToPoint(initialPoint);
      });
      return;
    }

    final resolvedInitialPoint = await _resolveInitialPoint();

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedPoint = resolvedInitialPoint;
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _moveToPoint(resolvedInitialPoint);
    });

    await _resolveAddressForPoint(resolvedInitialPoint, moveMap: false);
  }

  Future<LatLng> _resolveInitialPoint() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _statusMessage =
            'Location service is off, so the picker opened at the default area.';
        return _fallbackLocation;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _statusMessage =
            'Location permission was not granted, so the picker opened at the default area.';
        return _fallbackLocation;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      _statusMessage =
          'Current location could not be loaded, so the picker opened at the default area.';
      return _fallbackLocation;
    }
  }

  Future<void> _goToCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    final point = await _resolveInitialPoint();

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedPoint = point;
      _isLoading = false;
    });

    await _resolveAddressForPoint(point, moveMap: true);
  }

  Future<void> _searchForLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _statusMessage = 'Enter a place, address, or landmark to search.';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _statusMessage = null;
    });

    try {
      final matches = await locationFromAddress(query);
      if (matches.isEmpty) {
        setState(() {
          _statusMessage = 'No matching location was found for "$query".';
        });
        return;
      }

      final firstMatch = matches.first;
      final point = LatLng(firstMatch.latitude, firstMatch.longitude);

      await _resolveAddressForPoint(point, moveMap: true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = 'Location search failed. Try a more specific address.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _resolveAddressForPoint(
    LatLng point, {
    required bool moveMap,
  }) async {
    setState(() {
      _selectedPoint = point;
      _isResolvingAddress = true;
      _statusMessage = null;
    });

    if (moveMap) {
      _moveToPoint(point);
    }

    try {
      final placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      final placemark = placemarks.isNotEmpty ? placemarks.first : null;

      final resolvedAddress = _buildAddressLine(placemark, point);
      final resolvedSummary = _buildSummary(placemark, point);

      if (!mounted) {
        return;
      }

      setState(() {
        _addressLine = resolvedAddress;
        _summary = resolvedSummary;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _addressLine = _formatCoordinates(point);
        _summary = 'Selected location';
        _statusMessage =
            'The exact address could not be resolved, but the coordinates were saved.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingAddress = false;
        });
      }
    }
  }

  void _moveToPoint(LatLng point, {double zoom = 16}) {
    _mapController.move(point, zoom);
  }

  String _buildAddressLine(Placemark? placemark, LatLng point) {
    if (placemark == null) {
      return _formatCoordinates(point);
    }

    final parts = <String?>[
      placemark.street,
      placemark.subLocality,
      placemark.locality,
      placemark.administrativeArea,
      placemark.postalCode,
      placemark.country,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();

    if (parts.isEmpty) {
      return _formatCoordinates(point);
    }

    return parts.join(', ');
  }

  String _buildSummary(Placemark? placemark, LatLng point) {
    final summaryParts = <String?>[
      placemark?.subLocality,
      placemark?.locality,
      placemark?.administrativeArea,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();

    if (summaryParts.isEmpty) {
      return _formatCoordinates(point);
    }

    return summaryParts.join(', ');
  }

  String _formatCoordinates(LatLng point) {
    return '${point.latitude.toStringAsFixed(5)}, '
        '${point.longitude.toStringAsFixed(5)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedPoint = _selectedPoint ?? _fallbackLocation;

    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 52,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.outlineWarm,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pick location',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Search a place or use your current location, then fine-tune it on the map.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSoft,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _searchForLocation(),
                      decoration: InputDecoration(
                        hintText: 'Search address or place',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
                                onPressed: _searchForLocation,
                                icon: const Icon(Icons.arrow_forward),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 56,
                    width: 56,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _goToCurrentLocation,
                      style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Icon(Icons.my_location_outlined),
                    ),
                  ),
                ],
              ),
            ),
            if (_statusMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceTint,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.outlineWarm.withAlpha(140),
                    ),
                  ),
                  child: Text(
                    _statusMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceTint,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppTheme.outlineWarm.withAlpha(140),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _summary,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _addressLine.isEmpty
                          ? 'Resolving address...'
                          : _addressLine,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: selectedPoint,
                          initialZoom: 16,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all,
                          ),
                          onTap: (_, point) {
                            _resolveAddressForPoint(point, moveMap: false);
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.mobile',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: selectedPoint,
                                width: 54,
                                height: 54,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: AppTheme.primaryBrown,
                                  size: 46,
                                ),
                              ),
                            ],
                          ),
                          RichAttributionWidget(
                            attributions: [
                              TextSourceAttribution(
                                'OpenStreetMap contributors',
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_isLoading || _isResolvingAddress)
                        Positioned.fill(
                          child: Container(
                            color: Colors.white.withAlpha(170),
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoading || _isResolvingAddress
                          ? null
                          : () {
                              Navigator.of(context).pop(
                                LocationSelection(
                                  latitude: selectedPoint.latitude,
                                  longitude: selectedPoint.longitude,
                                  summary: _summary,
                                  addressLine: _addressLine.isEmpty
                                      ? _formatCoordinates(selectedPoint)
                                      : _addressLine,
                                ),
                              );
                            },
                      child: const Text('Use this location'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

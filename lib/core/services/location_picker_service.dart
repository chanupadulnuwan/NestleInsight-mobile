import 'package:flutter/material.dart';
import 'package:mobile/core/widgets/map_location_picker_sheet.dart';

class LocationSelection {
  const LocationSelection({
    required this.latitude,
    required this.longitude,
    required this.summary,
    required this.addressLine,
  });

  final double latitude;
  final double longitude;
  final String summary;
  final String addressLine;
}

class LocationPickerService {
  bool get isAvailable => true;

  String get unavailableMessage =>
      'Search a location or use your current location, then pick it from the map.';

  Future<LocationSelection?> pickLocation({
    required BuildContext context,
    LocationSelection? initialSelection,
  }) {
    return showModalBottomSheet<LocationSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          MapLocationPickerSheet(initialSelection: initialSelection),
    );
  }
}

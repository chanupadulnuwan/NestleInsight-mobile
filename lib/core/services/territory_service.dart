class TerritoryService {
  bool get isAvailable => false;

  String get unavailableReason =>
      'Territory auto-fill by location is not available from the current backend yet.';

  Future<String?> resolveTerritory({
    required double latitude,
    required double longitude,
  }) async {
    return null;
  }
}

class ShopOwnerProfile {
  const ShopOwnerProfile({
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
    required this.shopName,
    required this.address,
    this.territory,
    this.warehouse,
  });

  factory ShopOwnerProfile.fromJson(Map<String, dynamic>? json) {
    String readValue(String key) {
      final value = json?[key];
      return value == null ? '' : value.toString().trim();
    }

    String? readNestedLabel(String key, String nestedKey) {
      final value = json?[key];
      if (value is Map) {
        final nestedValue = value[nestedKey];
        final normalizedValue = nestedValue?.toString().trim();
        if (normalizedValue != null && normalizedValue.isNotEmpty) {
          return normalizedValue;
        }
      }

      return null;
    }

    return ShopOwnerProfile(
      username: readValue('username'),
      firstName: readValue('firstName'),
      lastName: readValue('lastName'),
      phoneNumber: readValue('phoneNumber'),
      email: readValue('email'),
      shopName: readValue('shopName'),
      address: readValue('address'),
      territory:
          _readNullableValue(json?['territoryName']) ??
          readNestedLabel('territory', 'name') ??
          _readNullableValue(json?['territory']),
      warehouse:
          _readNullableValue(json?['warehouseName']) ??
          readNestedLabel('warehouse', 'name'),
    );
  }

  final String username;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;
  final String shopName;
  final String address;
  final String? territory;
  final String? warehouse;

  String get displayShopName => shopName.isNotEmpty
      ? shopName
      : (firstName.isNotEmpty ? '$firstName Store' : 'Nestle Shop');

  String get locationLabel {
    if (address.isEmpty) {
      return 'Sri Lanka';
    }

    final parts = address
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts.first}, ${parts[1]}';
    }

    return parts.first;
  }

  // TODO: Replace this fallback when backend/master data exposes real territory assignments.
  String get territoryLabel => territory != null && territory!.trim().isNotEmpty
      ? territory!.trim()
      : 'Not assigned yet';

  String get addressLabel =>
      address.isNotEmpty ? address : 'No shop location address available yet.';

  Map<String, dynamic> toUserMap() {
    return <String, dynamic>{
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'email': email,
      'shopName': shopName,
      'address': address,
      'territory': territory,
      'warehouse': warehouse,
    };
  }

  ShopOwnerProfile copyWith({
    String? username,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? email,
    String? shopName,
    String? address,
    String? territory,
    String? warehouse,
  }) {
    return ShopOwnerProfile(
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      shopName: shopName ?? this.shopName,
      address: address ?? this.address,
      territory: territory ?? this.territory,
      warehouse: warehouse ?? this.warehouse,
    );
  }

  static String? _readNullableValue(dynamic value) {
    if (value == null) {
      return null;
    }

    final normalizedValue = value.toString().trim();
    return normalizedValue.isEmpty ? null : normalizedValue;
  }
}

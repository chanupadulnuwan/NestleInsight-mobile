/// Dart model matching the backend Promotion entity.
class Promotion {
  const Promotion({
    required this.id,
    required this.name,
    required this.discountType,
    required this.discountValue,
    required this.promotionType,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.eligibleProductNames,
    this.code,
    this.description,
    this.minQuantity,
    this.minOrderValue,
    this.usageLimit,
    this.perShopLimit,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      description: json['description'] as String?,
      promotionType: json['promotionType'] as String? ?? '',
      discountType: json['discountType'] as String? ?? '',
      discountValue: _readDouble(json['discountValue']),
      minQuantity: _readNullableInt(json['minQuantity']),
      minOrderValue: _readNullableDouble(json['minOrderValue']),
      usageLimit: _readNullableInt(json['usageLimit']),
      perShopLimit: _readNullableInt(json['perShopLimit']),
      status: json['status'] as String? ?? 'draft',
      startDate: _readDateTime(json['startDate']),
      endDate: _readDateTime(json['endDate']),
      eligibleProductNames: (json['eligibleProductNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdBy: json['createdBy'] as String?,
      createdAt: _readNullableDateTime(json['createdAt']),
      updatedAt: _readNullableDateTime(json['updatedAt']),
    );
  }

  final String id;
  final String name;
  final String? code;
  final String? description;
  final String promotionType;
  final String discountType;
  final double discountValue;
  final int? minQuantity;
  final double? minOrderValue;
  final int? usageLimit;
  final int? perShopLimit;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> eligibleProductNames;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Human-readable summary of the discount for banner / card display.
  String get offerSummary {
    if (discountType == 'PERCENTAGE') {
      final display = discountValue == discountValue.roundToDouble()
          ? discountValue.toInt().toString()
          : discountValue.toStringAsFixed(1);
      return '$display% off';
    }

    if (discountType == 'FIXED') {
      final display = discountValue == discountValue.roundToDouble()
          ? 'LKR ${discountValue.toInt()}'
          : 'LKR ${discountValue.toStringAsFixed(2)}';
      return '$display off';
    }

    // Fallback for buy-x-get-y or other future types.
    return name;
  }

  /// Formatted end date string (e.g. "25 Apr 2026").
  String get formattedEndDate {
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
    return '${endDate.day} ${months[endDate.month - 1]} ${endDate.year}';
  }

  /// Whether this promotion is still active (not expired).
  bool get isActive {
    final now = DateTime.now();
    return now.isBefore(endDate) && status == 'active';
  }

  /// All promotional rules combined into a readable list.
  List<String> get rules {
    final items = <String>[];

    if (minQuantity != null && minQuantity! > 0) {
      items.add('Minimum quantity: $minQuantity items');
    }

    if (minOrderValue != null && minOrderValue! > 0) {
      final display = minOrderValue == minOrderValue!.roundToDouble()
          ? 'LKR ${minOrderValue!.toInt()}'
          : 'LKR ${minOrderValue!.toStringAsFixed(2)}';
      items.add('Minimum order value: $display');
    }

    if (usageLimit != null && usageLimit! > 0) {
      items.add('Global usage limit: $usageLimit redemptions');
    }

    if (perShopLimit != null && perShopLimit! > 0) {
      items.add('Per-shop limit: $perShopLimit redemptions');
    }

    items.add('Valid from: ${_formatDate(startDate)}');
    items.add('Valid until: ${_formatDate(endDate)}');

    return items;
  }

  static String _formatDate(DateTime dt) {
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

double _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _readNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? _readNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime _readDateTime(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}

DateTime? _readNullableDateTime(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

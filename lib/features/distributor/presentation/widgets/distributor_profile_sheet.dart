import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/distributor/domain/delivery_assignment.dart';

class DistributorProfileData {
  const DistributorProfileData({
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
    required this.territory,
    required this.warehouse,
    required this.address,
    required this.assignmentStatus,
    required this.deliveryDateLabel,
    required this.vehicleLabel,
    required this.vehicleRegistrationNumber,
    required this.distributorName,
  });

  factory DistributorProfileData.fromUser(
    Map<String, dynamic>? json, {
    DeliveryAssignment? assignment,
  }) {
    String readValue(String key) {
      final value = json?[key];
      return value == null ? '' : value.toString().trim();
    }

    final territory = readValue('territoryName').isNotEmpty
        ? readValue('territoryName')
        : readValue('territory');
    final warehouse = readValue('warehouseName').isNotEmpty
        ? readValue('warehouseName')
        : readValue('warehouse');
    final vehicleLabel = assignment?.vehicleLabel?.trim() ?? '';
    final vehicleRegistrationNumber =
        assignment?.vehicleRegistrationNumber?.trim() ?? '';

    return DistributorProfileData(
      username: readValue('username'),
      firstName: readValue('firstName'),
      lastName: readValue('lastName'),
      phoneNumber: readValue('phoneNumber'),
      email: readValue('email'),
      territory: territory,
      warehouse: warehouse,
      address: readValue('address'),
      assignmentStatus: assignment?.status.trim() ?? 'UNASSIGNED',
      deliveryDateLabel: _formatDeliveryDate(assignment?.deliveryDate),
      vehicleLabel: vehicleLabel,
      vehicleRegistrationNumber: vehicleRegistrationNumber,
      distributorName: assignment?.distributorName.trim() ?? '',
    );
  }

  final String username;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;
  final String territory;
  final String warehouse;
  final String address;
  final String assignmentStatus;
  final String deliveryDateLabel;
  final String vehicleLabel;
  final String vehicleRegistrationNumber;
  final String distributorName;

  String get displayName {
    final parts = <String>[
      firstName,
      lastName,
    ].map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
    if (parts.isNotEmpty) {
      return parts.join(' ');
    }
    if (distributorName.isNotEmpty) {
      return distributorName;
    }
    if (username.isNotEmpty) {
      return username;
    }
    return 'Territory Distributor';
  }

  String get firstNameOrFallback {
    if (firstName.trim().isNotEmpty) {
      return firstName.trim();
    }

    final segments = displayName.split(' ');
    return segments.isNotEmpty ? segments.first : 'Distributor';
  }

  String get territoryLabel =>
      territory.isNotEmpty ? territory : 'Territory not assigned';

  String get warehouseLabel =>
      warehouse.isNotEmpty ? warehouse : 'Warehouse not assigned';

  String get addressLabel =>
      address.isNotEmpty ? address : 'No address available';

  String get vehicleHeadline {
    if (vehicleLabel.isNotEmpty) {
      return vehicleLabel;
    }

    if (vehicleRegistrationNumber.isNotEmpty) {
      return vehicleRegistrationNumber;
    }

    return 'Vehicle pending';
  }

  String get vehicleSubLabel {
    if (vehicleRegistrationNumber.isNotEmpty && vehicleLabel.isNotEmpty) {
      return vehicleRegistrationNumber;
    }

    return vehicleLabel.isNotEmpty
        ? 'Assigned for today'
        : 'Waiting for route assignment';
  }

  String get phoneLabel =>
      phoneNumber.isNotEmpty ? phoneNumber : 'No phone number available';

  String get emailLabel => email.isNotEmpty ? email : 'No email available';

  String get statusLabel {
    final normalized = assignmentStatus.trim();
    if (normalized.isEmpty) {
      return 'Unassigned';
    }

    return normalized
        .toLowerCase()
        .split(RegExp(r'[_\s]+'))
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  String get headerLocationLabel {
    if (territory.isNotEmpty) {
      return territory;
    }
    if (warehouse.isNotEmpty) {
      return warehouse;
    }
    return 'Sri Lanka';
  }
}

class DistributorProfileSheet extends StatelessWidget {
  const DistributorProfileSheet({
    super.key,
    required this.profile,
    required this.onLogoutRequested,
  });

  final DistributorProfileData profile;
  final Future<void> Function() onLogoutRequested;

  Future<void> _handleLogout(BuildContext context) async {
    Navigator.of(context).pop();
    await onLogoutRequested();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: FractionallySizedBox(
          heightFactor: 0.86,
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 12),
                Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.outlineWarm,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _ProfileHero(profile: profile),
                        const SizedBox(height: 22),
                        _SectionTitle(title: 'Account'),
                        _InfoCard(
                          children: <Widget>[
                            _InfoRow(
                              icon: Icons.badge_outlined,
                              label: 'Username',
                              value: profile.username.isNotEmpty
                                  ? profile.username
                                  : 'Not available',
                            ),
                            _InfoRow(
                              icon: Icons.mail_outline,
                              label: 'Email',
                              value: profile.emailLabel,
                            ),
                            _InfoRow(
                              icon: Icons.phone_outlined,
                              label: 'Phone',
                              value: profile.phoneLabel,
                            ),
                            _InfoRow(
                              icon: Icons.place_outlined,
                              label: 'Address',
                              value: profile.addressLabel,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _SectionTitle(title: 'Assignment'),
                        _InfoCard(
                          children: <Widget>[
                            _InfoRow(
                              icon: Icons.route_outlined,
                              label: 'Territory',
                              value: profile.territoryLabel,
                            ),
                            _InfoRow(
                              icon: Icons.warehouse_outlined,
                              label: 'Warehouse',
                              value: profile.warehouseLabel,
                            ),
                            _InfoRow(
                              icon: Icons.local_shipping_outlined,
                              label: 'Vehicle',
                              value:
                                  '${profile.vehicleHeadline}\n${profile.vehicleSubLabel}',
                            ),
                            _InfoRow(
                              icon: Icons.event_available_outlined,
                              label: 'Today',
                              value:
                                  '${profile.deliveryDateLabel}\n${profile.statusLabel}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceWarm,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppTheme.outlineWarm.withAlpha(110),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceTint,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.tune_outlined,
                                  color: AppTheme.primaryBrownDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Need account changes?',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: AppTheme.textDark,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Use the Settings tab to update security while keeping the same distributor workflow.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: AppTheme.textSoft),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => _handleLogout(context),
                          icon: const Icon(Icons.logout_outlined),
                          label: const Text('Logout'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryBrownDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile});

  final DistributorProfileData profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppTheme.headerGradientStart,
            AppTheme.headerGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(28),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(180)),
            ),
            child: const Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  profile.displayName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Territory Distributor',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withAlpha(220),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _HeroChip(
                      icon: Icons.route_outlined,
                      label: profile.territoryLabel,
                    ),
                    _HeroChip(
                      icon: Icons.local_shipping_outlined,
                      label: profile.vehicleHeadline,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppTheme.textDark,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.outlineWarm.withAlpha(110)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.primaryBrownDark.withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primaryBrownDark, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSoft,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
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

String _formatDeliveryDate(String? rawDate) {
  if (rawDate == null || rawDate.trim().isEmpty) {
    return 'Not scheduled yet';
  }

  final parsed = DateTime.tryParse(rawDate);
  if (parsed == null) {
    return rawDate;
  }

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

  final localDate = parsed.toLocal();
  return '${localDate.day} ${months[localDate.month - 1]} ${localDate.year}';
}

import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/utils/form_validators.dart';
import 'package:mobile/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:mobile/features/distributor/domain/delivery_assignment.dart';
import 'package:mobile/features/profile/data/services/profile_service.dart';
import 'package:mobile/features/profile/domain/shop_owner_profile.dart';

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

  DistributorProfileData withEditableProfile(ShopOwnerProfile profile) {
    return DistributorProfileData(
      username: profile.username,
      firstName: profile.firstName,
      lastName: profile.lastName,
      phoneNumber: profile.phoneNumber,
      email: profile.email,
      territory: profile.territory ?? territory,
      warehouse: profile.warehouse ?? warehouse,
      address: profile.address,
      assignmentStatus: assignmentStatus,
      deliveryDateLabel: deliveryDateLabel,
      vehicleLabel: vehicleLabel,
      vehicleRegistrationNumber: vehicleRegistrationNumber,
      distributorName: distributorName,
    );
  }

  Map<String, dynamic> toUserMap() {
    return <String, dynamic>{
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'territory': territory,
      'territoryName': territory,
      'warehouse': warehouse,
      'warehouseName': warehouse,
    };
  }
}

class DistributorProfileSheet extends StatefulWidget {
  const DistributorProfileSheet({
    super.key,
    required this.profile,
    required this.onLogoutRequested,
    required this.onProfileSaved,
    this.profileService,
  });

  final DistributorProfileData profile;
  final Future<void> Function() onLogoutRequested;
  final ValueChanged<DistributorProfileData> onProfileSaved;
  final ProfileService? profileService;

  @override
  State<DistributorProfileSheet> createState() => _DistributorProfileSheetState();
}

class _DistributorProfileSheetState extends State<DistributorProfileSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _usernameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _emailController;
  late final TextEditingController _territoryController;
  late final TextEditingController _warehouseController;
  late final TextEditingController _addressController;

  late final ProfileService _profileService;
  late DistributorProfileData _profile;
  late ShopOwnerProfile _editableProfile;

  bool _isEditing = false;
  bool _isLoadingProfile = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _profileService = widget.profileService ?? ProfileService();
    _profile = widget.profile;
    _editableProfile = _seedEditableProfile(widget.profile);

    _usernameController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _emailController = TextEditingController();
    _territoryController = TextEditingController();
    _warehouseController = TextEditingController();
    _addressController = TextEditingController();

    _applyProfile(_editableProfile);
    _refreshProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _territoryController.dispose();
    _warehouseController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  ShopOwnerProfile _seedEditableProfile(DistributorProfileData profile) {
    return ShopOwnerProfile(
      username: profile.username,
      firstName: profile.firstName,
      lastName: profile.lastName,
      phoneNumber: profile.phoneNumber,
      email: profile.email,
      shopName: '',
      address: profile.address,
      territory: profile.territory,
      warehouse: profile.warehouse,
    );
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final result = await _profileService.getCurrentProfile();

      if (!mounted) {
        return;
      }

      final nextProfile = _profile.withEditableProfile(result.profile);
      setState(() {
        _editableProfile = result.profile;
        _profile = nextProfile;
        _applyProfile(result.profile);
      });
      widget.onProfileSaved(nextProfile);
    } on ProfileServiceException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  void _applyProfile(ShopOwnerProfile profile) {
    _usernameController.text = profile.username;
    _firstNameController.text = profile.firstName;
    _lastNameController.text = profile.lastName;
    _phoneNumberController.text = profile.phoneNumber;
    _emailController.text = profile.email;
    _territoryController.text =
        profile.territory?.trim().isNotEmpty == true
            ? profile.territory!.trim()
            : _profile.territoryLabel;
    _warehouseController.text =
        profile.warehouse?.trim().isNotEmpty == true
            ? profile.warehouse!.trim()
            : _profile.warehouseLabel;
    _addressController.text = profile.address;
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _applyProfile(_editableProfile);
    });
  }

  Future<void> _saveProfile() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    try {
      final result = await _profileService.updateCurrentProfile(
        username: _usernameController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phoneNumber: _phoneNumberController.text,
        email: _emailController.text,
      );

      if (!mounted) {
        return;
      }

      final nextProfile = _profile.withEditableProfile(result.profile);
      setState(() {
        _isEditing = false;
        _editableProfile = result.profile;
        _profile = nextProfile;
        _applyProfile(result.profile);
      });
      widget.onProfileSaved(nextProfile);
      _showMessage(result.message);
    } on ProfileServiceException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    Navigator.of(context).pop();
    await widget.onLogoutRequested();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.textDark,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomTextField(
        labelText: label,
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        prefixIcon: Icon(icon),
        readOnly: !_isEditing,
        enabled: !_isSaving,
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomTextField(
        labelText: label,
        controller: controller,
        prefixIcon: Icon(icon),
        helperText: helperText,
        maxLines: maxLines,
        readOnly: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: FractionallySizedBox(
          heightFactor: 0.92,
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: Form(
              key: _formKey,
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Profile',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: AppTheme.textDark,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isEditing
                                    ? 'Update your distributor account details and save the changes.'
                                    : 'Review your distributor profile and switch to edit mode when needed.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isEditing)
                          TextButton(
                            onPressed: _isSaving ? null : _cancelEditing,
                            child: const Text('Cancel'),
                          )
                        else
                          TextButton.icon(
                            onPressed: _isLoadingProfile
                                ? null
                                : () {
                                    setState(() {
                                      _isEditing = true;
                                    });
                                  },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit'),
                          ),
                      ],
                    ),
                  ),
                  if (_isLoadingProfile)
                    const LinearProgressIndicator(minHeight: 2),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _ProfileHero(profile: _profile),
                          const SizedBox(height: 20),
                          _buildSectionTitle('Account details'),
                          _buildEditableField(
                            label: 'Username',
                            controller: _usernameController,
                            validator: FormValidators.username,
                            icon: Icons.alternate_email_outlined,
                            textInputAction: TextInputAction.next,
                          ),
                          _buildEditableField(
                            label: 'First name',
                            controller: _firstNameController,
                            validator: (value) => FormValidators.personName(
                              value,
                              fieldName: 'First name',
                            ),
                            icon: Icons.person_outline,
                            textInputAction: TextInputAction.next,
                          ),
                          _buildEditableField(
                            label: 'Last name',
                            controller: _lastNameController,
                            validator: (value) => FormValidators.personName(
                              value,
                              fieldName: 'Last name',
                            ),
                            icon: Icons.person_outline,
                            textInputAction: TextInputAction.next,
                          ),
                          _buildEditableField(
                            label: 'Telephone number',
                            controller: _phoneNumberController,
                            validator: FormValidators.phoneNumber,
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                          ),
                          _buildEditableField(
                            label: 'Email',
                            controller: _emailController,
                            validator: FormValidators.email,
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: 8),
                          _buildSectionTitle('Assignment details'),
                          _buildReadOnlyField(
                            label: 'Territory',
                            controller: _territoryController,
                            icon: Icons.route_outlined,
                            helperText:
                                'Territory assignment is controlled by the warehouse team.',
                          ),
                          _buildReadOnlyField(
                            label: 'Warehouse',
                            controller: _warehouseController,
                            icon: Icons.warehouse_outlined,
                          ),
                          _buildReadOnlyField(
                            label: 'Address',
                            controller: _addressController,
                            icon: Icons.place_outlined,
                            maxLines: 3,
                            helperText:
                                'Address updates are managed centrally for distributor accounts.',
                          ),
                          _InfoCard(
                            children: <Widget>[
                              _InfoRow(
                                icon: Icons.local_shipping_outlined,
                                label: 'Vehicle',
                                value:
                                    '${_profile.vehicleHeadline}\n${_profile.vehicleSubLabel}',
                              ),
                              _InfoRow(
                                icon: Icons.event_available_outlined,
                                label: 'Today',
                                value:
                                    '${_profile.deliveryDateLabel}\n${_profile.statusLabel}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (_isEditing) ...<Widget>[
                            FilledButton.icon(
                              onPressed: _isSaving ? null : _saveProfile,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                _isSaving ? 'Saving...' : 'Save changes',
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _handleLogout,
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

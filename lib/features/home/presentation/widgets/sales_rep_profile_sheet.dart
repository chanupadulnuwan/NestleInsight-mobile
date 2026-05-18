import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/utils/form_validators.dart';
import 'package:mobile/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:mobile/features/profile/data/services/profile_service.dart';
import 'package:mobile/features/profile/domain/shop_owner_profile.dart';

class SalesRepProfileData {
  const SalesRepProfileData({
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.username,
    required this.email,
    required this.mobileNumber,
    required this.territoryName,
    required this.hasActiveRoute,
    required this.hasReportableRoute,
    required this.shopsLeft,
  });

  final String firstName;
  final String lastName;
  final String fullName;
  final String username;
  final String email;
  final String mobileNumber;
  final String territoryName;
  final bool hasActiveRoute;
  final bool hasReportableRoute;
  final int shopsLeft;

  String get displayName {
    if (fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    final parts = <String>[
      firstName.trim(),
      lastName.trim(),
    ].where((part) => part.isNotEmpty).toList();
    if (parts.isNotEmpty) {
      return parts.join(' ');
    }
    if (username.trim().isNotEmpty) {
      return username.trim();
    }
    return 'Sales Representative';
  }

  String get phoneLabel => mobileNumber.trim().isNotEmpty
      ? mobileNumber.trim()
      : 'No mobile number available';

  String get emailLabel =>
      email.trim().isNotEmpty ? email.trim() : 'No email available';

  String get territoryLabel => territoryName.trim().isNotEmpty
      ? territoryName.trim()
      : 'Territory not assigned';

  String get routeStatusLabel {
    if (hasActiveRoute) {
      return 'Route active';
    }
    if (hasReportableRoute) {
      return 'Route closed';
    }
    return 'No active route';
  }

  String get routeStatusDetail {
    if (hasActiveRoute) {
      if (shopsLeft <= 0) {
        return 'Today\'s shop list is complete.';
      }
      if (shopsLeft == 1) {
        return '1 shop is left to visit today.';
      }
      return '$shopsLeft shops are left to visit today.';
    }
    if (hasReportableRoute) {
      return 'Final report is ready to generate and upload.';
    }
    return 'Start the day to begin today\'s route.';
  }

  String get workloadLabel {
    if (hasActiveRoute) {
      if (shopsLeft <= 0) {
        return 'All assigned outlets are covered.';
      }
      return shopsLeft == 1
          ? '1 outlet still needs attention.'
          : '$shopsLeft outlets still need attention.';
    }
    return hasReportableRoute
        ? 'The route is closed and waiting for the final upload.'
        : 'Waiting for route planning and opening stock.';
  }

  SalesRepProfileData withEditableProfile(ShopOwnerProfile profile) {
    final combinedName = <String>[
      profile.firstName.trim(),
      profile.lastName.trim(),
    ].where((part) => part.isNotEmpty).join(' ');

    return SalesRepProfileData(
      firstName: profile.firstName,
      lastName: profile.lastName,
      fullName: combinedName.isNotEmpty ? combinedName : fullName,
      username: profile.username,
      email: profile.email,
      mobileNumber: profile.phoneNumber,
      territoryName:
          profile.territory?.trim().isNotEmpty == true
              ? profile.territory!.trim()
              : territoryName,
      hasActiveRoute: hasActiveRoute,
      hasReportableRoute: hasReportableRoute,
      shopsLeft: shopsLeft,
    );
  }
}

class SalesRepProfileSheet extends StatefulWidget {
  const SalesRepProfileSheet({
    super.key,
    required this.profile,
    required this.initialImagePath,
    required this.onProfileImageChanged,
    required this.onLogoutRequested,
    required this.onProfileSaved,
    this.profileService,
  });

  final SalesRepProfileData profile;
  final String? initialImagePath;
  final Future<void> Function(String? imagePath) onProfileImageChanged;
  final Future<void> Function() onLogoutRequested;
  final Future<void> Function(
    String previousUsername,
    SalesRepProfileData profile,
  )
  onProfileSaved;
  final ProfileService? profileService;

  @override
  State<SalesRepProfileSheet> createState() => _SalesRepProfileSheetState();
}

class _SalesRepProfileSheetState extends State<SalesRepProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _usernameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _emailController;
  late final TextEditingController _territoryController;

  late final ProfileService _profileService;
  late SalesRepProfileData _profile;
  late ShopOwnerProfile _editableProfile;
  late String? _imagePath;

  bool _isPickingImage = false;
  bool _isEditing = false;
  bool _isLoadingProfile = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _profileService = widget.profileService ?? ProfileService();
    _profile = widget.profile;
    _editableProfile = _seedEditableProfile(widget.profile);
    _imagePath = widget.initialImagePath;

    _usernameController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _emailController = TextEditingController();
    _territoryController = TextEditingController();

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
    super.dispose();
  }

  ShopOwnerProfile _seedEditableProfile(SalesRepProfileData profile) {
    return ShopOwnerProfile(
      username: profile.username,
      firstName: profile.firstName,
      lastName: profile.lastName,
      phoneNumber: profile.mobileNumber,
      email: profile.email,
      shopName: '',
      address: '',
      territory: profile.territoryName,
      warehouse: null,
    );
  }

  bool get _hasImage {
    final path = _imagePath?.trim();
    if (path == null || path.isEmpty) {
      return false;
    }
    return File(path).existsSync();
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

      setState(() {
        _editableProfile = result.profile;
        _profile = _profile.withEditableProfile(result.profile);
        _applyProfile(result.profile);
      });
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
    final previousUsername = _profile.username;

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
      await widget.onProfileSaved(previousUsername, nextProfile);
      if (!mounted) {
        return;
      }
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

  Future<void> _pickImage() async {
    setState(() {
      _isPickingImage = true;
    });

    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1200,
      );

      if (file == null) {
        return;
      }

      await widget.onProfileImageChanged(file.path);
      if (!mounted) {
        return;
      }

      setState(() {
        _imagePath = file.path;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('Unable to select a profile picture right now.');
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _removeImage() async {
    await widget.onProfileImageChanged(null);
    if (!mounted) {
      return;
    }

    setState(() {
      _imagePath = null;
    });
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
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomTextField(
        labelText: label,
        controller: controller,
        prefixIcon: Icon(icon),
        helperText: helperText,
        readOnly: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: AppTheme.textDark,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isEditing
                                    ? 'Update your sales rep account details and save the changes.'
                                    : 'Review your profile, edit account details, and keep your photo up to date.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppTheme.textSoft),
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
                          _ProfileHero(
                            profile: _profile,
                            imagePath: _imagePath,
                            hasImage: _hasImage,
                          ),
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
                            label: 'Mobile number',
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
                          _buildSectionTitle('Field work'),
                          _buildReadOnlyField(
                            label: 'Assigned territory',
                            controller: _territoryController,
                            icon: Icons.route_outlined,
                            helperText:
                                'Territory assignment is managed by the warehouse team.',
                          ),
                          _InfoCard(
                            children: <Widget>[
                              _InfoRow(
                                icon: Icons.local_shipping_outlined,
                                label: 'Route status',
                                value:
                                    '${_profile.routeStatusLabel}\n${_profile.routeStatusDetail}',
                              ),
                              _InfoRow(
                                icon: Icons.assignment_turned_in_outlined,
                                label: 'Current workload',
                                value: _profile.workloadLabel,
                                isLast: true,
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
                                    Icons.photo_camera_back_outlined,
                                    color: AppTheme.primaryBrownDark,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Profile picture',
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
                                        'Add or change a profile photo any time from this panel.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppTheme.textSoft,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: <Widget>[
                              FilledButton.icon(
                                onPressed: _isPickingImage ? null : _pickImage,
                                icon: _isPickingImage
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.photo_library_outlined),
                                label: Text(
                                  _hasImage ? 'Change photo' : 'Add photo',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBrown,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                              if (_hasImage)
                                OutlinedButton.icon(
                                  onPressed: _removeImage,
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Remove photo'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryBrownDark,
                                    side: BorderSide(
                                      color:
                                          AppTheme.outlineWarm.withAlpha(180),
                                    ),
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
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
  const _ProfileHero({
    required this.profile,
    required this.imagePath,
    required this.hasImage,
  });

  final SalesRepProfileData profile;
  final String? imagePath;
  final bool hasImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF5A382A), Color(0xFF211714)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(28),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(180)),
            ),
            child: ClipOval(
              child: hasImage
                  ? Image.file(
                      File(imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 34,
                      ),
                    )
                  : const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 34,
                    ),
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
                  'Sales Representative',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withAlpha(220),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep your sales rep details current and ready for field work.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withAlpha(210),
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
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
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

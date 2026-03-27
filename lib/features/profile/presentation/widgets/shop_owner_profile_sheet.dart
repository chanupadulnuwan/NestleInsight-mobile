import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/utils/form_validators.dart';
import 'package:mobile/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:mobile/features/profile/data/services/profile_service.dart';
import 'package:mobile/features/profile/domain/shop_owner_profile.dart';

class ShopOwnerProfileSheet extends StatefulWidget {
  const ShopOwnerProfileSheet({
    super.key,
    required this.initialProfile,
    required this.onProfileSaved,
    required this.onLogoutRequested,
    this.profileService,
  });

  final ShopOwnerProfile initialProfile;
  final ValueChanged<ShopOwnerProfile> onProfileSaved;
  final Future<void> Function() onLogoutRequested;
  final ProfileService? profileService;

  @override
  State<ShopOwnerProfileSheet> createState() => _ShopOwnerProfileSheetState();
}

class _ShopOwnerProfileSheetState extends State<ShopOwnerProfileSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _usernameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _emailController;
  late final TextEditingController _shopNameController;
  late final TextEditingController _territoryController;
  late final TextEditingController _addressController;

  late final ProfileService _profileService;
  late ShopOwnerProfile _profile;

  bool _isEditing = false;
  bool _isLoadingProfile = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _profileService = widget.profileService ?? ProfileService();
    _profile = widget.initialProfile;

    _usernameController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _emailController = TextEditingController();
    _shopNameController = TextEditingController();
    _territoryController = TextEditingController();
    _addressController = TextEditingController();

    _applyProfile(_profile);
    _refreshProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _shopNameController.dispose();
    _territoryController.dispose();
    _addressController.dispose();
    super.dispose();
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
        _profile = result.profile;
        _applyProfile(result.profile);
      });
      widget.onProfileSaved(result.profile);
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
    _shopNameController.text = profile.shopName;
    _territoryController.text = profile.territoryLabel;
    _addressController.text = profile.addressLabel;
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _applyProfile(_profile);
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
        shopName: _shopNameController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isEditing = false;
        _profile = result.profile;
        _applyProfile(result.profile);
      });
      widget.onProfileSaved(result.profile);
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

  Future<void> _showHelpDialog() {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Help'),
          content: const Text(
            'If you need assistance, please contact your regional office.\n\n'
            'Phone: +94 11 234 5678\n'
            'Email: regionaloffice@nestleinsight.lk',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
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
                                    ? 'Update your account details and save the changes.'
                                    : 'Review your shop owner details and switch to edit mode when needed.',
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
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
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
                            textInputAction: TextInputAction.next,
                          ),
                          _buildEditableField(
                            label: 'Shop name',
                            controller: _shopNameController,
                            validator: (value) => FormValidators.required(
                              value,
                              fieldName: 'Shop name',
                            ),
                            icon: Icons.storefront_outlined,
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: 8),
                          _buildSectionTitle('Shop details'),
                          _buildReadOnlyField(
                            label: 'Territory',
                            controller: _territoryController,
                            icon: Icons.route_outlined,
                            helperText:
                                'Read-only for now until territory master data is available.',
                          ),
                          _buildReadOnlyField(
                            label: 'Shop location address',
                            controller: _addressController,
                            icon: Icons.place_outlined,
                            maxLines: 3,
                            helperText:
                                'This is controlled by the selected map location.',
                          ),
                          const SizedBox(height: 8),
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
                          TextButton.icon(
                            onPressed: _showHelpDialog,
                            icon: const Icon(Icons.help_outline),
                            label: const Text('Help'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _handleLogout,
                            icon: const Icon(Icons.logout_outlined),
                            label: const Text('Logout'),
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

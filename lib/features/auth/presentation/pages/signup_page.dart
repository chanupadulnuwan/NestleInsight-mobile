import 'package:flutter/material.dart';
import 'package:mobile/core/services/location_picker_service.dart';
import 'package:mobile/core/services/territory_service.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/utils/form_validators.dart';
import 'package:mobile/features/auth/data/services/auth_service.dart';
import 'package:mobile/features/auth/domain/public_user_role.dart';
import 'package:mobile/features/auth/presentation/pages/otp_verification_page.dart';
import 'package:mobile/features/auth/presentation/widgets/auth_page_shell.dart';
import 'package:mobile/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:mobile/features/auth/presentation/widgets/role_dropdown_field.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _territoryController = TextEditingController();
  final _warehouseController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _shopLocationController = TextEditingController();

  final _authService = AuthService();
  final _locationPickerService = LocationPickerService();
  final _territoryService = TerritoryService();

  PublicUserRole? _selectedRole;
  LocationSelection? _selectedLocation;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  bool get _isShopOwner => _selectedRole == PublicUserRole.shopOwner;
  bool get _isEmployeeRole => _selectedRole?.isEmployeeRole ?? false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _employeeIdController.dispose();
    _territoryController.dispose();
    _warehouseController.dispose();
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _shopLocationController.dispose();
    super.dispose();
  }

  void _resetRoleSpecificFields() {
    _selectedLocation = null;
    _employeeIdController.clear();
    _territoryController.clear();
    _warehouseController.clear();
    _shopNameController.clear();
    _shopAddressController.clear();
    _shopLocationController.clear();
  }

  Future<void> _openLocationPicker() async {
    final selectedLocation = await _locationPickerService.pickLocation(
      context: context,
      initialSelection: _selectedLocation,
    );

    if (!mounted || selectedLocation == null) {
      return;
    }

    setState(() {
      _selectedLocation = selectedLocation;
      _shopLocationController.text = selectedLocation.summary;
      _shopAddressController.text = selectedLocation.addressLine;
      _territoryController.clear();
      _warehouseController.clear();
    });

    try {
      final assignment = await _territoryService.resolveAssignment(
        latitude: selectedLocation.latitude,
        longitude: selectedLocation.longitude,
      );

      if (!mounted) {
        return;
      }

      if (assignment != null) {
        setState(() {
          _territoryController.text = assignment.territoryName;
          _warehouseController.text = assignment.warehouseName;
        });
      }
    } on TerritoryServiceException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    }
  }

  Future<void> _resolveEmployeeWarehouse() async {
    final warehouseName = _warehouseController.text.trim();
    if (warehouseName.isEmpty || !_isEmployeeRole) {
      _territoryController.clear();
      return;
    }

    try {
      final assignment = await _territoryService.lookupWarehouse(warehouseName);
      if (!mounted) {
        return;
      }

      setState(() {
        _warehouseController.text = assignment.warehouseName;
        _territoryController.text = assignment.territoryName;
      });
    } on TerritoryServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _territoryController.clear();
      });
      _showMessage(error.message);
    }
  }

  Future<void> _handleRegister() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    if (_selectedRole == null) {
      _showMessage('Select a role to continue.');
      return;
    }

    if (_isShopOwner && _selectedLocation == null) {
      _showMessage('Pick the shop location from the map to continue.');
      return;
    }

    if (_isEmployeeRole && _warehouseController.text.trim().isEmpty) {
      _showMessage('Enter the registered warehouse name to continue.');
      return;
    }

    if (_isEmployeeRole && _territoryController.text.trim().isEmpty) {
      _showMessage(
        'Use a registered warehouse name so the territory can be matched automatically.',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await _authService.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        role: _selectedRole!,
        employeeId: _employeeIdController.text.trim().isEmpty
            ? null
            : _employeeIdController.text.trim(),
        warehouseName: _isEmployeeRole
            ? _warehouseController.text.trim()
            : _warehouseController.text.trim().isEmpty
                ? null
                : _warehouseController.text.trim(),
        shopName: _isShopOwner ? _shopNameController.text.trim() : null,
        address: _isShopOwner ? _shopAddressController.text.trim() : null,
        latitude: _selectedLocation?.latitude,
        longitude: _selectedLocation?.longitude,
      );

      if (!mounted) {
        return;
      }

      if (result.otpRequired) {
        final verified = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => OtpVerificationPage(
              identifier: _emailController.text.trim(),
              initialDebugOtpCode: result.debugOtpCode,
              initialOtpDeliveryMethod: result.otpDeliveryMethod,
              title: 'Verify your account',
              subtitle:
                  'Enter the 6-digit OTP for ${_emailController.text.trim()} to finish creating your account.',
            ),
          ),
        );

        if (!mounted) {
          return;
        }

        if (verified == true) {
          _showMessage('Account verified. You can sign in now.');
          Navigator.of(context).pop(_emailController.text.trim());
        }
        return;
      }

      _showMessage(result.message);
      Navigator.of(context).pop(_emailController.text.trim());
    } on AuthServiceException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildNoticeCard({required IconData icon, required String message}) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTint,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outlineWarm.withAlpha(140)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryBrownDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeFields() {
    return Column(
      children: [
        _buildSectionTitle('Employment details'),
        CustomTextField(
          labelText: 'Employee ID',
          hintText: 'Enter it if you already have one',
          controller: _employeeIdController,
          prefixIcon: const Icon(Icons.badge_outlined),
          textInputAction: TextInputAction.next,
          helperText: 'Optional for now.',
        ),
        const SizedBox(height: 16),
        CustomTextField(
          labelText: 'Warehouse name',
          hintText: 'Enter the registered warehouse name',
          controller: _warehouseController,
          prefixIcon: const Icon(Icons.inventory_2_outlined),
          textInputAction: TextInputAction.next,
          helperText: 'The territory will auto-fill after the warehouse name matches.',
          validator: (value) {
            if (!_isEmployeeRole) {
              return null;
            }

            return FormValidators.required(value, fieldName: 'Warehouse name');
          },
          onChanged: (_) {
            _territoryController.clear();
          },
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _resolveEmployeeWarehouse,
            child: const Text('Check warehouse'),
          ),
        ),
        CustomTextField(
          labelText: 'Territory',
          hintText: 'Auto-filled from the registered warehouse',
          controller: _territoryController,
          prefixIcon: const Icon(Icons.map_outlined),
          helperText:
              'Read-only. It fills automatically when the warehouse name matches.',
          readOnly: true,
        ),
      ],
    );
  }

  Widget _buildShopOwnerFields() {
    return Column(
      children: [
        _buildSectionTitle('Shop details'),
        CustomTextField(
          labelText: 'Shop name',
          hintText: 'Enter the registered shop name',
          controller: _shopNameController,
          prefixIcon: const Icon(Icons.storefront_outlined),
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (!_isShopOwner) {
              return null;
            }

            return FormValidators.required(value, fieldName: 'Shop name');
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          labelText: 'Location',
          hintText: 'Tap to pick the location on the map',
          controller: _shopLocationController,
          prefixIcon: const Icon(Icons.place_outlined),
          suffixIcon: const Icon(Icons.map_outlined),
          helperText: _locationPickerService.unavailableMessage,
          readOnly: true,
          onTap: _openLocationPicker,
          validator: (value) {
            if (!_isShopOwner) {
              return null;
            }

            return FormValidators.required(value, fieldName: 'Location');
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          labelText: 'Address',
          hintText: 'Will auto-fill from the selected location',
          controller: _shopAddressController,
          prefixIcon: const Icon(Icons.home_work_outlined),
          maxLines: 2,
          textInputAction: TextInputAction.next,
          helperText: 'Auto-filled from the map, but you can still edit it.',
          validator: (value) {
            if (!_isShopOwner) {
              return null;
            }

            return FormValidators.required(value, fieldName: 'Address');
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          labelText: 'Territory',
          hintText: 'Auto-filled from the selected location',
          controller: _territoryController,
          prefixIcon: const Icon(Icons.route_outlined),
          helperText: 'Assigned from the nearest territory.',
          readOnly: true,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          labelText: 'Warehouse',
          hintText: 'Auto-filled from the selected location',
          controller: _warehouseController,
          prefixIcon: const Icon(Icons.inventory_2_outlined),
          helperText: 'Assigned from the nearest warehouse.',
          readOnly: true,
        ),
        const SizedBox(height: 16),
        _buildNoticeCard(
          icon: Icons.info_outline,
          message:
              'Choose the shop location from the popup map. The address now fills automatically from the selected point.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthPageShell(
      appBar: AppBar(title: const Text('Create account')),
      title: 'Create your account',
      subtitle:
          'Fill in your details, verify OTP, and start using Nestle Insight.',
      header: Image.asset(
        'assets/images/logpage.png',
        height: 168,
        fit: BoxFit.contain,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildNoticeCard(
              icon: Icons.info_outline,
              message:
                  'Signup now uses first name and last name. For shop owners, the location popup map will auto-fill the address, and OTP verification completes the account setup.',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Personal information'),
            CustomTextField(
              labelText: 'First name',
              hintText: 'Enter your first name',
              controller: _firstNameController,
              prefixIcon: const Icon(Icons.person_outline),
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  FormValidators.personName(value, fieldName: 'First name'),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              labelText: 'Last name',
              hintText: 'Enter your last name',
              controller: _lastNameController,
              prefixIcon: const Icon(Icons.person_outline),
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  FormValidators.personName(value, fieldName: 'Last name'),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              labelText: 'Username',
              hintText: 'Choose a username',
              controller: _usernameController,
              prefixIcon: const Icon(Icons.alternate_email_outlined),
              textInputAction: TextInputAction.next,
              helperText: 'Letters, numbers, and underscores only.',
              validator: FormValidators.username,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              labelText: 'Email',
              hintText: 'name@example.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.mail_outline),
              textInputAction: TextInputAction.next,
              validator: FormValidators.email,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              labelText: 'Telephone number',
              hintText: '+94XXXXXXXXX',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_outlined),
              textInputAction: TextInputAction.next,
              validator: FormValidators.phoneNumber,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Account role'),
            RoleDropdownField(
              value: _selectedRole,
              onChanged: (value) {
                setState(() {
                  _selectedRole = value;
                  _resetRoleSpecificFields();
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Select a role.';
                }

                return null;
              },
            ),
            const SizedBox(height: 24),
            if (_isEmployeeRole) ...[
              _buildEmployeeFields(),
              const SizedBox(height: 24),
            ],
            if (_isShopOwner) ...[
              _buildShopOwnerFields(),
              const SizedBox(height: 24),
            ],
            _buildSectionTitle('Security'),
            CustomTextField(
              labelText: 'Password',
              controller: _passwordController,
              obscureText: _obscurePassword,
              prefixIcon: const Icon(Icons.lock_outline),
              textInputAction: TextInputAction.next,
              helperText:
                  'Use at least 8 characters with uppercase, lowercase, and a number.',
              validator: FormValidators.password,
              onChanged: (_) {
                if (_confirmPasswordController.text.isNotEmpty) {
                  _formKey.currentState?.validate();
                }
              },
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              labelText: 'Confirm password',
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              prefixIcon: const Icon(Icons.lock_reset_outlined),
              textInputAction: TextInputAction.done,
              validator: (value) => FormValidators.confirmPassword(
                value,
                password: _passwordController.text,
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _handleRegister,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Create account',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSoft,
                    ),
                  ),
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    child: const Text('Log in'),
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

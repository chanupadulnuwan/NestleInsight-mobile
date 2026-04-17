import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/outlet_cubit.dart';

class RegisterOutletPage extends StatefulWidget {
  const RegisterOutletPage({
    super.key,
    this.territoryId = '00000000-0000-0000-0000-000000000001',
  });

  final String territoryId;

  @override
  State<RegisterOutletPage> createState() => _RegisterOutletPageState();
}

class _RegisterOutletPageState extends State<RegisterOutletPage> {
  final _outletNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _outletNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submitForm(BuildContext context) {
    if (_outletNameController.text.isEmpty ||
        _ownerNameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _addressController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    // Mock GPS coordinates for now
    const mockLatitude = 6.5244;
    const mockLongitude = 3.3792;

    context.read<OutletCubit>().registerOutlet(
      name: _outletNameController.text,
      owner: _ownerNameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      address: _addressController.text,
      latitude: mockLatitude,
      longitude: mockLongitude,
      territoryId: widget.territoryId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OutletCubit(),
      child: BlocListener<OutletCubit, OutletState>(
        listener: (context, state) {
          if (state is OutletError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is OutletSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          backgroundColor: AppTheme.surfaceWarm,
          appBar: AppBar(title: const Text('Register Outlet')),
          body: BlocBuilder<OutletCubit, OutletState>(
            builder: (context, state) {
              final isLoading = state is OutletLoading;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _TextField(
                      label: 'Outlet Name',
                      controller: _outletNameController,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    _TextField(
                      label: 'Owner Name',
                      controller: _ownerNameController,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    _TextField(
                      label: 'Phone',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    _TextField(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    _TextField(
                      label: 'Address',
                      controller: _addressController,
                      maxLines: 3,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () => _submitForm(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBrown,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Register Outlet',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

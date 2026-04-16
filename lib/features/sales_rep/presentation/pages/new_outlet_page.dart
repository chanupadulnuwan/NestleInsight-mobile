import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/sales_rep/data/services/route_setup_service.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/register_outlet_cubit.dart';

class NewOutletPage extends StatefulWidget {
  const NewOutletPage({super.key});

  @override
  State<NewOutletPage> createState() => _NewOutletPageState();
}

class _NewOutletPageState extends State<NewOutletPage> {
  final _formKey = GlobalKey<FormState>();
  final _outletNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedTerritoryId;
  double? _currentLatitude;
  double? _currentLongitude;

  @override
  void dispose() {
    _outletNameController.dispose();
    _ownerNameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onLocationFetched(RegisterOutletLocationFetched state) {
    setState(() {
      _currentLatitude = state.latitude;
      _currentLongitude = state.longitude;
    });
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTerritoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a territory'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_currentLatitude == null || _currentLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fetch your current location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<RegisterOutletCubit>().registerOutlet(
      outletName: _outletNameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      contactNumber: _contactNumberController.text.trim(),
      territoryId: _selectedTerritoryId!,
      latitude: _currentLatitude!,
      longitude: _currentLongitude!,
      ownerEmail: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegisterOutletCubit, RegisterOutletState>(
      listener: (context, state) {
        if (state is RegisterOutletSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        } else if (state is RegisterOutletError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        } else if (state is RegisterOutletLocationFetched) {
          _onLocationFetched(state);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.surfaceWarm,
        appBar: AppBar(title: const Text('Register New Outlet')),
        body: BlocBuilder<RegisterOutletCubit, RegisterOutletState>(
          builder: (context, state) {
            final isLoading = state is RegisterOutletLoading;
            final territories = state is RegisterOutletLocationFetched
                ? state.territories
                : <Territory>[];
            final hasLocation =
                _currentLatitude != null && _currentLongitude != null;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.outlineWarm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: AppTheme.primaryBrown,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Current Location',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppTheme.textDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (hasLocation) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Latitude: ${_currentLatitude?.toStringAsFixed(6)}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.green[700],
                                        fontFamily: 'monospace',
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Longitude: ${_currentLongitude?.toStringAsFixed(6)}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.green[700],
                                        fontFamily: 'monospace',
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () {
                                    context
                                        .read<RegisterOutletCubit>()
                                        .fetchLocationAndTerritories();
                                  },
                            icon: isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.my_location),
                            label: Text(
                              hasLocation
                                  ? 'Update Location'
                                  : 'Get Current Location',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBrown,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Form Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.outlineWarm),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Outlet Details',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppTheme.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 16),
                          // Outlet Name
                          TextFormField(
                            controller: _outletNameController,
                            enabled: !isLoading,
                            decoration: const InputDecoration(
                              labelText: 'Outlet Name',
                              hintText: 'e.g., City Center Store',
                              prefixIcon: Icon(Icons.storefront),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Outlet name is required';
                              }
                              if (value.length < 3) {
                                return 'Outlet name must be at least 3 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Owner Name
                          TextFormField(
                            controller: _ownerNameController,
                            enabled: !isLoading,
                            decoration: const InputDecoration(
                              labelText: 'Owner Name',
                              hintText: 'e.g., John Doe',
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Owner name is required';
                              }
                              if (value.length < 3) {
                                return 'Owner name must be at least 3 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Contact Number
                          TextFormField(
                            controller: _contactNumberController,
                            enabled: !isLoading,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Contact Number',
                              hintText: 'e.g., +94 71 234 5678',
                              prefixIcon: Icon(Icons.phone),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Contact number is required';
                              }
                              // Basic phone validation
                              final phoneRegex = RegExp(
                                r'^[+]?[(]?[0-9]{3}[)]?[-\s.]?[0-9]{3}[-\s.]?[0-9]{4,6}$',
                              );
                              if (!phoneRegex.hasMatch(value)) {
                                return 'Please enter a valid phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Territory Dropdown
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Territory',
                              prefixIcon: Icon(Icons.map),
                              hintText: 'Select a territory',
                            ),
                            items: territories.map((territory) {
                              return DropdownMenuItem(
                                value: territory.id,
                                child: Text(territory.name),
                              );
                            }).toList(),
                            initialValue: _selectedTerritoryId,
                            onChanged: !isLoading
                                ? (value) {
                                    setState(
                                      () => _selectedTerritoryId = value,
                                    );
                                  }
                                : null,
                            validator: (value) =>
                                value == null ? 'Territory is required' : null,
                          ),
                          const SizedBox(height: 16),
                          // Email (Optional)
                          TextFormField(
                            controller: _emailController,
                            enabled: !isLoading,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email (Optional)',
                              hintText: 'owner@example.com',
                              prefixIcon: Icon(Icons.email),
                            ),
                            validator: (value) {
                              if (value != null &&
                                  value.isNotEmpty &&
                                  !RegExp(
                                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                  ).hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Address (Optional)
                          TextFormField(
                            controller: _addressController,
                            enabled: !isLoading,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Address (Optional)',
                              hintText: 'Street address',
                              prefixIcon: Icon(Icons.location_on),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: !hasLocation || isLoading
                                  ? null
                                  : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBrown,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'Register Outlet',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

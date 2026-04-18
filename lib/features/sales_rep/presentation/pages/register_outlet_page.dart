import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/outlet_cubit.dart';

class RegisterOutletPage extends StatefulWidget {
  const RegisterOutletPage({
    super.key,
    this.territoryId = '',
  });

  final String territoryId;

  @override
  State<RegisterOutletPage> createState() => _RegisterOutletPageState();
}

class _RegisterOutletPageState extends State<RegisterOutletPage> {
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  final _outletNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _dio = DioClient.instance.client;

  String? _resolvedTerritoryId;
  bool _isResolvingTerritory = false;

  Map<String, dynamic> _readAuthUser(dynamic payload) {
    if (payload is! Map) {
      return const <String, dynamic>{};
    }

    final root = Map<String, dynamic>.from(payload);
    final nestedUser = root['user'];
    if (nestedUser is Map) {
      return Map<String, dynamic>.from(nestedUser);
    }

    final nestedData = root['data'];
    if (nestedData is Map) {
      return Map<String, dynamic>.from(nestedData);
    }

    return root;
  }

  @override
  void initState() {
    super.initState();
    _resolvedTerritoryId = _normalizeTerritoryId(widget.territoryId);

    if (_resolvedTerritoryId == null) {
      _resolveTerritoryId();
    }
  }

  @override
  void dispose() {
    _outletNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _normalizeTerritoryId(String? value) {
    final territoryId = value?.trim() ?? '';
    if (territoryId.isEmpty || !_uuidPattern.hasMatch(territoryId)) {
      return null;
    }
    return territoryId;
  }

  Future<void> _resolveTerritoryId() async {
    if (_isResolvingTerritory) {
      return;
    }

    setState(() => _isResolvingTerritory = true);

    try {
      final routeResponse = await _dio.get('/sales-routes/my');
      final route = routeResponse.data?['route'];
      final routeTerritoryId = _normalizeTerritoryId(
        route?['territoryId']?.toString(),
      );

      if (!mounted) {
        return;
      }

      if (routeTerritoryId != null) {
        setState(() {
          _resolvedTerritoryId = routeTerritoryId;
          _isResolvingTerritory = false;
        });
        return;
      }

      final meResponse = await _dio.get('/auth/me');
      final userData = _readAuthUser(meResponse.data);
      final userTerritoryId = _normalizeTerritoryId(
        userData['territoryId']?.toString(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _resolvedTerritoryId = userTerritoryId;
        _isResolvingTerritory = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isResolvingTerritory = false);
    }
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

    if (_isResolvingTerritory) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checking your assigned territory. Please wait.'),
        ),
      );
      return;
    }

    final territoryId = _resolvedTerritoryId;
    if (territoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to determine a valid territory for this account. Please refresh and try again.',
          ),
        ),
      );
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
      territoryId: territoryId,
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
              final canSubmit =
                  !isLoading &&
                  !_isResolvingTerritory &&
                  _resolvedTerritoryId != null;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (_isResolvingTerritory || _resolvedTerritoryId == null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _isResolvingTerritory
                              ? AppTheme.kCream
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isResolvingTerritory
                                ? AppTheme.outlineWarm
                                : Colors.orange.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (_isResolvingTerritory)
                              const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _isResolvingTerritory
                                    ? 'Checking your assigned territory before registration.'
                                    : 'A valid territory could not be found for this account. Please refresh and try again.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.kTextDark),
                              ),
                            ),
                            if (!_isResolvingTerritory)
                              TextButton(
                                onPressed: _resolveTerritoryId,
                                child: const Text('Retry'),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
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
                        onPressed: canSubmit ? () => _submitForm(context) : null,
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

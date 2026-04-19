import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/store_check_in_cubit.dart';

class MockShop {
  final String id;
  final String name;

  MockShop({required this.id, required this.name});
}

class StoreCheckInPage extends StatefulWidget {
  final String routeId;

  const StoreCheckInPage({super.key, required this.routeId});

  @override
  State<StoreCheckInPage> createState() => _StoreCheckInPageState();
}

class _StoreCheckInPageState extends State<StoreCheckInPage> {
  final TextEditingController _notesController = TextEditingController();
  String? _selectedShopId;

  final List<MockShop> mockShops = [
    MockShop(
      id: '550e8400-e29b-41d4-a716-446655440001',
      name: 'City Center Store',
    ),
    MockShop(id: '550e8400-e29b-41d4-a716-446655440002', name: 'Mall Outlet'),
    MockShop(id: '550e8400-e29b-41d4-a716-446655440003', name: 'Downtown Shop'),
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _checkInStore() {
    if (_selectedShopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a shop to check in.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<StoreCheckInCubit>().checkInToStore(
      routeId: widget.routeId,
      shopId: _selectedShopId!,
      visitNotes: _notesController.text.isNotEmpty
          ? _notesController.text
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StoreCheckInCubit, StoreCheckInState>(
      listener: (context, state) {
        if (state is StoreCheckInSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          Future.delayed(const Duration(milliseconds: 600), () {
            if (!context.mounted) {
              return;
            }
            Navigator.of(context).pop();
          });
        } else if (state is StoreCheckInError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.surfaceWarm,
        appBar: AppBar(title: const Text('Store Check-In')),
        body: BlocBuilder<StoreCheckInCubit, StoreCheckInState>(
          builder: (context, state) {
            final isLoading = state is StoreCheckInLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        Text(
                          'Select Shop',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Shop',
                            prefixIcon: Icon(Icons.storefront),
                            hintText: 'Choose a shop',
                          ),
                          items: mockShops.map((shop) {
                            return DropdownMenuItem(
                              value: shop.id,
                              child: Text(shop.name),
                            );
                          }).toList(),
                          initialValue: _selectedShopId,
                          onChanged: isLoading
                              ? null
                              : (value) {
                                  setState(() => _selectedShopId = value);
                                },
                          validator: (value) =>
                              value == null ? 'Please select a shop' : null,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Visit Notes (Optional)',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _notesController,
                          maxLines: 5,
                          enabled: !isLoading,
                          decoration: InputDecoration(
                            hintText: 'Add any notes about this visit...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppTheme.outlineWarm,
                              ),
                            ),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Icon(Icons.note_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _checkInStore,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBrown,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Confirm Check-In',
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

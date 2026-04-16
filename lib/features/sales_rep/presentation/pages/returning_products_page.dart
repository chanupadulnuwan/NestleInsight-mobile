import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/services/sales_return_service.dart';
import '../cubit/sales_return_cubit.dart';

class ReturningProductsPage extends StatelessWidget {
  final String routeId;

  const ReturningProductsPage({super.key, required this.routeId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SalesReturnCubit(),
      child: Scaffold(
        backgroundColor: AppTheme.surfaceWarm,
        appBar: AppBar(title: const Text('Returning Products')),
        body: BlocConsumer<SalesReturnCubit, SalesReturnState>(
          listener: (context, state) {
            if (state is SalesReturnSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.proceedOrderOlive,
                ),
              );
              Navigator.of(context).pop();
            } else if (state is SalesReturnError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.promotionMutedRed,
                ),
              );
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                _ReturningProductsForm(routeId: routeId),
                if (state is SalesReturnSubmitting)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReturnRowData {
  final TextEditingController idController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController casesController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  String? reason;

  void dispose() {
    idController.dispose();
    nameController.dispose();
    casesController.dispose();
    notesController.dispose();
  }
}

class _ReturningProductsForm extends StatefulWidget {
  final String routeId;

  const _ReturningProductsForm({required this.routeId});

  @override
  State<_ReturningProductsForm> createState() => _ReturningProductsFormState();
}

class _ReturningProductsFormState extends State<_ReturningProductsForm> {
  final _formKey = GlobalKey<FormState>();
  final List<_ReturnRowData> _rows = [_ReturnRowData()];

  final List<String> _reasons = [
    'DAMAGED',
    'EXPIRED',
    'CUSTOMER_REFUSED',
    'OVERSTOCK',
    'OTHER',
  ];

  @override
  void dispose() {
    for (var row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _rows.add(_ReturnRowData());
    });
  }

  void _removeRow(int index) {
    if (_rows.length > 1) {
      setState(() {
        final removed = _rows.removeAt(index);
        removed.dispose();
      });
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final items = _rows.map((row) {
        return ReturnItemLog(
          productId: row.idController.text.trim(),
          productName: row.nameController.text.trim(),
          quantityCases: int.parse(row.casesController.text.trim()),
          reason: row.reason!,
          notes: row.notesController.text.trim().isEmpty ? null : row.notesController.text.trim(),
        );
      }).toList();

      context.read<SalesReturnCubit>().submitReturn(
            routeId: widget.routeId,
            items: items,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Log any unsold or damaged products being returned from this route.',
            style: TextStyle(color: AppTheme.textSoft, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ..._rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 24),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppTheme.outlineWarm),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Item ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (_rows.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete, color: AppTheme.promotionMutedRed),
                            onPressed: () => _removeRow(index),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: row.idController,
                      decoration: const InputDecoration(labelText: 'Product ID', border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: row.nameController,
                      decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: row.casesController,
                      decoration: const InputDecoration(labelText: 'Cases', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: row.reason,
                      decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder()),
                      items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (val) {
                        setState(() {
                          row.reason = val;
                        });
                      },
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: row.notesController,
                      decoration: const InputDecoration(labelText: 'Notes (Optional)', border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addRow,
            icon: const Icon(Icons.add),
            label: const Text('Add another item'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryBrown,
              side: const BorderSide(color: AppTheme.primaryBrown),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryBrown,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Submit Returns', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/rep_order_cubit.dart';

class PinConfirmationDialog extends StatefulWidget {
  const PinConfirmationDialog({
    super.key,
    required this.orderId,
    required this.shopName,
  });

  final String orderId;
  final String shopName;

  @override
  State<PinConfirmationDialog> createState() => _PinConfirmationDialogState();
}

class _PinConfirmationDialogState extends State<PinConfirmationDialog> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: BlocBuilder<RepOrderCubit, RepOrderState>(
          builder: (context, state) {
            final isSubmitting =
                state is RepOrderLoading && state.orderId == widget.orderId;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Enter Shop Owner PIN',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(
                  widget.shopName.trim().isEmpty
                      ? 'Ask the shop owner to share the PIN from their activity center.'
                      : 'Ask ${widget.shopName} to share the PIN received in the shop owner activity center.',
                  style: const TextStyle(
                    color: AppTheme.textSoft,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  enabled: !isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'PIN',
                    hintText: 'Enter 4 to 6 digits',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reasonController,
                  enabled: !isSubmitting,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Short reason for assisted order',
                    hintText: 'Explain why the sales rep is placing this order.',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isSubmitting
                        ? null
                        : () {
                            context.read<RepOrderCubit>().confirmOrder(
                                  widget.orderId,
                                  _pinController.text,
                                  _reasonController.text,
                                );
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryBrown,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Confirm Order'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

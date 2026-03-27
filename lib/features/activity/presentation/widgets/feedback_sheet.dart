import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/utils/form_validators.dart';
import 'package:mobile/features/auth/presentation/widgets/custom_text_field.dart';

class FeedbackSheet extends StatefulWidget {
  const FeedbackSheet({
    super.key,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final bool isSubmitting;
  final Future<void> Function(String message) onSubmit;

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    await widget.onSubmit(_messageController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          top: 12,
          right: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 56,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.outlineWarm,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Feedback',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Please briefly type your feedback or any complaint.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSoft,
                      ),
                    ),
                    const SizedBox(height: 18),
                    CustomTextField(
                      labelText: 'Feedback message',
                      controller: _messageController,
                      prefixIcon: const Icon(Icons.rate_review_outlined),
                      keyboardType: TextInputType.multiline,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      helperText:
                          'Keep it short and clear so our team can review it quickly.',
                      validator: (value) {
                        final requiredMessage = FormValidators.required(
                          value,
                          fieldName: 'Feedback',
                        );
                        if (requiredMessage != null) {
                          return requiredMessage;
                        }

                        if (value!.trim().length < 5) {
                          return 'Please enter at least 5 characters.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: widget.isSubmitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.securitySlate,
                            ),
                            child: widget.isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.1,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('Submit'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

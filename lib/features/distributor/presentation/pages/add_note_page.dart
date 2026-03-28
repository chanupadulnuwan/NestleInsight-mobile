import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/distributor/data/services/distributor_service.dart';

const _categories = <(String, String, IconData)>[
  ('LATE', 'Running Late', Icons.access_time_outlined),
  ('FUEL', 'Fuel Issue', Icons.local_gas_station_outlined),
  ('TRAFFIC', 'Traffic / Road', Icons.traffic_outlined),
  ('VEHICLE', 'Vehicle Issue', Icons.car_repair_outlined),
  ('OTHER', 'Other', Icons.note_alt_outlined),
];

class AddNotePage extends StatefulWidget {
  const AddNotePage({super.key, this.assignmentId});

  final String? assignmentId;

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final _service = DistributorService();
  final _messageController = TextEditingController();
  String? _selectedCategory;
  bool _submitting = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedCategory == null) {
      setState(() { _error = 'Select a category.'; });
      return;
    }
    if (_messageController.text.trim().length < 5) {
      setState(() { _error = 'Please write at least a short message.'; });
      return;
    }
    setState(() { _submitting = true; _error = null; });
    try {
      await _service.addNote(
        category: _selectedCategory!,
        message: _messageController.text.trim(),
        assignmentId: widget.assignmentId,
      );
      if (mounted) setState(() { _success = true; _submitting = false; });
    } on DistributorServiceException catch (e) {
      if (mounted) setState(() { _error = e.message; _submitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surfaceWarm,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBrownDark,
        foregroundColor: Colors.white,
        title: const Text('Add Note to Manager'),
      ),
      body: _success
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle, color: AppTheme.primaryBrown, size: 72),
                  const SizedBox(height: 16),
                  Text('Note Sent', textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 8),
                  Text('Your territory manager has been notified.', textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryBrown, minimumSize: const Size(180, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text('Done'),
                  ),
                ]),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What\'s happening?', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                  const SizedBox(height: 4),
                  Text('This note will go directly to your territory manager\'s activity center.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
                  ),
                  const SizedBox(height: 24),

                  Text('Category', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.4,
                    children: _categories.map((cat) {
                      final (value, label, icon) = cat;
                      final isSelected = _selectedCategory == value;
                      return GestureDetector(
                        onTap: () => setState(() { _selectedCategory = value; }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryBrown : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryBrown : AppTheme.outlineWarm,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(children: [
                            Icon(icon, size: 20, color: isSelected ? Colors.white : AppTheme.textSoft),
                            const SizedBox(width: 8),
                            Expanded(child: Text(label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : AppTheme.textDark,
                              ),
                            )),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                  Text('Message', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Describe the situation in detail…',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0EF), borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0A7A3)),
                      ),
                      child: Text(_error!, style: const TextStyle(color: Color(0xFF9B4B46), fontSize: 13)),
                    ),
                  ],

                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Icon(Icons.send_outlined),
                    label: const Text('Send Note', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryBrown,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

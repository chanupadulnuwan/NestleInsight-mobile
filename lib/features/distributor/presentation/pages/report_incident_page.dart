import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/distributor/data/services/distributor_service.dart';

const _incidentOlive = Color(0xFF575F3B);
const _incidentBrown = Color(0xFF7C4836);
const _incidentOliveBorder = Color(0xFFD2D5C4);
const _incidentTextSoft = Color(0xFF767D60);

const _incidentTypes = <(String, String, IconData)>[
  ('VEHICLE_ACCIDENT', 'Vehicle Accident', Icons.car_crash_outlined),
  ('VEHICLE_BREAKDOWN', 'Vehicle Breakdown', Icons.build_circle_outlined),
  ('FUEL_PROBLEM', 'Fuel Problem', Icons.local_gas_station_outlined),
  ('ROUTE_ISSUE', 'Route Issue', Icons.route_outlined),
  ('DELIVERY_DELAY', 'Delivery Delay', Icons.schedule_outlined),
  ('CUSTOMER_DISPUTE', 'Customer Dispute', Icons.person_off_outlined),
  ('OTHER', 'Other', Icons.report_problem_outlined),
];

class ReportIncidentPage extends StatefulWidget {
  const ReportIncidentPage({super.key, this.assignmentId});

  final String? assignmentId;

  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage> {
  final _service = DistributorService();
  final _descController = TextEditingController();

  String? _selectedType;
  bool _submitting = false;
  bool _success = false;
  String? _error;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedType == null) {
      setState(() {
        _error = 'Select an incident type.';
      });
      return;
    }
    if (_descController.text.trim().length < 10) {
      setState(() {
        _error = 'Please describe the incident in at least 10 characters.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await _service.reportIncident(
        incidentType: _selectedType!,
        description: _descController.text.trim(),
        assignmentId: widget.assignmentId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _success = true;
        _submitting = false;
      });
    } on DistributorServiceException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 900;

    return Scaffold(
      backgroundColor: AppTheme.surfaceWarm,
      appBar: AppBar(
        backgroundColor: _incidentOlive,
        foregroundColor: Colors.white,
        title: const Text('Report Incident'),
      ),
      body: _success
          ? _SuccessView(onDone: () => Navigator.of(context).pop())
          : SingleChildScrollView(
              padding: EdgeInsets.all(isTablet ? 28 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What happened?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: _incidentOlive,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Report any special incidents that occurred during your delivery trip. Your territory manager will be notified.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _incidentTextSoft,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Incident Type',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _incidentOlive,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: isTablet ? 3 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: isTablet ? 2.9 : 2.4,
                    children: _incidentTypes.map((type) {
                      final (value, label, icon) = type;
                      final isSelected = _selectedType == value;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedType = value;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? _incidentOlive : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? _incidentOlive
                                  : _incidentOliveBorder,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? <BoxShadow>[
                                    BoxShadow(
                                      color: _incidentOlive.withAlpha(30),
                                      blurRadius: 14,
                                      offset: const Offset(0, 8),
                                    ),
                                  ]
                                : const <BoxShadow>[],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                icon,
                                size: 20,
                                color: isSelected ? Colors.white : _incidentOlive,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  label,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color:
                                        isSelected ? Colors.white : _incidentOlive,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Description',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _incidentOlive,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Describe what happened in detail...',
                      hintStyle: const TextStyle(color: _incidentTextSoft),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: _incidentOliveBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: _incidentOlive,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0EF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0A7A3)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFF9B4B46),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Icon(Icons.send_outlined),
                    label: const Text(
                      'Report Incident',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _incidentBrown,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: _incidentOlive, size: 72),
            const SizedBox(height: 16),
            Text(
              'Incident Reported',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: _incidentOlive,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your territory manager has been notified.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _incidentTextSoft,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(
                backgroundColor: _incidentBrown,
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

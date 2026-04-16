import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/incident_cubit.dart';

class ReportIncidentPage extends StatefulWidget {
  const ReportIncidentPage({
    super.key,
    required this.routeId,
    this.territoryId = '00000000-0000-0000-0000-000000000001',
  });

  final String routeId;
  final String territoryId;

  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage> {
  final _descriptionController = TextEditingController();
  String _selectedType = 'VEHICLE_ISSUE';
  String _selectedSeverity = 'MEDIUM';

  final _incidentTypes = [
    'FUEL_ISSUE',
    'VEHICLE_ISSUE',
    'SUSPICIOUS_OUTLET',
    'DELIVERY_ISSUE',
    'STOCK_ISSUE',
    'ROUTE_ISSUE',
    'WAREHOUSE_ISSUE',
    'OTHER',
  ];

  final _severityLevels = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm(BuildContext context) {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    // Mock GPS coordinates
    const mockLatitude = 6.5244;
    const mockLongitude = 3.3792;

    context.read<IncidentCubit>().reportIncident(
      routeId: widget.routeId,
      type: _selectedType,
      description: _descriptionController.text,
      severity: _selectedSeverity,
      latitude: mockLatitude,
      longitude: mockLongitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => IncidentCubit(),
      child: BlocListener<IncidentCubit, IncidentState>(
        listener: (context, state) {
          if (state is IncidentError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is IncidentSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          backgroundColor: AppTheme.surfaceWarm,
          appBar: AppBar(title: const Text('Report Incident')),
          body: BlocBuilder<IncidentCubit, IncidentState>(
            builder: (context, state) {
              final isLoading = state is IncidentLoading;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(label: 'Incident Type'),
                    const SizedBox(height: 12),
                    _DropdownField(
                      value: _selectedType,
                      items: _incidentTypes,
                      onChanged: isLoading
                          ? null
                          // 👇 FIXED: Added the ?? fallback here
                          : (value) => setState(
                              () => _selectedType = value ?? _selectedType,
                            ),
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel(label: 'Severity'),
                    const SizedBox(height: 12),
                    _DropdownField(
                      value: _selectedSeverity,
                      items: _severityLevels,
                      onChanged: isLoading
                          ? null
                          // 👇 FIXED: Added the ?? fallback here
                          : (value) => setState(
                              () => _selectedSeverity =
                                  value ?? _selectedSeverity,
                            ),
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel(label: 'Description'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      enabled: !isLoading,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Describe the incident in detail',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () => _submitForm(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.promotionMutedRed,
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
                                'Submit Incident',
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppTheme.primaryBrown,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String? value;
  final List<String> items;
  final void Function(String?)? onChanged;

  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.outlineWarm),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        onChanged: onChanged,
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
      ),
    );
  }
}

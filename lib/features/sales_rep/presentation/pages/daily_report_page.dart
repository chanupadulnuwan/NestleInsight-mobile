import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/sales_rep/data/services/report_service.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/report_cubit.dart';

class DailyReportPage extends StatefulWidget {
  const DailyReportPage({
    super.key,
    required this.routeId,
    this.territoryId = '00000000-0000-0000-0000-000000000001',
  });

  final String routeId;
  final String territoryId;

  @override
  State<DailyReportPage> createState() => _DailyReportPageState();
}

class _DailyReportPageState extends State<DailyReportPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReportCubit(),
      child: BlocListener<ReportCubit, ReportState>(
        listener: (context, state) {
          if (state is ReportError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is ReportSuccess) {
            // Success is shown in the UI via the state
          }
        },
        child: Scaffold(
          backgroundColor: AppTheme.surfaceWarm,
          appBar: AppBar(title: const Text('End of Day Report')),
          body: BlocBuilder<ReportCubit, ReportState>(
            builder: (context, state) {
              final isLoading = state is ReportLoading;

              if (state is ReportSuccess) {
                return _ReportSuccessView(report: state.report);
              }

              return _ReportInitialView(
                isLoading: isLoading,
                routeId: widget.routeId,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReportInitialView extends StatelessWidget {
  const _ReportInitialView({required this.isLoading, required this.routeId});

  final bool isLoading;
  final String routeId;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.primaryBrown.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_turned_in,
              size: 64,
              color: AppTheme.primaryBrown,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'End of Day Report',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.kTextDark,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Complete your daily report for today. This will summarize all your activities and metrics.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSoft,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () => context.read<ReportCubit>().generateReport(
                      routeId: routeId,
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.securitySlate,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Generate Report',
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
  }
}

class _ReportSuccessView extends StatelessWidget {
  const _ReportSuccessView({required this.report});

  final DailyReport report;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.proceedOrderOlive.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 64,
              color: AppTheme.proceedOrderOlive,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Report Complete!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.kTextDark,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReportInfoRow(
                    label: 'Report ID',
                    value: report.id.substring(0, 8),
                  ),
                  const SizedBox(height: 16),
                  _ReportInfoRow(
                    label: 'Report Date',
                    value: report.reportDate,
                  ),
                  const SizedBox(height: 16),
                  _ReportInfoRow(label: 'Status', value: report.status),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Your daily report has been successfully submitted. Thank you for keeping us updated!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSoft,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBrown,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Done',
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
  }
}

class _ReportInfoRow extends StatelessWidget {
  const _ReportInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSoft,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.kTextDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

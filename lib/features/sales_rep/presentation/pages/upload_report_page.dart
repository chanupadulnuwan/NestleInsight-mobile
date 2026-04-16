import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_theme.dart';
import '../cubit/upload_report_cubit.dart';
import '../../data/services/upload_report_service.dart';

class UploadReportPage extends StatefulWidget {
  final String routeId;

  const UploadReportPage({super.key, required this.routeId});

  @override
  State<UploadReportPage> createState() => _UploadReportPageState();
}

class _UploadReportPageState extends State<UploadReportPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.surfaceWarm,
        appBar: AppBar(
          title: const Text('Uploads / Daily Report'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Generate Report'),
              Tab(text: 'Past Reports'),
            ],
            indicatorColor: AppTheme.primaryBrown,
            labelColor: AppTheme.primaryBrown,
          ),
        ),
        body: BlocConsumer<UploadReportCubit, UploadReportState>(
          listener: (context, state) {
            if (state is UploadReportError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppTheme.promotionMutedRed),
              );
            } else if (state is UploadReportGenerated) {
              // Switch to tab 2 when automatically completed
              DefaultTabController.of(context).animateTo(1);
            }
          },
          builder: (context, state) {
            return TabBarView(
              children: [
                _buildGenerateTab(context, state),
                _buildPastReportsTab(context, state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGenerateTab(BuildContext context, UploadReportState state) {
    if (state is UploadReportGenerated) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: AppTheme.proceedOrderOlive),
              const SizedBox(height: 24),
              const Text(
                'Report Generated Successfully!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('Report ID: ${state.report.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Date: ${state.report.reportDate}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isGenerating = state is UploadReportGenerating;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('End of Day Report', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 12),
          const Text(
            "Submit today's daily report for your current route. This will summarize all visits, orders, and activities logged today.",
            style: TextStyle(fontSize: 16, color: AppTheme.textSoft),
          ),
          const SizedBox(height: 24),
          Card(
            color: AppTheme.securitySlate.withOpacity(0.1),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Route Info', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.securitySlate)),
                  const SizedBox(height: 8),
                  Text('Route ID: ${widget.routeId}', style: const TextStyle(color: AppTheme.textDark)),
                  const SizedBox(height: 4),
                  Text('Date: ${DateTime.now().toIso8601String().split('T')[0]}', style: const TextStyle(color: AppTheme.textDark)),
                ],
              ),
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: isGenerating
                ? null
                : () {
                    context.read<UploadReportCubit>().generateReport(routeId: widget.routeId);
                  },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryBrown,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isGenerating
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Generate & Submit Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPastReportsTab(BuildContext context, UploadReportState state) {
    if (state is UploadReportInitial || state is UploadReportLoading || state is UploadReportGenerating) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 80,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              ),
            ),
          );
        },
      );
    }

    if (state is UploadReportLoaded || state is UploadReportGenerated) {
      List<DailyReportSummary> reports = [];
      if (state is UploadReportLoaded) {
        reports = state.reports;
      }
      // If it's Generated, we don't have the full list locally without looking at previous state, 
      // but Generate reloads it automatically so it bounces to Loaded super fast.
      
      if (reports.isEmpty) {
        return RefreshIndicator(
          onRefresh: () => context.read<UploadReportCubit>().loadMyReports(),
          child: ListView(
            children: const [
              SizedBox(height: 100),
              Center(child: Text('No reports yet', style: TextStyle(fontSize: 18, color: AppTheme.textSoft))),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => context.read<UploadReportCubit>().loadMyReports(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            
            final isSubmitted = report.status == 'SUBMITTED';
            final badgeColor = isSubmitted ? AppTheme.proceedOrderOlive : AppTheme.kOrange;

            String timeStr = '';
            if (report.submittedAt != null) {
              final val = report.submittedAt!.toLocal();
              timeStr = '${val.hour.toString().padLeft(2, '0')}:${val.minute.toString().padLeft(2, '0')}';
            }

            // Formatting date to dd/MM/yyyy assuming reportDate is yyyy-mm-dd
            final parts = report.reportDate.split('-');
            final formattedDate = parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : report.reportDate;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppTheme.outlineWarm),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formattedDate, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                        if (timeStr.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Submitted at $timeStr', style: const TextStyle(color: AppTheme.textSoft, fontSize: 13)),
                        ]
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        report.status,
                        style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

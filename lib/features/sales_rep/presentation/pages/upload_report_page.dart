import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/services/upload_report_service.dart';
import '../cubit/upload_report_cubit.dart';

class UploadReportPage extends StatefulWidget {
  const UploadReportPage({super.key, required this.routeId});

  final String routeId;

  @override
  State<UploadReportPage> createState() => _UploadReportPageState();
}

class _UploadReportPageState extends State<UploadReportPage> {
  final TextEditingController _commentsController = TextEditingController();
  final Set<String> _selectedReportIds = <String>{};
  String? _boundReportId;

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: BlocConsumer<UploadReportCubit, UploadReportState>(
        listener: (context, state) {
          final report = state.selectedReport;
          if (report != null && report.id != _boundReportId) {
            _boundReportId = report.id;
            _commentsController.text = report.repComments ?? '';
          }

          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppTheme.promotionMutedRed,
              ),
            );
            context.read<UploadReportCubit>().clearNotifications();
          } else if (state.successMessage != null) {
            if (state.successMessage!.contains('uploaded successfully')) {
              setState(() => _selectedReportIds.clear());
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppTheme.proceedOrderOlive,
              ),
            );
            context.read<UploadReportCubit>().clearNotifications();
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppTheme.surfaceWarm,
            appBar: AppBar(
              title: const Text('Daily Report'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Draft Review'),
                  Tab(text: 'Past Reports'),
                ],
                indicatorColor: AppTheme.primaryBrown,
                labelColor: AppTheme.primaryBrown,
              ),
            ),
            body: TabBarView(
              children: [
                _buildDraftTab(context, state),
                _buildPastReportsTab(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDraftTab(BuildContext context, UploadReportState state) {
    final report = state.selectedReport;
    final hasRouteId = widget.routeId.trim().isNotEmpty;

    if (state.isLoadingReports && report == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (report == null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _InfoBanner(
              title: 'Generate a daily report draft',
              message:
                  'We will collect route, visit, OSA, assisted-order, return, and incident data into a draft that the sales rep can review before final submission.',
              icon: Icons.assignment_outlined,
              accentColor: AppTheme.securitySlate,
            ),
            const SizedBox(height: 20),
            _InfoCard(
              title: 'Route context',
              lines: [
                'Route ID: ${hasRouteId ? widget.routeId : 'Not available'}',
                'Status: close the route first if the server says the report is not ready yet.',
              ],
            ),
            const Spacer(),
            FilledButton(
              onPressed: !hasRouteId || state.isGenerating
                  ? null
                  : () {
                      context.read<UploadReportCubit>().generateReport(
                        routeId: widget.routeId,
                      );
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryBrown,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: state.isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    )
                  : Text(
                      hasRouteId
                          ? 'Generate Draft Report'
                          : 'No route available yet',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    final isSubmitted = report.isSubmitted;
    final canEditComments = !state.isSavingDraft;

    return RefreshIndicator(
      onRefresh: () => context.read<UploadReportCubit>().loadMyReports(
        focusReportId: report.id,
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoBanner(
            title: isSubmitted
                ? 'Submitted report ready to update'
                : 'Draft ready for review',
            message: isSubmitted
                ? 'You can add new notes to this past report and resubmit it after making changes.'
                : 'Review the collected sections below, add comments if needed, then submit the final report.',
            icon:
                isSubmitted ? Icons.history_toggle_off : Icons.fact_check_outlined,
            accentColor:
                isSubmitted ? AppTheme.proceedOrderOlive : AppTheme.securitySlate,
          ),
          const SizedBox(height: 16),
          _HeaderCard(report: report),
          const SizedBox(height: 12),
          _SummaryCard(title: 'Route Summary', data: report.routeSummary),
          _SummaryCard(title: 'Visit Summary', data: report.visitSummary),
          _SummaryCard(
            title: 'OSA & Feedback Summary',
            data: report.osaSummary,
          ),
          _SummaryCard(
            title: 'Orders / Delivery Summary',
            data: report.deliverySummary,
          ),
          _SummaryCard(title: 'Return Summary', data: report.returnSummary),
          _SummaryCard(title: 'Incident Summary', data: report.incidentSummary),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sales Rep Comments',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentsController,
                    enabled: canEditComments,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: isSubmitted
                          ? 'Add updated notes before resubmitting...'
                          : 'Add any final notes before submission...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: state.isSavingDraft
                ? null
                : () {
                    context.read<UploadReportCubit>().saveDraftComments(
                      _commentsController.text.trim(),
                    );
                  },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppTheme.primaryBrown),
            ),
            child: state.isSavingDraft
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : Text(isSubmitted ? 'Update Notes' : 'Save Draft Comments'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: state.isSubmitting
                ? null
                : () {
                    context.read<UploadReportCubit>().submitSelectedReport();
                  },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.proceedOrderOlive,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: state.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.2,
                    ),
                  )
                : Text(
                    isSubmitted ? 'Resubmit Report' : 'Submit Final Report',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          if (widget.routeId.trim().isNotEmpty)
            TextButton.icon(
              onPressed: state.isGenerating
                  ? null
                  : () {
                      context.read<UploadReportCubit>().generateReport(
                        routeId: widget.routeId,
                      );
                    },
              icon: const Icon(Icons.refresh),
              label: const Text('Regenerate From Latest Route Data'),
            ),
        ],
      ),
    );
  }

  Widget _buildPastReportsTab(BuildContext context, UploadReportState state) {
    if (state.isLoadingReports && state.reports.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.reports.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<UploadReportCubit>().loadMyReports(),
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text(
                'No reports yet',
                style: TextStyle(fontSize: 18, color: AppTheme.textSoft),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<UploadReportCubit>().loadMyReports(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.reports.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final selectedDraftCount = state.reports
                .where((report) => _selectedReportIds.contains(report.id))
                .length;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BulkUploadPanel(
                selectedCount: selectedDraftCount,
                isSubmitting: state.isSubmitting,
                onUpload: selectedDraftCount == 0 || state.isSubmitting
                    ? null
                    : () {
                        context.read<UploadReportCubit>().submitReports(
                          _selectedReportIds,
                        );
                      },
              ),
            );
          }

          final reportIndex = index - 1;
          final report = state.reports[reportIndex];
          final isSelected = state.selectedReport?.id == report.id;
          final isChecked = _selectedReportIds.contains(report.id);
          final canSelectForUpload = report.isDraft || report.isSubmitted;
          final badgeColor = report.isSubmitted
              ? AppTheme.proceedOrderOlive
              : AppTheme.kOrange;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isSelected
                    ? AppTheme.primaryBrown
                    : AppTheme.outlineWarm,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                DefaultTabController.of(context).animateTo(0);
                context.read<UploadReportCubit>().openReport(report.id);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Checkbox(
                      value: isChecked,
                      onChanged: canSelectForUpload
                          ? (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedReportIds.add(report.id);
                                } else {
                                  _selectedReportIds.remove(report.id);
                                }
                              });
                            }
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDisplayDate(report.reportDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            report.submittedAt == null
                                ? 'Draft report'
                                : 'Submitted at ${_formatDateTime(report.submittedAt)}',
                            style: const TextStyle(
                              color: AppTheme.textSoft,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        report.status,
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.title,
    required this.message,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(color: AppTheme.textSoft, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  line,
                  style: const TextStyle(color: AppTheme.textSoft),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulkUploadPanel extends StatelessWidget {
  const _BulkUploadPanel({
    required this.selectedCount,
    required this.isSubmitting,
    required this.onUpload,
  });

  final int selectedCount;
  final bool isSubmitting;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.proceedOrderOlive.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                color: AppTheme.proceedOrderOlive,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedCount == 0
                    ? 'Select reports to submit or resubmit'
                    : '$selectedCount report${selectedCount == 1 ? '' : 's'} selected',
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            FilledButton(
              onPressed: onUpload,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.proceedOrderOlive,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.report});

  final DailyReportDetail report;

  @override
  Widget build(BuildContext context) {
    final badgeColor = report.isSubmitted
        ? AppTheme.proceedOrderOlive
        : AppTheme.kOrange;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Report Header',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    report.status,
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Report date: ${_formatDisplayDate(report.reportDate)}'),
            if (report.submittedAt != null) ...[
              const SizedBox(height: 6),
              Text('Submitted at: ${_formatDateTime(report.submittedAt)}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.data});

  final String title;
  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    if (data == null || data!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _SummaryContent(title: title, data: data!),
          ],
        ),
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({required this.title, required this.data});

  final String title;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final normalizedTitle = title.toLowerCase();
    if (normalizedTitle.contains('route')) {
      return _RouteSummaryBody(data: data);
    }
    if (normalizedTitle.contains('visit')) {
      return _VisitSummaryBody(data: data);
    }
    if (normalizedTitle.contains('osa')) {
      return _OsaSummaryBody(data: data);
    }
    if (normalizedTitle.contains('order') ||
        normalizedTitle.contains('delivery')) {
      return _DeliverySummaryBody(data: data);
    }
    if (normalizedTitle.contains('return')) {
      return _ReturnSummaryBody(data: data);
    }
    if (normalizedTitle.contains('incident')) {
      return _IncidentSummaryBody(data: data);
    }
    return _FallbackSummaryBody(data: data);
  }
}

class _RouteSummaryBody extends StatelessWidget {
  const _RouteSummaryBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final startedAt = _readDateTime(data, const ['startedAt']);
    final closedAt = _readDateTime(data, const ['closedAt']);
    final fieldDurationMinutes =
        _readInt(data, const ['fieldDurationMinutes']) ??
        _deriveDurationMinutes(startedAt, closedAt);

    final metrics = <_SummaryMetricData>[
      if (_readString(data, const ['status']) != null)
        _SummaryMetricData(
          label: 'Status',
          value: _formatStatus(_readString(data, const ['status'])!),
          accentColor: AppTheme.proceedOrderOlive,
        ),
      if (fieldDurationMinutes != null)
        _SummaryMetricData(
          label: 'Field Time',
          value: '$fieldDurationMinutes min',
        ),
      if (_readInt(data, const [
            'openingStockLines',
            'openingStockLineCount',
          ]) !=
          null)
        _SummaryMetricData(
          label: 'Opening Lines',
          value:
              '${_readInt(data, const ['openingStockLines', 'openingStockLineCount'])}',
        ),
      if (_readInt(data, const ['openingStockCases']) != null)
        _SummaryMetricData(
          label: 'Opening Cases',
          value: '${_readInt(data, const ['openingStockCases'])}',
        ),
      if (_readInt(data, const [
            'closingStockLines',
            'closingStockLineCount',
          ]) !=
          null)
        _SummaryMetricData(
          label: 'Closing Lines',
          value:
              '${_readInt(data, const ['closingStockLines', 'closingStockLineCount'])}',
        ),
      if (_readInt(data, const ['closingStockCases']) != null)
        _SummaryMetricData(
          label: 'Closing Cases',
          value: '${_readInt(data, const ['closingStockCases'])}',
        ),
      if (_readInt(data, const ['returnLineCount']) != null)
        _SummaryMetricData(
          label: 'Return Lines',
          value: '${_readInt(data, const ['returnLineCount'])}',
        ),
      if (_readInt(data, const ['totalReturnedCases']) != null)
        _SummaryMetricData(
          label: 'Returned Cases',
          value: '${_readInt(data, const ['totalReturnedCases'])}',
        ),
      if (_readInt(data, const ['varianceLineCount']) != null)
        _SummaryMetricData(
          label: 'Variance Lines',
          value: '${_readInt(data, const ['varianceLineCount'])}',
          accentColor: _readBool(data, const ['hasVariance']) == true
              ? AppTheme.promotionMutedRed
              : null,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricWrap(metrics: metrics),
        if (startedAt != null || closedAt != null) ...[
          const SizedBox(height: 14),
          _DetailGroup(
            title: 'Timeline',
            rows: [
              if (startedAt != null)
                _DetailRowData(
                  title: 'Started',
                  subtitle: _formatDateTime(startedAt),
                ),
              if (closedAt != null)
                _DetailRowData(
                  title: 'Closed',
                  subtitle: _formatDateTime(closedAt),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _VisitSummaryBody extends StatelessWidget {
  const _VisitSummaryBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final outlets = _readMapList(data['outlets'] ?? data['visitedShops']);
    final totalDurationMinutes = _readInt(data, const [
      'totalDurationMinutes',
      'totalVisitDurationMinutes',
    ]);

    final metrics = <_SummaryMetricData>[
      if (_readInt(data, const ['totalVisits']) != null)
        _SummaryMetricData(
          label: 'Total Visits',
          value: '${_readInt(data, const ['totalVisits'])}',
        ),
      if (_readInt(data, const ['completedVisits']) != null)
        _SummaryMetricData(
          label: 'Completed',
          value: '${_readInt(data, const ['completedVisits'])}',
          accentColor: AppTheme.proceedOrderOlive,
        ),
      if (_readInt(data, const ['inProgressVisits']) != null)
        _SummaryMetricData(
          label: 'In Progress',
          value: '${_readInt(data, const ['inProgressVisits'])}',
        ),
      if (totalDurationMinutes != null)
        _SummaryMetricData(
          label: 'Visit Time',
          value: '$totalDurationMinutes min',
        ),
      if (_readInt(data, const ['photoCount']) != null)
        _SummaryMetricData(
          label: 'Photos',
          value: '${_readInt(data, const ['photoCount'])}',
        ),
      if (_readInt(data, const ['feedbackCount']) != null)
        _SummaryMetricData(
          label: 'Feedback Items',
          value: '${_readInt(data, const ['feedbackCount'])}',
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricWrap(metrics: metrics),
        if (outlets.isNotEmpty) ...[
          const SizedBox(height: 14),
          _DetailGroup(
            title: 'Visited Outlets',
            rows: outlets.map((outlet) {
              final durationSeconds = _readInt(outlet, const [
                'durationSeconds',
              ]);
              final startedAt = _readDateTime(outlet, const ['startedAt']);
              final endedAt = _readDateTime(outlet, const ['endedAt']);
              final detailParts = <String>[
                if (startedAt != null) 'Started ${_formatDateTime(startedAt)}',
                if (endedAt != null) 'Ended ${_formatDateTime(endedAt)}',
                if (durationSeconds != null)
                  _formatSecondsDuration(durationSeconds),
              ];

              return _DetailRowData(
                title:
                    _readString(outlet, const ['outletName', 'shopName']) ??
                    'Visited outlet',
                subtitle: detailParts.join('  |  '),
                badge: _formatStatus(
                  _readString(outlet, const ['status']) ?? 'UNKNOWN',
                ),
                badgeColor:
                    (_readString(outlet, const ['status']) ?? '')
                            .toUpperCase() ==
                        'COMPLETED'
                    ? AppTheme.proceedOrderOlive
                    : AppTheme.securitySlate,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _OsaSummaryBody extends StatelessWidget {
  const _OsaSummaryBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final issues = _readMapList(data['issues']);
    final feedbackSamples = _readMapList(data['feedbackSamples']);

    final metrics = <_SummaryMetricData>[
      if (_readInt(data, const ['planogramOkCount', 'visitsWithPlanogramOk']) !=
          null)
        _SummaryMetricData(
          label: 'Planogram OK',
          value:
              '${_readInt(data, const ['planogramOkCount', 'visitsWithPlanogramOk'])}',
          accentColor: AppTheme.proceedOrderOlive,
        ),
      if (_readInt(data, const ['posmOkCount', 'visitsWithPosmOk']) != null)
        _SummaryMetricData(
          label: 'POSM OK',
          value: '${_readInt(data, const ['posmOkCount', 'visitsWithPosmOk'])}',
          accentColor: AppTheme.proceedOrderOlive,
        ),
      if (_readInt(data, const [
            'outletCountWithIssues',
            'visitsWithOsaNotes',
          ]) !=
          null)
        _SummaryMetricData(
          label: 'Outlets With Issues',
          value:
              '${_readInt(data, const ['outletCountWithIssues', 'visitsWithOsaNotes'])}',
          accentColor: AppTheme.promotionMutedRed,
        ),
      if (_readInt(data, const ['issueCount', 'totalOsaIssueEntries']) != null)
        _SummaryMetricData(
          label: 'Issue Notes',
          value:
              '${_readInt(data, const ['issueCount', 'totalOsaIssueEntries'])}',
          accentColor: AppTheme.promotionMutedRed,
        ),
      if (_readInt(data, const ['feedbackCount', 'visitsWithFeedback']) != null)
        _SummaryMetricData(
          label: 'Feedback Notes',
          value:
              '${_readInt(data, const ['feedbackCount', 'visitsWithFeedback'])}',
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricWrap(metrics: metrics),
        if (issues.isNotEmpty) ...[
          const SizedBox(height: 14),
          _DetailGroup(
            title: 'OSA Issues',
            rows: issues.map((issue) {
              return _DetailRowData(
                title:
                    _readString(issue, const ['outletName', 'shopName']) ??
                    'Outlet issue',
                subtitle:
                    _readString(issue, const ['note', 'feedback']) ??
                    'Issue recorded',
              );
            }).toList(),
          ),
        ],
        if (feedbackSamples.isNotEmpty) ...[
          const SizedBox(height: 14),
          _DetailGroup(
            title: 'Outlet Feedback',
            rows: feedbackSamples.map((entry) {
              return _DetailRowData(
                title:
                    _readString(entry, const ['outletName', 'shopName']) ??
                    'Outlet feedback',
                subtitle:
                    _readString(entry, const ['feedback', 'note']) ??
                    'Feedback recorded',
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _DeliverySummaryBody extends StatelessWidget {
  const _DeliverySummaryBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final orders = _readMapList(data['orders']);
    final metrics = <_SummaryMetricData>[
      if (_readInt(data, const ['totalRequests', 'assistedOrderCount']) != null)
        _SummaryMetricData(
          label: 'Order Requests',
          value:
              '${_readInt(data, const ['totalRequests', 'assistedOrderCount'])}',
        ),
      if (_readInt(data, const ['confirmedOrders']) != null)
        _SummaryMetricData(
          label: 'Confirmed',
          value: '${_readInt(data, const ['confirmedOrders'])}',
          accentColor: AppTheme.proceedOrderOlive,
        ),
      if (_readInt(data, const ['draftOrders']) != null)
        _SummaryMetricData(
          label: 'Draft',
          value: '${_readInt(data, const ['draftOrders'])}',
        ),
      if (_readInt(data, const ['pendingPinOrders']) != null)
        _SummaryMetricData(
          label: 'Pending PIN',
          value: '${_readInt(data, const ['pendingPinOrders'])}',
        ),
      if (_readInt(data, const ['expiredOrders']) != null)
        _SummaryMetricData(
          label: 'Expired',
          value: '${_readInt(data, const ['expiredOrders'])}',
          accentColor: AppTheme.promotionMutedRed,
        ),
      if (_readDouble(data, const ['totalValue', 'totalOrderValue']) != null)
        _SummaryMetricData(
          label: 'Total Value',
          value:
              'Rs. ${_formatCurrency(_readDouble(data, const ['totalValue', 'totalOrderValue'])!)}',
          accentColor: AppTheme.primaryBrown,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricWrap(metrics: metrics),
        const SizedBox(height: 14),
        if (orders.isEmpty)
          const _EmptySummaryState(
            message: 'No assisted orders were recorded for this route.',
          )
        else
          _DetailGroup(
            title: 'Orders',
            rows: orders.map((order) {
              final placedAt = _readDateTime(order, const ['placedAt']);
              final totalAmount = _readDouble(order, const ['totalAmount']);
              final subtitleParts = <String>[
                if (totalAmount != null) 'Rs. ${_formatCurrency(totalAmount)}',
                if (placedAt != null) _formatDateTime(placedAt),
              ];

              return _DetailRowData(
                title:
                    _readString(order, const ['orderCode']) ?? 'Assisted order',
                subtitle: subtitleParts.join('  |  '),
                badge: _formatStatus(
                  _readString(order, const ['status']) ?? 'UNKNOWN',
                ),
                badgeColor: _statusAccent(
                  _readString(order, const ['status']) ?? '',
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _ReturnSummaryBody extends StatelessWidget {
  const _ReturnSummaryBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final items = _readMapList(data['items']);
    final metrics = <_SummaryMetricData>[
      if (_readInt(data, const ['returnLineCount']) != null)
        _SummaryMetricData(
          label: 'Return Lines',
          value: '${_readInt(data, const ['returnLineCount'])}',
        ),
      if (_readInt(data, const ['totalReturnedCases']) != null)
        _SummaryMetricData(
          label: 'Returned Cases',
          value: '${_readInt(data, const ['totalReturnedCases'])}',
          accentColor: AppTheme.primaryBrown,
        ),
      if (_readInt(data, const [
            'totalReturnedUnits',
            'totalReturnedProducts',
          ]) !=
          null)
        _SummaryMetricData(
          label: 'Returned Products',
          value:
              '${_readInt(data, const ['totalReturnedUnits', 'totalReturnedProducts'])}',
          accentColor: AppTheme.primaryBrown,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricWrap(metrics: metrics),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 14),
          _DetailGroup(
            title: 'Returned Items',
            rows: items.map((item) {
              final notes = _readString(item, const ['notes']);
              final quantityParts = <String>[
                if ((_readInt(item, const ['quantityCases']) ?? 0) > 0)
                  '${_readInt(item, const ['quantityCases'])} case(s)',
                if ((_readInt(item, const ['quantityUnits']) ?? 0) > 0)
                  '${_readInt(item, const ['quantityUnits'])} product(s)',
              ];
              return _DetailRowData(
                title:
                    _readString(item, const [
                      'productName',
                      'productNameSnapshot',
                    ]) ??
                    'Returned item',
                subtitle: [
                  if (_readString(item, const ['reason']) != null)
                    _formatStatus(_readString(item, const ['reason'])!),
                  if (notes != null && notes.isNotEmpty) notes,
                ].join('  |  '),
                badge: quantityParts.isEmpty
                    ? 'Returned'
                    : quantityParts.join(' + '),
                badgeColor: AppTheme.primaryBrown,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _IncidentSummaryBody extends StatelessWidget {
  const _IncidentSummaryBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final incidents = _readMapList(data['incidents']);
    final severityMap = data['incidentsBySeverity'] is Map
        ? Map<String, dynamic>.from(data['incidentsBySeverity'] as Map)
        : const <String, dynamic>{};

    final metrics = <_SummaryMetricData>[
      if (_readInt(data, const ['incidentCount']) != null)
        _SummaryMetricData(
          label: 'Incidents',
          value: '${_readInt(data, const ['incidentCount'])}',
        ),
      if (_readInt(severityMap, const ['LOW']) != null)
        _SummaryMetricData(
          label: 'Low',
          value: '${_readInt(severityMap, const ['LOW'])}',
        ),
      if (_readInt(severityMap, const ['MEDIUM']) != null)
        _SummaryMetricData(
          label: 'Medium',
          value: '${_readInt(severityMap, const ['MEDIUM'])}',
          accentColor: AppTheme.kOrange,
        ),
      if (_readInt(severityMap, const ['HIGH']) != null)
        _SummaryMetricData(
          label: 'High',
          value: '${_readInt(severityMap, const ['HIGH'])}',
          accentColor: AppTheme.promotionMutedRed,
        ),
      if (_readInt(severityMap, const ['CRITICAL']) != null)
        _SummaryMetricData(
          label: 'Critical',
          value: '${_readInt(severityMap, const ['CRITICAL'])}',
          accentColor: AppTheme.promotionMutedRed,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricWrap(metrics: metrics),
        if (incidents.isNotEmpty) ...[
          const SizedBox(height: 14),
          _DetailGroup(
            title: 'Incident Log',
            rows: incidents.map((incident) {
              final createdAt = _readDateTime(incident, const ['createdAt']);
              return _DetailRowData(
                title: _readString(incident, const ['type']) ?? 'Incident',
                subtitle: [
                  if (_readString(incident, const ['description']) != null)
                    _readString(incident, const ['description'])!,
                  if (createdAt != null) _formatDateTime(createdAt),
                ].join('  |  '),
                badge: _formatStatus(
                  _readString(incident, const ['severity']) ?? 'UNKNOWN',
                ),
                badgeColor: _severityAccent(
                  _readString(incident, const ['severity']) ?? '',
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _FallbackSummaryBody extends StatelessWidget {
  const _FallbackSummaryBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final rows = data.entries
        .where((entry) => entry.value is! List && entry.value is! Map)
        .map(
          (entry) => _DetailRowData(
            title: _formatFieldLabel(entry.key),
            subtitle: _formatAnyValue(entry.value),
          ),
        )
        .toList();

    if (rows.isEmpty) {
      return const _EmptySummaryState(
        message: 'No summary details are available for this section yet.',
      );
    }

    return _DetailGroup(title: 'Summary Details', rows: rows);
  }
}

class _MetricWrap extends StatelessWidget {
  const _MetricWrap({required this.metrics});

  final List<_SummaryMetricData> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return const _EmptySummaryState(
        message: 'No summary metrics are available yet.',
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: metrics.map((metric) {
        final accentColor = metric.accentColor ?? AppTheme.primaryBrownDark;
        return Container(
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 170),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWarm,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.outlineWarm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                metric.value,
                style: TextStyle(
                  fontSize: 18,
                  color: accentColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DetailGroup extends StatelessWidget {
  const _DetailGroup({required this.title, required this.rows});

  final String title;
  final List<_DetailRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 10),
        ...rows.map(
          (row) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWarm,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.outlineWarm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.title,
                        style: const TextStyle(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (row.subtitle != null &&
                          row.subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          row.subtitle!,
                          style: const TextStyle(
                            color: AppTheme.textSoft,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (row.badge != null && row.badge!.trim().isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (row.badgeColor ?? AppTheme.securitySlate)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      row.badge!,
                      style: TextStyle(
                        color: row.badgeColor ?? AppTheme.securitySlate,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptySummaryState extends StatelessWidget {
  const _EmptySummaryState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarm,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outlineWarm),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppTheme.textSoft,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SummaryMetricData {
  const _SummaryMetricData({
    required this.label,
    required this.value,
    this.accentColor,
  });

  final String label;
  final String value;
  final Color? accentColor;
}

class _DetailRowData {
  const _DetailRowData({
    required this.title,
    this.subtitle,
    this.badge,
    this.badgeColor,
  });

  final String title;
  final String? subtitle;
  final String? badge;
  final Color? badgeColor;
}

String _formatDisplayDate(String reportDate) {
  final parts = reportDate.split('-');
  if (parts.length != 3) {
    return reportDate;
  }
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return 'Not available';
  }

  final local = value.toLocal();
  final date = _formatDisplayDate(local.toIso8601String().split('T').first);
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$date $hour:$minute';
}

String _formatStatus(String value) {
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0]}${part.substring(1).toLowerCase()}')
      .join(' ');
}

String _formatCurrency(double value) {
  return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
}

String _formatSecondsDuration(int seconds) {
  if (seconds < 60) {
    return '$seconds sec';
  }
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  if (remainingSeconds == 0) {
    return '$minutes min';
  }
  return '$minutes min $remainingSeconds sec';
}

int? _deriveDurationMinutes(DateTime? startedAt, DateTime? closedAt) {
  if (startedAt == null || closedAt == null) {
    return null;
  }
  return closedAt.difference(startedAt).inMinutes;
}

List<Map<String, dynamic>> _readMapList(dynamic value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }

  return value
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(entry))
      .toList();
}

String? _readString(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value == null) {
      continue;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty && text != 'null') {
      return text;
    }
  }
  return null;
}

int? _readInt(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}

double? _readDouble(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}

bool? _readBool(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is bool) {
      return value;
    }
    if (value is String) {
      if (value.toLowerCase() == 'true') {
        return true;
      }
      if (value.toLowerCase() == 'false') {
        return false;
      }
    }
  }
  return null;
}

DateTime? _readDateTime(Map<String, dynamic> data, List<String> keys) {
  final value = _readString(data, keys);
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value);
}

String _formatFieldLabel(String key) {
  final normalized = key.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  return normalized
      .split('_')
      .expand((part) => part.split(' '))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _formatAnyValue(dynamic value) {
  if (value == null) {
    return 'Not available';
  }
  if (value is bool) {
    return value ? 'Yes' : 'No';
  }
  return value.toString();
}

Color _statusAccent(String status) {
  switch (status.toUpperCase()) {
    case 'CONFIRMED':
    case 'COMPLETED':
    case 'APPROVED':
    case 'SUBMITTED':
      return AppTheme.proceedOrderOlive;
    case 'DRAFT':
    case 'PENDING':
    case 'PENDING_PIN':
      return AppTheme.kOrange;
    case 'EXPIRED':
    case 'REJECTED':
      return AppTheme.promotionMutedRed;
    default:
      return AppTheme.securitySlate;
  }
}

Color _severityAccent(String severity) {
  switch (severity.toUpperCase()) {
    case 'LOW':
      return AppTheme.securitySlate;
    case 'MEDIUM':
      return AppTheme.kOrange;
    case 'HIGH':
    case 'CRITICAL':
      return AppTheme.promotionMutedRed;
    default:
      return AppTheme.securitySlate;
  }
}

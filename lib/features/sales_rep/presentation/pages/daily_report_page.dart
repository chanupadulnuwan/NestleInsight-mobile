import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/upload_report_cubit.dart';
import 'upload_report_page.dart';

class DailyReportPage extends StatelessWidget {
  const DailyReportPage({
    super.key,
    required this.routeId,
    this.territoryId = '',
  });

  final String routeId;
  final String territoryId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UploadReportCubit()..loadMyReports(),
      child: UploadReportPage(routeId: routeId),
    );
  }
}

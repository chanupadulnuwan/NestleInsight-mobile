import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/home/presentation/widgets/activity_card.dart';
import '../controllers/sales_rep_activity_cubit.dart';

class SalesRepActivityTab extends StatefulWidget {
  const SalesRepActivityTab({super.key});

  @override
  State<SalesRepActivityTab> createState() => _SalesRepActivityTabState();
}

class _SalesRepActivityTabState extends State<SalesRepActivityTab> {
  @override
  void initState() {
    super.initState();
    context.read<SalesRepActivityCubit>().fetchActivities();
    context.read<SalesRepActivityCubit>().startPolling();
  }

  @override
  void dispose() {
    // Note: Cubit is provided at a higher level, but we can stop polling here
    // if we want it to only poll while the tab is active.
    // However, if it's in a PageView/IndexedStack, dispose might not be called immediately.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesRepActivityCubit, SalesRepActivityState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => context
              .read<SalesRepActivityCubit>()
              .fetchActivities(isManualRefresh: true),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Activity Feed',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Stay updated on your outlet registration status and other real-time notifications.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
              ),
              const SizedBox(height: 24),
              if (state is SalesRepActivityLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (state is SalesRepActivityError)
                _MessageCard(
                  title: 'Unable to load activity',
                  message: state.message,
                )
              else if (state is SalesRepActivityLoaded)
                if (state.activities.isEmpty)
                  const _MessageCard(
                    title: 'No activity yet',
                    message:
                        'Once your registered outlets are reviewed or other events occur, they will appear here.',
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.activities.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final activity = state.activities[index];
                      return ActivityCard(activity: activity);
                    },
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarm,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineWarm.withAlpha(110)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSoft),
          ),
        ],
      ),
    );
  }
}

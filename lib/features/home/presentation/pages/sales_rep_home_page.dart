import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:mobile/features/auth/presentation/pages/login_page.dart';
import 'package:mobile/features/sales_rep/presentation/pages/start_route_page.dart';
import 'package:mobile/features/sales_rep/presentation/pages/register_outlet_page.dart';
import 'package:mobile/features/sales_rep/presentation/pages/store_visit_page.dart';
import 'package:mobile/features/sales_rep/presentation/pages/report_incident_page.dart';
import 'package:mobile/features/sales_rep/presentation/pages/daily_report_page.dart';

import '../../../../core/theme/app_theme.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

class SalesRepHomePage extends StatelessWidget {
  const SalesRepHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the Cubit and load data immediately
    return BlocProvider(
      create: (context) => HomeCubit()..loadHomeData(),
      child: Scaffold(
        backgroundColor: AppTheme.kCream,
        body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeInitial || state is HomeLoading) {
              return _buildShimmerLoading();
            } else if (state is HomeLoaded) {
              return _buildLoadedState(context, state);
            } else if (state is HomeError) {
              return Center(
                child: Text(
                  state.message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppTheme.kTextDark),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 240,
            child: Stack(
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 20,
                  right: 20,
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, HomeLoaded state) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildHeroSection(context, state),
          const SizedBox(height: 10),
          _buildDashboardList(context, state),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, HomeLoaded state) {
    return SizedBox(
      height: 240,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Banner Background
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.kBrown, AppTheme.kTextDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.kTextDark.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.kCream.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hello ${state.firstName}!',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => _handleLogout(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Territory Card Overlapping
          Positioned(
            bottom: 0,
            left: 20,
            right: 20,
            child: _buildTerritoryCard(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildTerritoryCard(BuildContext context, HomeLoaded state) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kTextDark.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Current Territory',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.kBrown,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.territoryName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.kTextDark,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.kCream,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${state.shopsLeft}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.kTextDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'Shops',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.kBrown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardList(BuildContext context, HomeLoaded state) {
    final bool hasRoute = state.hasActiveRoute;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Your Dashboard',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.kTextDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _buildActionCard(
            context: context,
            title: 'Start Route',
            icon: Icons.wb_sunny,
            color: AppTheme.kOrange,
            isLocked: false,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const StartRoutePage()),
              );
            },
          ),
          _buildActionCard(
            context: context,
            title: 'Register New Outlet',
            icon: Icons.add_business,
            color: AppTheme.kOrange,
            isLocked: false,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const RegisterOutletPage(),
                ),
              );
            },
          ),
          _buildActionCard(
            context: context,
            title: 'Log Store Visit',
            icon: Icons.storefront,
            color: AppTheme.kOrange,
            isLocked: !hasRoute,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const StoreVisitPage(
                    routeId: '00000000-0000-0000-0000-000000000001',
                    territoryId: '00000000-0000-0000-0000-000000000001',
                  ),
                ),
              );
            },
          ),
          _buildActionCard(
            context: context,
            title: 'Report Incident',
            icon: Icons.warning_amber,
            color: AppTheme.promotionMutedRed,
            isLocked: !hasRoute,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ReportIncidentPage(
                    routeId: '00000000-0000-0000-0000-000000000001',
                    territoryId: '00000000-0000-0000-0000-000000000001',
                  ),
                ),
              );
            },
          ),
          _buildActionCard(
            context: context,
            title: 'End of Day Report',
            icon: Icons.assignment_turned_in,
            color: AppTheme.securitySlate,
            isLocked: !hasRoute,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DailyReportPage(
                    routeId: '00000000-0000-0000-0000-000000000001',
                    territoryId: '00000000-0000-0000-0000-000000000001',
                  ),
                ),
              );
            },
          ),
          _buildActionCard(
            context: context,
            title: 'Smart Route',
            icon: Icons.map,
            color: AppTheme.kBrown,
            isLocked: false,
          ),
          _buildActionCard(
            context: context,
            title: 'Outlet Visit',
            icon: Icons.store,
            color: AppTheme.kBrown,
            isLocked: !hasRoute, // Locked if no route is active
          ),
          _buildActionCard(
            context: context,
            title: 'Returning Products',
            icon: Icons.assignment_return,
            color: AppTheme.kBrown,
            isLocked: !hasRoute, // Locked if no route is active
          ),
          _buildActionCard(
            context: context,
            title: 'Uploads / Daily Report',
            icon: Icons.cloud_upload,
            color: AppTheme.kBrown,
            isLocked: false,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required bool isLocked,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLocked ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Opacity(
            opacity: isLocked ? 0.6 : 1.0,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isLocked ? Colors.grey[200] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isLocked
                      ? Colors.transparent
                      : AppTheme.kBrown.withOpacity(0.1),
                ),
                boxShadow: isLocked
                    ? []
                    : [
                        BoxShadow(
                          color: color.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isLocked
                          ? Colors.grey[400]
                          : color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: isLocked ? Colors.grey[600] : color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isLocked ? Colors.grey[600] : AppTheme.kTextDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isLocked)
                    Icon(Icons.lock, color: Colors.grey[500], size: 24)
                  else
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppTheme.kBrown.withOpacity(0.4),
                      size: 16,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    const storage = FlutterSecureStorage();
    await storage.deleteAll();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shimmer/shimmer.dart';

import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/presentation/pages/login_page.dart';
import 'package:mobile/features/home/presentation/cubit/home_cubit.dart';
import 'package:mobile/features/home/presentation/cubit/home_state.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/sales_return_cubit.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/upload_report_cubit.dart';
import 'package:mobile/features/sales_rep/presentation/pages/outlet_visit_page.dart';
import 'package:mobile/features/sales_rep/presentation/pages/register_outlet_page.dart';
import 'package:mobile/features/sales_rep/presentation/pages/report_incident_page.dart';
import 'package:mobile/features/sales_rep/presentation/pages/returning_products_page.dart';
import 'package:mobile/features/sales_rep/presentation/pages/smart_route_page.dart';
import 'package:mobile/features/sales_rep/presentation/pages/start_route_page.dart';
import 'package:mobile/features/home/presentation/controllers/sales_rep_activity_cubit.dart';
import 'package:mobile/features/home/presentation/widgets/sales_rep_activity_tab.dart';
import 'package:mobile/features/sales_rep/presentation/pages/upload_report_page.dart';

class SalesRepHomePage extends StatelessWidget {
  const SalesRepHomePage({super.key});

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  String? _normalizeTerritoryId(String? value) {
    final territoryId = value?.trim() ?? '';
    if (territoryId.isEmpty || !_uuidPattern.hasMatch(territoryId)) {
      return null;
    }
    return territoryId;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => HomeCubit()..loadHomeData()),
        BlocProvider(create: (context) => SalesRepActivityCubit()),
      ],
      child: _SalesRepHomeView(normalizeTerritoryId: _normalizeTerritoryId),
    );
  }
}

class _SalesRepHomeView extends StatefulWidget {
  const _SalesRepHomeView({required this.normalizeTerritoryId});

  final String? Function(String?) normalizeTerritoryId;

  @override
  State<_SalesRepHomeView> createState() => _SalesRepHomeViewState();
}

class _SalesRepHomeViewState extends State<_SalesRepHomeView> {
  int _currentIndex = 0;

  String _buildShopsTitle(HomeLoaded state) {
    if (state.shopsLeft <= 0) {
      return 'No shops left to visit today';
    }
    if (state.shopsLeft == 1) {
      return '1 shop left to visit today';
    }
    return '${state.shopsLeft} shops left to visit today';
  }

  String _buildShopsSubtitle(HomeLoaded state) {
    if (state.shopsLeft <= 0) {
      return 'Today\'s best plan is complete';
    }
    return state.hasActiveRoute ? 'Route is active' : 'From today\'s shop list';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kCream,
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeInitial || state is HomeLoading) {
              return _buildShimmerLoading();
            }
            if (state is HomeError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.kTextDark,
                    ),
                  ),
                ),
              );
            }
            if (state is! HomeLoaded) {
              return const SizedBox.shrink();
            }

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _currentIndex == 0
                  ? _buildHomeTab(context, state)
                  : _currentIndex == 1
                      ? const SalesRepActivityTab()
                      : _buildSettingsTab(context, state),
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.kCream,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Activity'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(
              5,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context, HomeLoaded state) {
    return SingleChildScrollView(
      key: const ValueKey('sales-rep-home'),
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(context, state),
            const SizedBox(height: 24),
            Text(
              'Work Dashboard',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.kTextDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _buildDashboardList(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, HomeLoaded state) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF5A382A), Color(0xFF211714)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kTextDark.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -8,
              top: 18,
              child: SizedBox(
                width: 170,
                height: 128,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: const [
                    _HeroProductImage(
                      assetPath: 'assets/images/products/milo_400g.png',
                      left: 6,
                      top: 24,
                      height: 78,
                    ),
                    _HeroProductImage(
                      assetPath: 'assets/images/products/nescafe_3in1.png',
                      left: 68,
                      top: 8,
                      height: 94,
                    ),
                    _HeroProductImage(
                      assetPath: 'assets/images/products/maggi_chicken.png',
                      left: 116,
                      top: 26,
                      height: 74,
                    ),
                    _HeroProductImage(
                      assetPath: 'assets/images/products/nestle_everyday_clean.png',
                      left: 90,
                      top: 62,
                      height: 54,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getGreeting(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                          onPressed: () => _handleLogout(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 170,
                    child: Text(
                      'Hello ${state.firstName}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeroInfoCard(
                          context,
                          title: 'Territory',
                          value: state.territoryName,
                          icon: Icons.location_on_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _buildHeroInfoCard(
                          context,
                          title: _buildShopsTitle(state),
                          value: _buildShopsSubtitle(state),
                          icon: Icons.local_shipping_outlined,
                          alignStart: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    bool alignStart = false,
  }) {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            alignStart ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.kBrown, size: 24),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              title,
              textAlign: alignStart ? TextAlign.left : TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.kTextDark,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              value,
              textAlign: alignStart ? TextAlign.left : TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.kBrown,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardList(BuildContext context, HomeLoaded state) {
    final hasRoute = state.hasActiveRoute;

    return Column(
      children: [
        _buildActionCard(
          context: context,
          title: 'Start The Day',
          subtitle: 'Select vehicle, opening stock, auto carry',
          icon: Icons.wb_sunny_outlined,
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
          title: 'Smart Route',
          subtitle: 'Plan the most efficient route',
          icon: Icons.alt_route,
          color: AppTheme.kBrown,
          isLocked: false,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SmartRoutePage(
                  routeId: state.activeRouteId,
                  territoryId: state.activeTerritoryId,
                ),
              ),
            );
          },
        ),
        _buildActionCard(
          context: context,
          title: 'Outlet Visit',
          subtitle: 'OSA, order taking, deliveries, and promotions',
          icon: Icons.storefront_outlined,
          color: AppTheme.kBrown,
          isLocked: !hasRoute,
          onTap: () {
            final routeId = state.activeRouteId ?? '';
            final territoryId = state.activeTerritoryId ?? '';
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => OutletVisitPage(
                  routeId: routeId,
                  territoryId: territoryId,
                ),
              ),
            );
          },
        ),
        _buildActionCard(
          context: context,
          title: 'Returning Products',
          subtitle: 'Manage product returns efficiently',
          icon: Icons.assignment_return_outlined,
          color: AppTheme.kBrown,
          isLocked: !hasRoute,
          onTap: () {
            final routeId = state.activeRouteId ?? '';
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BlocProvider(
                  create: (_) => SalesReturnCubit(),
                  child: ReturningProductsPage(routeId: routeId),
                ),
              ),
            );
          },
        ),
        _buildActionCard(
          context: context,
          title: 'Uploads',
          subtitle: 'View orders, reports, and upload daily data',
          icon: Icons.cloud_upload_outlined,
          color: AppTheme.kBrown,
          isLocked: false,
          onTap: () {
            final routeId = state.activeRouteId ?? '';
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BlocProvider(
                  create: (_) => UploadReportCubit()..loadMyReports(),
                  child: UploadReportPage(routeId: routeId),
                ),
              ),
            );
          },
        ),
        _buildActionCard(
          context: context,
          title: 'Register New Outlet',
          subtitle: 'Add a new outlet under your assigned territory',
          icon: Icons.add_business_outlined,
          color: AppTheme.kOrange,
          isLocked: false,
          onTap: () {
            final territoryId =
                widget.normalizeTerritoryId(state.activeTerritoryId) ??
                widget.normalizeTerritoryId(state.territoryId);
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RegisterOutletPage(territoryId: territoryId ?? ''),
              ),
            );
          },
        ),
        _buildActionCard(
          context: context,
          title: 'Report Incident',
          subtitle: 'Capture route issues and field exceptions',
          icon: Icons.warning_amber_rounded,
          color: AppTheme.promotionMutedRed,
          isLocked: !hasRoute,
          onTap: () {
            final routeId = state.activeRouteId;
            final territoryId = state.activeTerritoryId;
            if (routeId == null || territoryId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Missing route or territory details'),
                ),
              );
              return;
            }

            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ReportIncidentPage(
                  routeId: routeId,
                  territoryId: territoryId,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isLocked,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLocked ? null : onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              color: isLocked ? Colors.grey.shade200 : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isLocked
                    ? Colors.transparent
                    : AppTheme.kBrown.withValues(alpha: 0.14),
              ),
              boxShadow: [
                if (!isLocked)
                  BoxShadow(
                    color: color.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isLocked ? Colors.grey.shade400 : color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: isLocked ? Colors.grey.shade600 : color,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isLocked ? Colors.grey.shade700 : AppTheme.kTextDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isLocked ? Colors.grey.shade600 : AppTheme.textSoft,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  isLocked ? Icons.lock_outline : Icons.arrow_forward_ios_rounded,
                  size: isLocked ? 20 : 18,
                  color: isLocked ? Colors.grey.shade500 : AppTheme.kBrown,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTab(BuildContext context, HomeLoaded state) {
    return SingleChildScrollView(
      key: const ValueKey('sales-rep-settings'),
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.kTextDark.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: AppTheme.kCream,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.person, color: AppTheme.kBrown),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.fullName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.kTextDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sales Representative',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailTile(
                    context,
                    label: 'Assigned Territory',
                    value: state.territoryName,
                    icon: Icons.map_outlined,
                  ),
                  _buildDetailTile(
                    context,
                    label: 'Mobile Number',
                    value: state.mobileNumber,
                    icon: Icons.phone_outlined,
                  ),
                  _buildDetailTile(
                    context,
                    label: 'Email',
                    value: state.email,
                    icon: Icons.email_outlined,
                  ),
                  _buildDetailTile(
                    context,
                    label: 'Name',
                    value: state.fullName,
                    icon: Icons.badge_outlined,
                  ),
                  _buildDetailTile(
                    context,
                    label: 'Username',
                    value: state.username,
                    icon: Icons.alternate_email,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.kCream.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: AppTheme.kBrown),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.kTextDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    }
    if (hour < 17) {
      return 'Good Afternoon';
    }
    return 'Good Evening';
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

class _HeroProductImage extends StatelessWidget {
  const _HeroProductImage({
    required this.assetPath,
    required this.left,
    required this.top,
    required this.height,
  });

  final String assetPath;
  final double left;
  final double top;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Image.asset(assetPath, height: height, fit: BoxFit.contain),
      ),
    );
  }
}

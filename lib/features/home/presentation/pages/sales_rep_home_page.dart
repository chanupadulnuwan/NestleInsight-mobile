import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shimmer/shimmer.dart';

import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/services/auth_service.dart';
import 'package:mobile/features/auth/presentation/pages/login_page.dart';
import 'package:mobile/features/home/presentation/cubit/home_cubit.dart';
import 'package:mobile/features/home/presentation/cubit/home_state.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/sales_return_cubit.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/rep_order_cubit.dart';
import 'package:mobile/features/sales_rep/presentation/cubit/upload_report_cubit.dart';
import 'package:mobile/features/sales_rep/presentation/pages/end_route_page.dart';
import 'package:mobile/features/sales_rep/presentation/pages/outlet_visit_page.dart';
import 'package:mobile/features/sales_rep/presentation/pages/place_order_page.dart';
import 'package:mobile/features/sales_rep/presentation/pages/register_outlet_page.dart';
import 'package:mobile/features/sales_rep/presentation/pages/report_incident_page.dart';
import 'package:mobile/features/sales_rep/presentation/pages/returning_products_page.dart';
import 'package:mobile/features/sales_rep/presentation/pages/smart_route_page.dart';
import 'package:mobile/features/sales_rep/presentation/pages/start_route_page.dart';
import 'package:mobile/features/home/presentation/controllers/sales_rep_activity_cubit.dart';
import 'package:mobile/features/home/presentation/widgets/sales_rep_activity_tab.dart';
import 'package:mobile/features/home/presentation/widgets/sales_rep_profile_sheet.dart';
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
  static const String _profileImageStoragePrefix = 'sales_rep_profile_image_';

  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  int _currentIndex = 0;
  String? _profileImagePath;
  String? _profileImageLoadedFor;

  Future<void> _refreshHome() async {
    if (!mounted) {
      return;
    }
    await context.read<HomeCubit>().loadHomeData();
  }

  String _profileImageStorageKey(String username) =>
      '$_profileImageStoragePrefix${username.trim().toLowerCase()}';

  Future<void> _loadProfileImage(String username) async {
    _profileImageLoadedFor = username;
    final storedPath = await _storage.read(
      key: _profileImageStorageKey(username),
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _profileImagePath = storedPath;
    });
  }

  Future<void> _updateProfileImage(HomeLoaded state, String? path) async {
    final normalizedPath = path?.trim();
    final storageKey = _profileImageStorageKey(state.username);

    if (normalizedPath == null || normalizedPath.isEmpty) {
      await _storage.delete(key: storageKey);
    } else {
      await _storage.write(key: storageKey, value: normalizedPath);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _profileImagePath = normalizedPath == null || normalizedPath.isEmpty
          ? null
          : normalizedPath;
    });
  }

  Future<void> _handleProfileSaved(
    String previousUsername,
    SalesRepProfileData profile,
  ) async {
    final previousKey = _profileImageStorageKey(previousUsername);
    final nextKey = _profileImageStorageKey(profile.username);
    final normalizedPath = _profileImagePath?.trim();

    if (previousKey != nextKey) {
      if (normalizedPath != null && normalizedPath.isNotEmpty) {
        await _storage.write(key: nextKey, value: normalizedPath);
      }
      await _storage.delete(key: previousKey);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _profileImageLoadedFor = profile.username;
    });

    await context.read<HomeCubit>().loadHomeData();
  }

  void _ensureProfileImageLoaded(String username) {
    if (_profileImageLoadedFor == username) {
      return;
    }

    _loadProfileImage(username);
  }

  Future<void> _pushAndRefresh(Widget page) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
    await _refreshHome();
  }

  Future<void> _openProfileSheet(HomeLoaded state) async {
    await _loadProfileImage(state.username);
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SalesRepProfileSheet(
        profile: SalesRepProfileData(
          firstName: state.firstName,
          lastName: '',
          fullName: state.fullName,
          username: state.username,
          email: state.email,
          mobileNumber: state.mobileNumber,
          territoryName: state.territoryName,
          hasActiveRoute: state.hasActiveRoute,
          hasReportableRoute: state.hasReportableRoute,
          shopsLeft: state.shopsLeft,
        ),
        initialImagePath: _profileImagePath,
        onProfileImageChanged: (path) => _updateProfileImage(state, path),
        onLogoutRequested: _handleLogout,
        onProfileSaved: _handleProfileSaved,
      ),
    );
  }

  String _buildShopsTitle(HomeLoaded state) {
    if (!state.hasActiveRoute) {
      return state.hasReportableRoute
          ? 'Route closed. Report ready'
          : 'No active route today';
    }
    if (state.shopsLeft <= 0) {
      return 'No shops left to visit today';
    }
    if (state.shopsLeft == 1) {
      return '1 shop left to visit today';
    }
    return '${state.shopsLeft} shops left to visit today';
  }

  String _buildShopsSubtitle(HomeLoaded state) {
    if (!state.hasActiveRoute) {
      return state.hasReportableRoute
          ? 'Generate and upload the final report'
          : 'Start the day to create today\'s route';
    }
    if (state.shopsLeft <= 0) {
      return 'Today\'s beat plan is complete';
    }
    return state.hasActiveRoute ? 'Route is active' : 'From today\'s shop list';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Colors.white, Color(0xFFFFFCF8)],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -140,
              left: -110,
              child: IgnorePointer(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[Color(0x26CFAE73), Color(0x00CFAE73)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -120,
              bottom: -130,
              child: IgnorePointer(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[Color(0x1F8A6B53), Color(0x008A6B53)],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
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
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppTheme.kTextDark),
                        ),
                      ),
                    );
                  }
                  if (state is! HomeLoaded) {
                    return const SizedBox.shrink();
                  }

                  _ensureProfileImageLoaded(state.username);

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
          ],
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
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
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
    final isTablet = MediaQuery.sizeOf(context).width >= 720;

    return SingleChildScrollView(
      key: const ValueKey('sales-rep-home'),
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 1020 : 680),
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
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, HomeLoaded state) {
    final isTablet = MediaQuery.sizeOf(context).width >= 720;
    final profilePath = _profileImagePath?.trim();
    final hasProfileImage =
        profilePath != null &&
        profilePath.isNotEmpty &&
        File(profilePath).existsSync();

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
              top: -30,
              right: -18,
              child: Container(
                width: isTablet ? 220 : 160,
                height: isTablet ? 220 : 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(18),
                ),
              ),
            ),
            Positioned(
              bottom: -56,
              left: -28,
              child: Container(
                width: isTablet ? 180 : 136,
                height: isTablet ? 180 : 136,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(10),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 24 : 20,
                isTablet ? 20 : 18,
                isTablet ? 24 : 20,
                isTablet ? 20 : 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getGreeting(),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openProfileSheet(state),
                          borderRadius: BorderRadius.circular(999),
                          child: Ink(
                            width: isTablet ? 50 : 46,
                            height: isTablet ? 50 : 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(28),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withAlpha(80),
                              ),
                            ),
                            child: ClipOval(
                              child: hasProfileImage
                                  ? Image.file(
                                      File(profilePath),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.person_outline,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person_outline,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isTablet ? 360 : 240),
                    child: Text(
                      'Hello ${state.firstName}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  SizedBox(height: isTablet ? 18 : 14),
                  Row(
                    children: [
                      Expanded(
                        flex: isTablet ? 5 : 4,
                        child: _buildHeroInfoCard(
                          context,
                          title: 'Territory',
                          value: state.territoryName,
                          icon: Icons.location_on_outlined,
                          isTablet: isTablet,
                        ),
                      ),
                      SizedBox(width: isTablet ? 14 : 12),
                      Expanded(
                        flex: isTablet ? 7 : 6,
                        child: _buildHeroInfoCard(
                          context,
                          title: _buildShopsTitle(state),
                          value: _buildShopsSubtitle(state),
                          icon: Icons.local_shipping_outlined,
                          alignStart: true,
                          isTablet: isTablet,
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
    required bool isTablet,
  }) {
    final useStartAlignment = alignStart || isTablet;

    return Container(
      height: isTablet ? 88 : 96,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 14,
        vertical: isTablet ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: useStartAlignment
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.kBrown, size: 24),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              title,
              textAlign: useStartAlignment ? TextAlign.left : TextAlign.center,
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
              textAlign: useStartAlignment ? TextAlign.left : TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.kBrown,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardList(BuildContext context, HomeLoaded state) {
    final hasRoute = state.hasActiveRoute;
    final routeId = state.activeRouteId ?? '';
    final territoryId = state.activeTerritoryId ?? state.territoryId ?? '';
    final reportRouteId = state.reportableRouteId ?? '';
    final actions = <_DashboardActionItem>[
      _DashboardActionItem(
        title: 'Start The Day',
        subtitle: 'Select vehicle, opening stock, auto carry',
        icon: Icons.wb_sunny_outlined,
        color: AppTheme.kOrange,
        isLocked: false,
        onTap: () => _pushAndRefresh(const StartRoutePage()),
      ),
      _DashboardActionItem(
        title: 'Smart Route',
        subtitle: 'Plan the most efficient route',
        icon: Icons.alt_route,
        color: AppTheme.kBrown,
        isLocked: false,
        onTap: () => _pushAndRefresh(
          SmartRoutePage(
            routeId: state.activeRouteId,
            territoryId: state.activeTerritoryId,
          ),
        ),
      ),
      _DashboardActionItem(
        title: 'Outlet Visit',
        subtitle: 'OSA, order taking, deliveries, and promotions',
        icon: Icons.storefront_outlined,
        color: AppTheme.kBrown,
        isLocked: !hasRoute,
        onTap: () => _pushAndRefresh(
          OutletVisitPage(routeId: routeId, territoryId: territoryId),
        ),
      ),
      _DashboardActionItem(
        title: 'Returning Products',
        subtitle: 'Manage product returns efficiently',
        icon: Icons.assignment_return_outlined,
        color: AppTheme.kBrown,
        isLocked: !hasRoute,
        onTap: () => _pushAndRefresh(
          BlocProvider(
            create: (_) => SalesReturnCubit(),
            child: ReturningProductsPage(routeId: routeId),
          ),
        ),
      ),
      _DashboardActionItem(
        title: 'End Route',
        subtitle: 'Hand over returns and remaining lorry stock',
        icon: Icons.fact_check_outlined,
        color: AppTheme.proceedOrderOlive,
        isLocked: !hasRoute,
        onTap: () => _pushAndRefresh(EndRoutePage(routeId: routeId)),
      ),
      _DashboardActionItem(
        title: 'Uploads',
        subtitle: 'Generate, review, and upload route reports',
        icon: Icons.cloud_upload_outlined,
        color: AppTheme.kBrown,
        isLocked: !state.hasReportableRoute,
        onTap: () => _pushAndRefresh(
          BlocProvider(
            create: (_) => UploadReportCubit()..loadMyReports(),
            child: UploadReportPage(routeId: reportRouteId),
          ),
        ),
      ),
      _DashboardActionItem(
        title: 'Register New Outlet',
        subtitle: 'Add a new outlet under your assigned territory',
        icon: Icons.add_business_outlined,
        color: AppTheme.kOrange,
        isLocked: false,
        onTap: () {
          final territoryId =
              widget.normalizeTerritoryId(state.activeTerritoryId) ??
              widget.normalizeTerritoryId(state.territoryId);
          _pushAndRefresh(RegisterOutletPage(territoryId: territoryId ?? ''));
        },
      ),
      _DashboardActionItem(
        title: 'Place an Order',
        subtitle: 'Create assisted orders for assigned shops',
        icon: Icons.add_shopping_cart_outlined,
        color: AppTheme.proceedOrderOlive,
        isLocked: !hasRoute,
        onTap: () => _pushAndRefresh(
          BlocProvider(
            create: (_) => RepOrderCubit(),
            child: PlaceOrderPage(routeId: routeId),
          ),
        ),
      ),
      _DashboardActionItem(
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

          _pushAndRefresh(
            ReportIncidentPage(routeId: routeId, territoryId: territoryId),
          );
        },
      ),
    ];
    final isTablet = MediaQuery.sizeOf(context).width >= 720;

    if (!isTablet) {
      return Column(
        children: [
          for (var index = 0; index < actions.length; index++) ...[
            _buildActionCard(
              context: context,
              title: actions[index].title,
              subtitle: actions[index].subtitle,
              icon: actions[index].icon,
              color: actions[index].color,
              isLocked: actions[index].isLocked,
              onTap: actions[index].onTap,
              isTabletLayout: false,
            ),
            if (index != actions.length - 1) const SizedBox(height: 14),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 16) / 2;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: actions
              .map(
                (action) => SizedBox(
                  width: cardWidth,
                  child: _buildActionCard(
                    context: context,
                    title: action.title,
                    subtitle: action.subtitle,
                    icon: action.icon,
                    color: action.color,
                    isLocked: action.isLocked,
                    onTap: action.onTap,
                    isTabletLayout: true,
                  ),
                ),
              )
              .toList(),
        );
      },
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
    required bool isTabletLayout,
  }) {
    return Material(
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
                  ? AppTheme.primaryBrownDark.withValues(alpha: 0.18)
                  : AppTheme.primaryBrownDark.withValues(alpha: 0.28),
              width: isLocked ? 1.0 : 1.2,
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
          padding: EdgeInsets.symmetric(
            horizontal: isTabletLayout ? 18 : 16,
            vertical: isTabletLayout ? 18 : 16,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: isTabletLayout ? 118 : 88),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isLocked
                        ? Colors.grey.shade400
                        : color.withValues(alpha: 0.12),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: isLocked
                                  ? Colors.grey.shade700
                                  : AppTheme.kTextDark,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isLocked
                              ? Colors.grey.shade600
                              : AppTheme.textSoft,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: isTabletLayout ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  isLocked
                      ? Icons.lock_outline
                      : Icons.arrow_forward_ios_rounded,
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
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.kTextDark,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sales Representative',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.textSoft),
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

  Future<void> _handleLogout() async {
    await _authService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}

class _DashboardActionItem {
  const _DashboardActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isLocked,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isLocked;
  final VoidCallback onTap;
}

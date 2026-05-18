import 'package:flutter/material.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/storage/token_storage_service.dart';
import 'package:mobile/core/widgets/insight_loading_screen.dart';
import 'package:mobile/features/auth/presentation/pages/login_page.dart';
import 'package:mobile/features/distributor/presentation/pages/distributor_home_page.dart';
import 'package:mobile/features/home/presentation/pages/shop_owner_dashboard_page.dart';
import 'package:mobile/features/home/presentation/pages/dummy_home_page.dart';
import '../../features/home/presentation/pages/sales_rep_home_page.dart';
import 'package:dio/dio.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final storage = TokenStorageService();
    final token = await storage.readAccessToken();

    if (token == null || token.isEmpty) {
      _goToLogin();
      return;
    }

    try {
      final dio = DioClient.instance.client;
      final response = await dio.get<Map<String, dynamic>>('/auth/me');
      final user = response.data?['user'] as Map<String, dynamic>?;
      if (user != null) {
        await storage.saveUserData(user);
        _goToHome(user);
      } else {
        _goToLogin();
      }
    } on DioException {
      await storage.clearSession();
      _goToLogin();
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
    );
  }

  void _goToHome(Map<String, dynamic> user) {
    if (!mounted) return;
    final role = user['role'] as String?;
    Widget home;
    if (role == 'SHOP_OWNER') {
      home = ShopOwnerDashboardPage(user: user);
    } else if (role == 'TERRITORY_DISTRIBUTOR') {
      home = DistributorHomePage(user: user);
    } else if (role == 'SALES_REP') {
      home = const SalesRepHomePage();
    } else {
      home = DummyHomePage(user: user);
    }
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => home));
  }

  @override
  Widget build(BuildContext context) {
    return const InsightLoadingScreen();
  }
}

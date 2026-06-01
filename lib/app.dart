import 'package:flutter/material.dart';
import 'package:mobile/core/services/localization_service.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/auth_gate.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    LocalizationService.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LocalizationService.instance,
      builder: (context, child) {
        return MaterialApp(
          title: 'Nestle Insight',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const AuthGate(),
        );
      },
    );
  }
}


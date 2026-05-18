import 'package:flutter/material.dart';

class InsightLoadingScreen extends StatefulWidget {
  const InsightLoadingScreen({super.key});

  @override
  State<InsightLoadingScreen> createState() => _InsightLoadingScreenState();
}

class _InsightLoadingScreenState extends State<InsightLoadingScreen>
    with SingleTickerProviderStateMixin {
  static const _tagline = 'Sell.Record.Done';

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 700;
          final logoWidth = isTablet ? 320.0 : 250.0;
          final welcomeWidth = isTablet ? 300.0 : 245.0;

          return SafeArea(
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: -130,
                  left: -100,
                  child: IgnorePointer(
                    child: Container(
                      width: isTablet ? 320 : 240,
                      height: isTablet ? 320 : 240,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: <Color>[
                            Color(0x1FCFAE73),
                            Color(0x00CFAE73),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -110,
                  bottom: -120,
                  child: IgnorePointer(
                    child: Container(
                      width: isTablet ? 340 : 260,
                      height: isTablet ? 340 : 260,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: <Color>[
                            Color(0x178A6B53),
                            Color(0x008A6B53),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 40 : 28,
                    vertical: isTablet ? 28 : 24,
                  ),
                  child: Column(
                    children: [
                      const Spacer(flex: 5),
                      Center(
                        child: Image.asset(
                          'assets/branding/splash_logo.png',
                          width: logoWidth,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: isTablet ? 108 : 88),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/branding/welcome_note.png',
                            width: welcomeWidth,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 12),
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, _) {
                              return Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 0,
                                children: List<Widget>.generate(
                                  _tagline.length,
                                  (index) => _AnimatedTaglineLetter(
                                    controllerValue: _controller.value,
                                    character: _tagline[index],
                                    index: index,
                                    isTablet: isTablet,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const Spacer(flex: 4),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedTaglineLetter extends StatelessWidget {
  const _AnimatedTaglineLetter({
    required this.controllerValue,
    required this.character,
    required this.index,
    required this.isTablet,
  });

  final double controllerValue;
  final String character;
  final int index;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final shift = index * 0.055;
    var phase = controllerValue - shift;
    while (phase < 0) {
      phase += 1;
    }
    phase = phase % 1;

    double pop;
    if (phase < 0.18) {
      pop = Curves.easeOutBack.transform(phase / 0.18);
    } else if (phase < 0.36) {
      pop = 1 - Curves.easeIn.transform((phase - 0.18) / 0.18);
    } else {
      pop = 0;
    }
    final safePop = pop.clamp(0.0, 1.0);

    final lift = -8.0 * safePop;
    final scale = 1 + (0.12 * safePop);
    final opacity = (0.72 + (0.28 * safePop)).clamp(0.0, 1.0);

    return Transform.translate(
      offset: Offset(0, lift),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Text(
            character,
            style: TextStyle(
              color: const Color(0xFF5E4B40),
              fontSize: isTablet ? 21 : 17,
              fontWeight: FontWeight.w500,
              letterSpacing: isTablet ? 1.8 : 1.25,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

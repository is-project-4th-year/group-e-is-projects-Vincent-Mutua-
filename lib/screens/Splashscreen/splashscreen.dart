import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ics_application/screens/Authentication/signup.dart';

// 1. Converted to a StatefulWidget to manage the animation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// 2. Added "TickerProviderStateMixin" to handle the animation ticks
class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  final String appLogoPath = 'assets/images/logo.svg';
  final double logoWidth = 350.0;
  final double logoHeight = 350.0;

  // 3. Defined the AnimationController and Color Animations
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation1;
  late Animation<Color?> _colorAnimation2;

  @override
  void initState() {
    super.initState();

    _navigateToSignUp();

    // 4. Initialized the controller
    _controller = AnimationController(
      // Duration of one pulse cycle (e.g., 1.5 seconds)
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true); // Makes it loop back and forth (pulse)

    // 5. Created the Color Tweens (transitions)
    
    // Animation for the top color of the gradient
    // It pulses between the two blue/purple hues
    _colorAnimation1 = ColorTween(
      begin: const Color(0xFF1a1a2c),
      end: const Color(0xFF19182d), 
    ).animate(_controller);

    // Animation for the bottom color of the gradient
    // It pulses between the dark grey and the blue/purple hue
    _colorAnimation2 = ColorTween(
      begin: const Color(0xFF181920), 
      end: const Color(0xFF1a1a2c),
    ).animate(_controller);
  }

  void _navigateToSignUp() async {
    // Wait for 3 seconds to show the animation
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      // Use pushReplacement to prevent going back to the splash screen
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SignUpScreen()));
    }
  }

  @override
  void dispose() {
    // 6. Disposed the controller to prevent memory leaks
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 7. Removed the static background color
      //    The AnimatedBuilder now provides the background
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // 8. This Container is the animated part that rebuilds
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                // 9. Used the animated color values from the tweens
                colors: [
                  _colorAnimation1.value!,
                  _colorAnimation2.value!,
                ],
              ),
            ),
            // "child" here is the static content from below
            child: child,
          );
        },
        // 10. This "child" is your static content (logo/text).
        //     It is passed into the builder and does NOT rebuild,
        //     which is much more efficient.
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                appLogoPath,
                width: logoWidth,
                height: logoHeight,
                semanticsLabel: 'App Logo',
              ),
              const SizedBox(height: 24), // Spacing between logo and text
              const Text(
                'App',
                style: TextStyle(
                  fontFamily: 'Lato-Bold',
                  fontSize: 30,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




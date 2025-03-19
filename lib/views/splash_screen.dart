import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoBounceAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late List<Animation<double>> _buttonFadeAnimations;
  late List<Animation<Offset>> _buttonSlideAnimations;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    _logoBounceAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.bounceOut),
      ),
    );

    _logoRotationAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.3, 0.8, curve: Curves.easeInOut),
      ),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: Offset(1.0, 0.0),
      end: Offset(0.0, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.3, 0.8, curve: Curves.easeInOut),
      ),
    );

    _buttonFadeAnimations = [
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0.5, 1.0, curve: Curves.easeInOut),
        ),
      ),
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0.6, 1.0, curve: Curves.easeInOut),
        ),
      ),
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0.7, 1.0, curve: Curves.easeInOut),
        ),
      ),
    ];

    _buttonSlideAnimations = [
      Tween<Offset>(begin: Offset(0.0, 0.5), end: Offset(0.0, 0.0)).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0.5, 1.0, curve: Curves.easeInOut),
        ),
      ),
      Tween<Offset>(begin: Offset(0.0, 0.5), end: Offset(0.0, 0.0)).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0.6, 1.0, curve: Curves.easeInOut),
        ),
      ),
      Tween<Offset>(begin: Offset(0.0, 0.5), end: Offset(0.0, 0.0)).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0.7, 1.0, curve: Curves.easeInOut),
        ),
      ),
    ];

    _controller.forward();
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _logoBounceAnimation.value * 200),
                  child: Transform.rotate(
                    angle: _logoRotationAnimation.value,
                    child: Icon(
                      Icons.location_on,
                      size: 100,
                      color: Color(0xFF6200EE),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            FadeTransition(
              opacity: _textFadeAnimation,
              child: SlideTransition(
                position: _textSlideAnimation,
                child: Column(
                  children: [
                    Text(
                      'SpotVibe',
                      style: GoogleFonts.poppins(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6200EE),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Discover the vibe of your city',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40),
            FadeTransition(
              opacity: _buttonFadeAnimations[0],
              child: SlideTransition(
                position: _buttonSlideAnimations[0],
                child: SizedBox(
                  width: 250,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6200EE),
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Sign In',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 15),
            FadeTransition(
              opacity: _buttonFadeAnimations[1],
              child: SlideTransition(
                position: _buttonSlideAnimations[1],
                child: SizedBox(
                  width: 250,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Color(0xFF6200EE)),
                      ),
                    ),
                    child: Text(
                      'Sign Up',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Color(0xFF6200EE),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 15),
            FadeTransition(
              opacity: _buttonFadeAnimations[2],
              child: SlideTransition(
                position: _buttonSlideAnimations[2],
                child: SizedBox(
                  width: 250,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/google_icon.webp',
                          height: 24,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Sign Up with Google',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
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
}

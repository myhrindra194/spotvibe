import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Home',
          style: GoogleFonts.poppins(
            color: Color(0xFF6200EE),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Text(
          'Welcome to SpotVibe!',
          style: GoogleFonts.poppins(
            fontSize: 24,
            color: Color(0xFF6200EE),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_application_1/viewmodels/registration_viewmodel.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  RegistrationScreenState createState() => RegistrationScreenState();
}

class RegistrationScreenState extends State<RegistrationScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitForm(BuildContext context) {
    final registrationViewModel =
        Provider.of<RegistrationViewModel>(context, listen: false);

    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez entrer une adresse e-mail valide')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Les mots de passe ne correspondent pas')),
      );
      return;
    }

    registrationViewModel.signUpWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      'Default Name',
    );
  }

  @override
  Widget build(BuildContext context) {
    final registrationViewModel = Provider.of<RegistrationViewModel>(context);

    if (registrationViewModel.user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }

    if (registrationViewModel.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(registrationViewModel.errorMessage!)),
        );
        registrationViewModel.errorMessage = null;
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  size: 60,
                  color: Color(0xFF6200EE),
                ),
                SizedBox(height: 20),
                Text(
                  'Create Account',
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6200EE),
                  ),
                ),
                SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.email, color: Color(0xFF6200EE)),
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.lock, color: Color(0xFF6200EE)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Color(0xFF6200EE),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.lock, color: Color(0xFF6200EE)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Color(0xFF6200EE),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: registrationViewModel.isLoading
                        ? null
                        : () => _submitForm(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6200EE),
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: registrationViewModel.isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Sign Up',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: Text(
                    'Already have an account? Sign In',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Color(0xFF6200EE),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

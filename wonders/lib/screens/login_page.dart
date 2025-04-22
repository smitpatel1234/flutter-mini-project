import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'dart:math';
import '../services/auth_service.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _controller;
  late Animation<double> _cloudAnimation;
  late Animation<double> _unicornScaleAnimation;
  late Animation<double> _unicornRotationAnimation;
  late Animation<double> _unicornFloatAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 6),
    )..repeat(reverse: true);

    _cloudAnimation = Tween<double>(
      begin: 0,
      end: 50,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _unicornScaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _unicornRotationAnimation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _unicornFloatAnimation = Tween<double>(
      begin: -5,
      end: 5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await _authService.signInWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        // Navigation handled by auth stream in main.dart
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();
      // Navigation handled by auth stream in main.dart
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.cyanAccent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Container(
              alignment: Alignment.center,
              child: Text(
                "Login",
                style: TextStyle(
                  letterSpacing: 2.0,
                  fontSize: 45,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ),
            // Positioned cloud animation
            AnimatedBuilder(
              animation: _cloudAnimation,
              builder: (context, child) {
                return Positioned(
                  left: 50 * sin((_cloudAnimation.value - 25) / 25) + 10,
                  top: 25 * sin((_cloudAnimation.value - 25) / 25) + 40,
                  child: Image.asset('assets/images/cloud.png', width: 100),
                );
              },
            ),
            AnimatedBuilder(
              animation: _cloudAnimation,
              builder: (context, child) {
                return Positioned(
                  right: 50 * sin((_cloudAnimation.value - 25) / 25) + 10,
                  top: 25 * sin((_cloudAnimation.value - 25) / 25) + 40,
                  child: Image.asset('assets/images/cloud.png', width: 100),
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Color.fromARGB(255, 255, 136, 25),
              Color.fromARGB(255, 206, 228, 12),
            ],
            radius: 3.0,
            center: Alignment(-2.0, -1.0),
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated unicorn
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _unicornFloatAnimation.value),
                        child: Transform.rotate(
                          angle: _unicornRotationAnimation.value,
                          child: Transform.scale(
                            scale: _unicornScaleAnimation.value,
                            child: Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(249, 247, 197, 0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius:
                                        30 * _unicornScaleAnimation.value,
                                    offset: Offset(0, 5),
                                    spreadRadius:
                                        2 * _unicornScaleAnimation.value,
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: child,
                            ),
                          ),
                        ),
                      );
                    },
                    child: Image.network(
                      'https://img.icons8.com/officel/80/unicorn.png',
                      height: 80,
                    ),
                  ),
                  SizedBox(height: 20),
                  if (_errorMessage != null)
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!EmailValidator.validate(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                      textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child:
                        _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                              'Login',
                              style: TextStyle(color: Colors.white),
                            ),
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegisterPage()),
                      );
                    },
                    child: Text(
                      'Need an account? Register now',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  // Add Google Sign-In section below
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: Colors.white70, thickness: 1),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "OR",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Colors.white70, thickness: 1),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: Container(
                      height: 60, // Fixed size from 60 to 30
                      width: 60, // Fixed size from 60 to 30
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Image.network(
                        'https://img.icons8.com/clouds/100/google-logo.png',
                        height: 40,
                      ),
                    ),
                    label: Text(
                      'Sign in with Google',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

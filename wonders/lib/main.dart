import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wonders of the World',
      home: MyHomePage(),
      theme: ThemeData(primarySwatch: Colors.blue),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _cloudAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    )..repeat(reverse: true); // Repeats the animation back and forth

    _cloudAnimation = Tween<double>(
      begin: -10,
      end: 100,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose(); // Free resources
    super.dispose();
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
            AnimatedBuilder(
              animation: _cloudAnimation,
              builder: (context, child) {
                return Positioned(
                  left: _cloudAnimation.value,
                  top: 10,
                  child: Image.asset('assets/images/cloud.png', width: 100),
                );
              },
            ),
            AnimatedBuilder(
              animation: _cloudAnimation,
              builder: (context, child) {
                return Positioned(
                  right: _cloudAnimation.value,
                  bottom: 10,
                  child: Image.asset('assets/images/cloud.png', width: 100),
                );
              },
            ),
            Container(
              alignment: Alignment.center,
              child: Text(
                "Wonders of the World",
                style: TextStyle(
                  letterSpacing: 2.0,
                  fontSize: 45,
                  fontFamily: GoogleFonts.mouseMemoirs().fontFamily,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Container(
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
        ),
      ),
    );
  }
}

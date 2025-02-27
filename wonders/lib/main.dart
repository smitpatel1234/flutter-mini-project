import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);
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
              alignment: Alignment.bottomRight,
              child: Image.asset('assets/images/cloud.png', fit: BoxFit.fill),
            ),
            Container(
              alignment: Alignment.bottomLeft,
              child: Image.asset(
                'assets/images/cloud.png',
                fit: BoxFit.fill,
                alignment: Alignment.bottomLeft,
              ),
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
                const Color.fromARGB(255, 255, 136, 25),
                const Color.fromARGB(255, 206, 228, 12),
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

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import for User class
import 'package:google_fonts/google_fonts.dart'; // Add this import for GoogleFonts
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        StreamProvider(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Wonders of the World',
        home: AuthWrapper(),
        theme: ThemeData(primarySwatch: Colors.blue),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    // Return home or login screen based on auth state
    if (user != null) {
      return MyHomePage();
    } else {
      return LoginPage();
    }
  }
}

class MyHomePage extends StatefulWidget {
  // Remove const keyword since we need to initialize state
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
    final authService = Provider.of<AuthService>(context);

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
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await authService.signOut();
            },
            tooltip: 'Sign Out',
          ),
        ],
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Welcome to Wonders of the World!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "You are signed in as: ${authService.currentUser?.email}",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

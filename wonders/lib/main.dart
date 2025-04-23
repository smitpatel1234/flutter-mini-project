import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:wonders/screens/PersonalWondersPage.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/image_service.dart';
import 'services/wonder_service.dart';
import 'models/user_model.dart';
import 'models/user_wonder_model.dart';
import 'screens/login_page.dart';
import 'screens/profile_page.dart';
import 'screens/user_wonder_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'services/budget_service.dart';
import 'models/wonder_budget_model.dart';
import 'screens/wonder_budget_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Verify Firebase Storage is correctly initialized
  try {
    final storage = FirebaseStorage.instance;
    print('✓ Firebase Storage initialized with bucket: ${storage.bucket}');

    // Create test reference to verify access
    final testRef = storage.ref('test.txt');
    print('✓ Created test reference: ${testRef.fullPath}');
  } catch (e) {
    print('✗ Firebase Storage initialization error: $e');
  }
  runApp(MyApp());
}

// Rest of your imports...
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Wonders App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: AuthenticationWrapper(),
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();

    if (user != null) {
      return HomePage();
    }
    return LoginPage();
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _cloudAnimation;
  late Animation<double> _leftCloudAnimation;
  late Animation<double> _rightCloudAnimation;

  @override
  void initState() {
    super.initState();

    // Create animation controller
    _cloudAnimation = AnimationController(
      vsync: this,
      duration: Duration(seconds: 20), // Slower animation for smoother movement
    )..repeat(reverse: true);

    // Create left cloud animation
    _leftCloudAnimation = Tween<double>(
      begin: -50.0, // Start from slightly off-screen
      end: 100.0, // Move to visible area
    ).animate(
      CurvedAnimation(parent: _cloudAnimation, curve: Curves.easeInOut),
    );

    // Create right cloud animation
    _rightCloudAnimation = Tween<double>(
      begin: 100.0, // Start from visible area
      end: -50.0, // Move slightly off-screen
    ).animate(
      CurvedAnimation(parent: _cloudAnimation, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _cloudAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final wonderService = WonderService();

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
                  left: _leftCloudAnimation.value,
                  top: 10,
                  child: Image.asset(
                    'assets/images/cloud.png',
                    width: 100,
                    color: Colors.white.withOpacity(
                      0.8,
                    ), // Semi-transparent clouds
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _cloudAnimation,
              builder: (context, child) {
                return Positioned(
                  right: _rightCloudAnimation.value,
                  bottom: 10,
                  child: Image.asset(
                    'assets/images/cloud.png',
                    width: 80, // Slightly smaller for variety
                    color: Colors.white.withOpacity(0.7),
                  ),
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
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
            tooltip: 'Profile',
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await authService.signOut();
            },
            tooltip: 'Sign Out',
          ),
        ],
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
        child: FutureBuilder<UserModel?>(
          future: authService.getUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final user = snapshot.data;
            final userName =
                user?.name ??
                authService.currentUser?.email?.split('@')[0] ??
                'Explorer';

            return SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Center(
                    child: Text(
                      "Welcome, $userName!",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 30),

                  // Create Your Wonder Card
                  _buildCreateWonderCard(context),

                  SizedBox(height: 30),

                  // User's Wonders Section
                  Text(
                    "Your Personal Wonders",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 15),
                  // Add in the section where user wonders are displayed

                  // Add this before or after your horizontal ListView of wonders
                  Container(
                    margin: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Budget button
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WonderBudgetPage(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.deepPurple, Colors.purple],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.purple.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Budget',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 8), // Space between buttons
                            // Existing See All button
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PersonalWondersPage(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue, Colors.cyanAccent],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'See All',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Stream builder to show user wonders
                  StreamBuilder<List<UserWonderModel>>(
                    stream: wonderService.getUserWonders(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Error: ${snapshot.error}'),
                          ),
                        );
                      }

                      final userWonders = snapshot.data ?? [];

                      if (userWonders.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.add_location_alt,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'You haven\'t added any personal wonders yet',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Container(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: userWonders.length,
                          itemBuilder: (context, index) {
                            final wonder = userWonders[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            UserWonderPage(wonderId: wonder.id),
                                  ),
                                ).then((value) {
                                  // Refresh if needed
                                  if (value == true) {
                                    setState(() {});
                                  }
                                });
                              },
                              child: Container(
                                width: 200,
                                margin: EdgeInsets.only(right: 15),
                                child: Card(
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      if (wonder.imageUrl != null)
                                        CachedNetworkImage(
                                          imageUrl: wonder.imageUrl!,
                                          fit: BoxFit.cover,
                                          placeholder:
                                              (context, url) => Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                          errorWidget:
                                              (context, url, error) =>
                                                  Container(
                                                    color: Colors.blue[100],
                                                    child: Icon(
                                                      Icons.photo,
                                                      size: 50,
                                                    ),
                                                  ),
                                        )
                                      else
                                        Container(
                                          color: Colors.blue[100],
                                          child: Icon(Icons.photo, size: 50),
                                        ),

                                      // Add the "Visited" badge for completed wonders
                                      if (wonder.isCompleted == true)
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.check_circle,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  "Visited",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          color: Colors.black54,
                                          padding: EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 8,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                wonder.name,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              if (wonder.plannedVisitDate !=
                                                  null)
                                                Text(
                                                  DateFormat(
                                                    'MMM d, yyyy',
                                                  ).format(
                                                    wonder.plannedVisitDate!,
                                                  ),
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 30),

                  // Static World Wonders Section
                  Text(
                    "Explore Famous Wonders",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 15),
                  _buildWondersGrid(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Method to build the wonders grid
  Widget _buildWondersGrid(BuildContext context) {
    // Enhanced list of famous world wonders with locations and descriptions
    final wonders = [
      {
        'name': 'Great Wall of China',
        'location': 'China',
        'description':
            'A series of fortifications built along the northern borders of China to protect against invasions.',
      },
      {
        'name': 'Petra',
        'location': 'Jordan',
        'description':
            'A historical and archaeological city known for its rock-cut architecture and water conduit system.',
      },
      {
        'name': 'Colosseum',
        'location': 'Italy',
        'description':
            'An oval amphitheatre in the center of Rome, built of travertine limestone, tuff, and brick-faced concrete.',
      },
      {
        'name': 'Machu Picchu',
        'location': 'Peru',
        'description':
            'A 15th-century Inca citadel situated on a mountain ridge above the Urubamba Valley.',
      },
      {
        'name': 'Taj Mahal',
        'location': 'India',
        'description':
            'An ivory-white marble mausoleum commissioned in 1632 by the Mughal emperor Shah Jahan.',
      },
      {
        'name': 'Christ the Redeemer',
        'location': 'Brazil',
        'description':
            'An Art Deco statue of Jesus Christ created by French sculptor Paul Landowski in Rio de Janeiro.',
      },
    ];

    // Create instance of image service
    final imageService = ImageService();

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: wonders.length,
      itemBuilder: (context, index) {
        final wonder = wonders[index];

        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    constraints: BoxConstraints(maxHeight: 450),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Use FutureBuilder for image in dialog as well
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: FutureBuilder<String>(
                            future: imageService.getWonderImage(
                              wonder['name']!,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Container(
                                  height: 180,
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              } else if (snapshot.hasError ||
                                  !snapshot.hasData) {
                                return Container(
                                  height: 180,
                                  color: Colors.grey[300],
                                  child: Icon(Icons.broken_image, size: 50),
                                );
                              }

                              return CachedNetworkImage(
                                imageUrl: snapshot.data!,
                                height: 180,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Container(
                                      height: 180,
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
                                      height: 180,
                                      color: Colors.grey[300],
                                      child: Icon(Icons.broken_image, size: 50),
                                    ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                wonder['name']!,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    wonder['location']!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Text(
                                wonder['description']!,
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Close'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Use FutureBuilder with image service to get dynamic images for each wonder
                FutureBuilder<String>(
                  future: imageService.getWonderImage(wonder['name']!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError || !snapshot.hasData) {
                      return Container(
                        color: Colors.grey[300],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, color: Colors.red),
                            SizedBox(height: 4),
                            Text("Image error", style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      );
                    }

                    return CachedNetworkImage(
                      imageUrl: snapshot.data!,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) =>
                              Center(child: CircularProgressIndicator()),
                      errorWidget:
                          (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, color: Colors.red),
                                SizedBox(height: 4),
                                Text(
                                  "Image error",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                    );
                  },
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.0),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wonder['name']!,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          wonder['location']!,
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                // Info button hint
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // New method to build the "Create Your Wonder" card
  Widget _buildCreateWonderCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => UserWonderPage()),
        ).then((value) {
          // Refresh if needed
          if (value == true) {
            setState(() {});
          }
        });
      },
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.blue.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_location_alt,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Create Your Own Wonder",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Add places you want to visit with photos and plans",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

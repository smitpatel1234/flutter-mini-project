import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get user data from Firestore
  Future<UserModel?> getUserData() async {
    if (currentUser == null) return null;

    DocumentSnapshot doc =
        await _firestore.collection('users').doc(currentUser!.uid).get();

    if (doc.exists) {
      return UserModel.fromJson(doc.data() as Map<String, dynamic>);
    } else {
      // Create basic user if not exists
      final userModel = UserModel(
        uid: currentUser!.uid,
        email: currentUser!.email ?? '',
      );
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .set(userModel.toJson());
      return userModel;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? gender,
    DateTime? dateOfBirth,
    String? wonder,
  }) async {
    if (currentUser == null) return;

    Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (gender != null) data['gender'] = gender;
    if (dateOfBirth != null) {
      data['dateOfBirth'] = dateOfBirth.millisecondsSinceEpoch;
    }
    if (wonder != null) data['wonder'] = wonder;

    await _firestore.collection('users').doc(currentUser!.uid).update(data);
  }

  // Sign in with email & password
  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if user exists in Firestore, create if not
      await _checkUserInFirestore(result.user!);

      return result;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Sign in failed';
    }
  }

  // Register with email & password
  Future<UserCredential> registerWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create new user in Firestore
      await _createUserInFirestore(result.user!);

      return result;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Registration failed';
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential result = await _auth.signInWithCredential(credential);

      // Check if user exists in Firestore, create if not
      await _checkUserInFirestore(result.user!);

      return result;
    } catch (e) {
      throw 'Google sign in failed: $e';
    }
  }

  // Check if user exists in Firestore and create if not
  Future<void> _checkUserInFirestore(User user) async {
    DocumentSnapshot doc =
        await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      await _createUserInFirestore(user);
    }
  }

  // Create new user document in Firestore
  Future<void> _createUserInFirestore(User user) async {
    UserModel userModel = UserModel(uid: user.uid, email: user.email ?? '');

    await _firestore.collection('users').doc(user.uid).set(userModel.toJson());
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    return await _auth.signOut();
  }
}

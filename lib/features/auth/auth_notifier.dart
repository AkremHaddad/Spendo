import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthNotifier extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final GoogleSignIn _googleSignIn;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  User? get currentUser => _auth.currentUser;
  String? get userId => currentUser?.uid;
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  AuthNotifier() {
    _auth.authStateChanges().listen((user) {
      _isLoggedIn = user != null;
      notifyListeners();
    });
    if (!kIsWeb) {
      _googleSignIn = GoogleSignIn.instance;
    }
  }

  // ---------------- SIGN UP ----------------
  Future<String?> signUpWithEmail(String email, String password, String username) async {
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCred.user;
      if (user == null) return 'User creation failed';

      // Save username to Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'email': email,
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update Firebase Auth profile
      await user.updateDisplayName(username);

      // Create default categories if new user
      final isNew = userCred.additionalUserInfo?.isNewUser ?? false;
      if (isNew) await _createDefaultCategoriesForUser(user.uid);

      // Kick off email verification; account creation still succeeds if this fails.
      try {
        await user.sendEmailVerification();
      } catch (_) {}

      _isLoggedIn = true;
      notifyListeners();
      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ---------------- LOGIN ----------------
  Future<String?> loginWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _isLoggedIn = true;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ---------------- GOOGLE LOGIN ----------------
  Future<String?> loginWithGoogle() async {
    try {
      UserCredential userCred;
      if (kIsWeb) {
        // Web-specific code
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        // You can add scopes if needed
        // googleProvider.addScope('https://www.googleapis.com/auth/contacts.readonly');
        userCred = await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobile-specific code
        final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
        if (googleUser == null) return 'Google sign-in aborted';

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          // accessToken: googleAuth.accessToken,  // Optional, idToken is sufficient for Google
        );
        userCred = await _auth.signInWithCredential(credential);
      }

      final user = userCred.user!;
      final isNew = userCred.additionalUserInfo?.isNewUser ?? false;

      // Store Firestore data
      final userDoc = _firestore.collection('users').doc(user.uid);
      if (isNew) {
        await userDoc.set({
          'email': user.email,
          'username': user.displayName ?? 'User',
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _createDefaultCategoriesForUser(user.uid);
      }

      _isLoggedIn = true;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ---------------- EMAIL VERIFICATION ----------------
  Future<String?> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No signed-in user';
      await user.sendEmailVerification();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// Refreshes the current user from Firebase so `isEmailVerified` reflects
  /// a link the user may have just clicked in their inbox.
  Future<bool> refreshEmailVerifiedStatus() async {
    try {
      await _auth.currentUser?.reload();
    } catch (_) {}
    notifyListeners();
    return isEmailVerified;
  }

  // ---------------- LOGOUT ----------------
  Future<void> signOut() async {
    await _auth.signOut();
    _isLoggedIn = false;
    notifyListeners();
  }

  // ---------------- DEFAULT CATEGORIES ----------------
  Future<void> _createDefaultCategoriesForUser(String uid) async {
    final db = FirebaseFirestore.instance;
    final col = db.collection('categories');

    // Check if user already has categories
    final existing = await col.where('userId', isEqualTo: uid).limit(1).get();
    if (existing.docs.isNotEmpty) return;

    // Helper to generate Firestore IDs
    String genId() => col.doc().id;

    // Default categories & products
    final defaults = <Map<String, dynamic>>[
      // Expenses
      {
        'name': 'Housing / Rent',
        'color': 0xFFF44336,
        'type': 'expense',
        'products': ['Rent', 'Mortgage', 'Utilities', 'Insurance'],
      },
      {
        'name': 'Food',
        'color': 0xFFFF9800,
        'type': 'expense',
        'products': ['Groceries', 'Dining Out', 'Snacks'],
      },
      {
        'name': 'Transport',
        'color': 0xFF2196F3,
        'type': 'expense',
        'products': ['Gas', 'Public Transport', 'Car Maintenance'],
      },
      {
        'name': 'Health',
        'color': 0xFF4CAF50,
        'type': 'expense',
        'products': ['Doctor', 'Medicine', 'Gym'],
      },
      {
        'name': 'Entertainment',
        'color': 0xFF9C27B0,
        'type': 'expense',
        'products': ['Movies', 'Subscriptions'],
      },
      {
        'name': 'Shopping',
        'color': 0xFF795548,
        'type': 'expense',
        'products': ['Clothes', 'Electronics'],
      },
      // Income
      {
        'name': 'Salary',
        'color': 0xFF00BCD4,
        'type': 'income',
        'products': ['Base Salary', 'Bonus'],
      },
      {
        'name': 'Business',
        'color': 0xFF607D8B,
        'type': 'income',
        'products': ['Freelance', 'Side Hustle'],
      },
      {
        'name': 'Investments',
        'color': 0xFF3F51B5,
        'type': 'income',
        'products': ['Dividends', 'Interest'],
      },
    ];

    // Write all categories & products
    for (final catData in defaults) {
      final catId = genId();
      final products = (catData['products'] as List<String>).map((name) {
        return {
          'id': genId(),
          'name': name,
          'isDeleted': false,
        };
      }).toList();

      final docData = {
        'id': catId,
        'name': catData['name'],
        'color': catData['color'],
        'type': catData['type'],
        'isDeleted': false,
        'userId': uid,
        'products': products,
      };

      await col.doc(catId).set(docData);
    }
  }
}
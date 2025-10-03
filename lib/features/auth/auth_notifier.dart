import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../categories/logic/categoryNotifier.dart';

class AuthNotifier extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  User? get currentUser => _auth.currentUser;
  String? get userId => currentUser?.uid;

  AuthNotifier() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((user) {
      _isLoggedIn = user != null;
      notifyListeners();
    });
  }

  // ---------------- SIGN UP ----------------
  Future<String?> signUpWithEmail(String email, String password) async {
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCred.user;

      _isLoggedIn = user != null;
      notifyListeners();

      // If new user, create default categories
      final isNew = userCred.additionalUserInfo?.isNewUser ?? false;
      if (isNew && user != null) {
        try {
          await _createDefaultCategoriesForUser(user.uid);
        } catch (e, st) {
          debugPrint('Failed to create default categories: $e\n$st');
        }
      }

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
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _isLoggedIn = true;
      notifyListeners();
      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ---------------- LOGOUT ----------------
  Future<void> signOut() async {
    await _auth.signOut();
    _isLoggedIn = false;
    notifyListeners();
  }

  // ---------------- DEFAULT CATEGORIES ----------------
  // Inside AuthNotifier

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

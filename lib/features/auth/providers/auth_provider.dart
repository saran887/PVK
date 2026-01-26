import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/user_model.dart';

// Firebase instances
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Auth repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(firebaseAuthProvider),
    ref.read(firestoreProvider),
  );
});

// Auth state stream
final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.read(firebaseAuthProvider);
  return auth.authStateChanges();
});

// Current user document - optimized stream handling
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(null);
      }
      
      final firestore = ref.read(firestoreProvider);
      return firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((doc) {
            if (doc.exists && doc.data() != null) {
              return UserModel.fromFirestore(doc.data()!);
            }
            return null;
          })
          .handleError((error) {
            debugPrint('Error fetching user document: $error');
            return null;
          });
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._auth, this._firestore);

  User? get currentUser => _auth.currentUser;

  /// Sign in with a 4-digit code
  /// First tries the code as a string, then as a number
  Future<UserCredential> signInWithCode(String code) async {
    // Try finding user with code as string
    QuerySnapshot usersQuery = await _firestore
        .collection('users')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    // If not found, try as number
    if (usersQuery.docs.isEmpty) {
      final codeNum = int.tryParse(code);
      if (codeNum != null) {
        usersQuery = await _firestore
            .collection('users')
            .where('code', isEqualTo: codeNum)
            .limit(1)
            .get();
      }
    }

    if (usersQuery.docs.isEmpty) {
      throw AuthException('Invalid code. No user found.');
    }

    final userDoc = usersQuery.docs.first;
    final userData = userDoc.data() as Map<String, dynamic>;

    final email = userData['email'] as String?;
    final password = userData['password'] as String? ?? code;

    if (email == null || email.isEmpty) {
      throw AuthException('User email not configured.');
    }

    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getFirebaseAuthErrorMessage(e.code));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> createUser(UserModel user, String password) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: user.email,
      password: password,
    );

    await _firestore
        .collection('users')
        .doc(userCredential.user!.uid)
        .set(user.toMap());
  }

  String _getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this code.';
      case 'wrong-password':
        return 'Invalid credentials. Please contact admin.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  
  @override
  String toString() => message;
}

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

// Current user document
final currentUserProvider = StreamProvider<UserModel?>((ref) async* {
  final authState = ref.watch(authStateProvider);
  
  await for (final user in authState.when(
    data: (user) => Stream.value(user),
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  )) {
    if (user == null) {
      yield null;
    } else {
      final firestore = ref.read(firestoreProvider);
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      
      if (userDoc.exists) {
        yield UserModel.fromFirestore(userDoc.data()!);
      } else {
        yield null;
      }
    }
  }
});

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._auth, this._firestore);

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithCode(String code) async {
    // Query Firestore for user with this code
    final usersQuery = await _firestore
        .collection('users')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    if (usersQuery.docs.isEmpty) {
      throw Exception('Invalid code');
    }

    final userDoc = usersQuery.docs.first;
    final userData = userDoc.data();

    // Sign in with email/password
    return await _auth.signInWithEmailAndPassword(
      email: userData['email'],
      password: userData['password'] ?? code, // Use code as password
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> createUser(UserModel user, String password) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: user.email,
      password: password,
    );

    await _firestore.collection('users').doc(userCredential.user!.uid).set(user.toMap());
  }
}

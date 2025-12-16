import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options_local.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
    // DEBUG: Seed Firestore with test user code 2000
    Future<void> addTestUser() async {
      
      await FirebaseFirestore.instance.collection('users').add({
        'code': '2000',
        'name': 'Test User',
        'email': 'testuser@example.com',
      });
    }
    
    // DEBUG: Remove all products from Firestore
    Future<void> removeAllProducts() async {
      final products = await FirebaseFirestore.instance.collection('products').get();
      for (var doc in products.docs) {
        await doc.reference.delete();
      }
      debugPrint('✅ Removed ${products.docs.length} products from database');
    }
    
    // Uncomment to run once
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
    // Run Firestore seed after Firebase is initialized
    // await addTestUser(); // Comment out after first run
    // await removeAllProducts(); // Comment out after first run
  } catch (e, stackTrace) {
    debugPrint('❌ Firebase initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Distribution Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}

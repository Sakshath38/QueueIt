import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app/router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: BranchQApp()));
}

// 1. Changed to ConsumerWidget
class BranchQApp extends ConsumerWidget {
  const BranchQApp({super.key});

  @override
  // 2. Added WidgetRef ref
  Widget build(BuildContext context, WidgetRef ref) {
    
    // 3. Watch the Riverpod router for authentication state
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'BranchQ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Premium Color Palette
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A), // Deep Slate/Navy
          primary: const Color(0xFF2563EB),   // Vibrant Blue for actions
          surface: const Color(0xFFF8FAFC),   // Slightly cool off-white background
        ),

        // Modern Typography (Inter is the gold standard for fintech)
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),

        // Global Component Styling
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF0F172A)),
          titleTextStyle: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),

        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),

        // Card theme for Material 3
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)), // Subtle border
          ),
        ),
      ),

      // Use the watched router
      routerConfig: router,
    );
  }
}
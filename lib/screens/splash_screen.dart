import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'home/home_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final loggedIn = await AuthService.isLoggedIn();
    if (!loggedIn) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    // Check onboarding complete in Firestore
    final uid = AuthService.getUid();
    bool onboardingDone = false;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      onboardingDone = doc.data()?['onboarding_complete'] == true;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => onboardingDone ? const HomeScreen() : const OnboardingFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          ),
        ),
        child: const Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.school_rounded, color: Colors.white, size: 80),
            SizedBox(height: 16),
            Text('SkillRise', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Learn. Grow. Rise.', style: TextStyle(color: Colors.white70, fontSize: 16)),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          ]),
        ),
      ),
    );
  }
}

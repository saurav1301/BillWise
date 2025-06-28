import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _handleLogin(BuildContext context) async {
    final user = await AuthService().signInWithGoogle();
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login failed. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            SizedBox(height: screenHeight * 0.1),
            Image.asset(
              'assets/logo.png',
              height: 120,
            ),
            const SizedBox(height: 32),

            const Text(
              "Welcome to BillWise",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Split expenses. Share fairly.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 48),

            // ✅ Google Sign-In Button
            ElevatedButton.icon(
              onPressed: () => _handleLogin(context),
              icon: Image.asset('assets/google_icon.png', height: 24),
              label: const Text("Sign in with Google"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 2,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),

            const SizedBox(height: 16),

            // ✅ Facebook login button (placeholder)
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Add Facebook login
              },
              icon: const Icon(Icons.facebook, color: Colors.white),
              label: const Text("Continue with Facebook"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            const SizedBox(height: 16),

            // ✅ Phone login button (navigate to screen)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/phone-login');
              },
              icon: const Icon(Icons.phone),
              label: const Text("Login with Mobile Number"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            const SizedBox(height: 24),

            // ✅ "New here? Create Account" text
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: const Text("New here? Create Account"),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

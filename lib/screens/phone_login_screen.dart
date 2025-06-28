import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  String? _verificationId;
  bool _otpSent = false;
  bool _loading = false;

  void _sendOtp() async {
    setState(() => _loading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _phoneController.text.trim(),
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval (for Android)
        await FirebaseAuth.instance.signInWithCredential(credential);
        _goToHome();
      },
      verificationFailed: (e) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification failed: ${e.message}")),
        );
      },
      codeSent: (verificationId, _) {
        setState(() {
          _otpSent = true;
          _verificationId = verificationId;
          _loading = false;
        });
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  void _verifyOtp() async {
    if (_verificationId == null) return;

    setState(() => _loading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      _goToHome();
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP. Please try again.")),
      );
    }
  }

  void _goToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login with Mobile")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            if (!_otpSent)
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  hintText: "+91 9876543210",
                ),
              ),
            if (_otpSent)
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Enter OTP"),
              ),
            const SizedBox(height: 24),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _otpSent ? _verifyOtp : _sendOtp,
              child: Text(_otpSent ? "Verify OTP" : "Send OTP"),
            ),
          ],
        ),
      ),
    );
  }
}

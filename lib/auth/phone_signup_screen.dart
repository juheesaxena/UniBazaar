import 'package:flutter/material.dart';
import 'auth_service.dart';

class PhoneSignUpScreen extends StatefulWidget {
  const PhoneSignUpScreen({super.key});

  @override
  State<PhoneSignUpScreen> createState() => _PhoneSignUpScreenState();
}

class _PhoneSignUpScreenState extends State<PhoneSignUpScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  String? _error;

  Future<void> _signUp() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _authService.signUpWithEmail(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      if (!mounted) return;
      if (user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() => _error = 'Sign up failed. Try again.');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),

              // Logo row
              Center(
                child: Image.asset(
                  'assets/images/unibazaar_splash.jpeg',
                  height: 60,
                ),
              ),

              const SizedBox(height: 60),

              const Text(
                'Sign up',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),

              // Name
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Name',
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Email
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Phone
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Mobile number',
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              // Sign up button (green, full width)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAEDC98),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    _loading ? 'Signing up...' : 'Sign up',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],

              const SizedBox(height: 32),

              // Divider line
              const Divider(thickness: 0.7),

              const SizedBox(height: 8),

              // Already have account
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Already have an account ? Log in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

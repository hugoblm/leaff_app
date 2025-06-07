import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:flutter/gestures.dart';

class TextStyles {
  static const TextStyle titleStyle = TextStyle(
    color: Color(0xFFFFFFFF),
    fontSize: 32,
    height: 1.2,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subtitleStyle = TextStyle(
    color: Color(0x7FFFFFFF),
    fontSize: 16,
  );

  static const TextStyle boldText = TextStyle(
    color: Color(0xFFFFFFFF),
    fontWeight: FontWeight.bold,
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signIn();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing in with Google: ${e.toString()}'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showComingSoon(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider sign-in coming soon!'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/login_background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  
                  // Title
                  Text(
                    'Let\'s start by saving the planet!',
                    style: TextStyles.titleStyle,
                  ),
                  
                  // Spacer to push buttons to bottom
                  const Spacer(),
              // OAuth Sign-In buttons
              Column(
                children: [
                  // Google Sign In button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEDE9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      icon: const Icon(Icons.g_mobiledata, color: Color(0xFFD32F2F), size: 24),
                      label: const Text(
                        'Sign in with Google',
                        style: TextStyle(color: Color(0xFF000000), fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Facebook Sign In button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1877F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton.icon(
                      onPressed: _isLoading ? null : () => _showComingSoon('Facebook'),
                      icon: const Icon(Icons.facebook, color: Color(0xFFFFFFFF), size: 24),
                      label: const Text(
                        'Sign in with Facebook',
                        style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Apple Sign In button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF000000),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton.icon(
                      onPressed: _isLoading ? null : () => _showComingSoon('Apple'),
                      icon: const Icon(Icons.apple, color: Color(0xFFFFFFFF), size: 24),
                      label: const Text(
                        'Sign in with Apple',
                        style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),

              // Info text
              const Center(
                child: Text(
                  'Sign in with your preferred provider to continue',
                  style: TextStyle(color: Color(0x7FFFFFFF)),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // Terms and conditions
              Center(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Color(0x7FFFFFFF), fontSize: 12),
                    children: [
                      const TextSpan(text: 'By signing in, you agree to our '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyles.boldText,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // TODO: Add terms of service link
                          },
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyles.boldText,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // TODO: Add privacy policy link
                          },
                      ),
                    ],
                  ),
                ),
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

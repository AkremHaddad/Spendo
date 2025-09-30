import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/responsive.dart';
import 'auth_notifier.dart';
import '../../core/theme/theme.dart'; 

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

bool isMobileScreen(BuildContext context) {
  return MediaQuery.of(context).size.width < 600;
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLogin = true; // toggle between login/signup
  bool loading = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    final auth = Provider.of<AuthNotifier>(context, listen: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary, // dynamic primary color
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: isMobile ? double.infinity : 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor, // changes automatically in dark mode
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Spendo',
                  style: TextStyle(
                    fontSize: isMobile ? 32 : 40,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary, // adapt to theme
                  ),
                ),
                const SizedBox(height: 24),
                if (errorMessage != null)
                  Text(
                    errorMessage!,
                    style: TextStyle(color: colorScheme.error),
                  ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          setState(() {
                            loading = true;
                            errorMessage = null;
                          });
                          final email = emailController.text.trim();
                          final password = passwordController.text.trim();
                          String? error;
                          if (isLogin) {
                            error = await auth.loginWithEmail(email, password);
                          } else {
                            error = await auth.signUpWithEmail(email, password);
                          }
                          setState(() {
                            loading = false;
                            errorMessage = error;
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: loading
                      ? CircularProgressIndicator(
                          color: colorScheme.onPrimary,
                        )
                      : Text(
                          isLogin ? 'Login' : 'Sign Up',
                          style: TextStyle(color: colorScheme.onPrimary),
                        ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                      errorMessage = null;
                    });
                  },
                  child: Text(
                    isLogin
                        ? "Don't have an account? Sign Up"
                        : "Already have an account? Login",
                    style: TextStyle(color: colorScheme.secondary),
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to Spendo Web! Manage your finances easily.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

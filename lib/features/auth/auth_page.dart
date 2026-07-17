import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/theme.dart';
import 'auth_notifier.dart';
import '../main/main_page.dart'; 

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLogin = true;
  bool loading = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.base300,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 900) {
              return _buildMobileLayout(context, theme, colorScheme, isDark);
            } else {
              return _buildDesktopLayout(context, theme, colorScheme, isDark);
            }
          },
        ),
      ),
    );
  }

  // 🖥️ Desktop Layout
  Widget _buildDesktopLayout(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Row(
      children: [
        // Left side - content
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.only(top: 40, left: 80, right: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(colorScheme, 38, isDark),
                const SizedBox(height: 24),
                Text(
                  'Join Spendo and track\nyour expenses',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: theme.textTheme.headlineLarge?.color,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Take control of your finances with our intuitive tracking tools.',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                _buildForm(context, theme, colorScheme),
              ],
            ),
          ),
        ),

        // Right side - hero visual
        Expanded(
          flex: 6,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -400,
                top: 0,
                child: Container(
                  width: 700,
                  height: 700,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 100),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: Theme.of(context).borderColor,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.asset(
                        isDark
                            ? 'assets/images/dark3.png'
                            : 'assets/images/light3.png',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 📱 Mobile Layout
  Widget _buildMobileLayout(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(colorScheme, 32, isDark),
          const SizedBox(height: 32),
          Text(
            'Join Spendo and track your expenses',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: theme.textTheme.headlineLarge?.color,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take control of your finances with our intuitive tracking tools.',
            style: TextStyle(
              fontSize: 16,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 220,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -80,
                  top: -40,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Image.asset(
                    isDark
                        ? 'assets/images/dark3.png'
                        : 'assets/images/light3.png',
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildForm(context, theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildTitle(ColorScheme colorScheme, double fontSize, bool isDark) {
    return Row(
      children: [
        SvgPicture.asset(
          isDark ? 'assets/images/logoDark.svg' : 'assets/images/logoLight.svg',
          height: fontSize,
        ),
        const SizedBox(width: 8),
        Text(
          'Spendo',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  // 🧩 Auth form widget
  Widget _buildForm(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final auth = Provider.of<AuthNotifier>(context, listen: false);

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        children: [
          if (errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.error.withOpacity(0.3)),
              ),
              child: Text(
                errorMessage!,
                style: TextStyle(color: colorScheme.error, fontSize: 14),
              ),
            ),

          // 🔹 Animated form fields
          AnimatedCrossFade(
            firstChild: Column(
              children: [
                // Email
                const SizedBox(height: 8),

                TextField(
                  controller: emailController,
                  
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    filled: true,
                    fillColor: theme.cardsColor,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                // Password
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    filled: true,
                    fillColor: theme.cardsColor,
                  ),
                ),
              ],
            ),
            secondChild: Column(
              children: [
                // Username
                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      filled: true,
                      fillColor: theme.cardsColor,
                    ),
                  ),
                ),
                // Email
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    filled: true,
                    fillColor: theme.cardsColor,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                // Password
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    filled: true,
                    fillColor: theme.cardsColor,
                  ),
                ),
              ],
            ),
            crossFadeState: isLogin
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 300),
          ),

          const SizedBox(height: 24),

          // Login/Signup button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      setState(() {
                        loading = true;
                        errorMessage = null;
                      });
                      final email = emailController.text.trim();
                      final password = passwordController.text.trim();
                      final username = usernameController.text.trim();

                      String? error;
                      if (isLogin) {
                        error = await auth.loginWithEmail(email, password);
                      } else {
                        if (username.isEmpty) {
                          error = 'Username is required';
                        } else {
                          error = await auth.signUpWithEmail(
                            email,
                            password,
                            username,
                          );
                        }
                      }

                      setState(() {
                        loading = false;
                        errorMessage = error;
                      });
                      if (error == null) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) =>
                                MainPage(userId: auth.userId!),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : Text(
                      isLogin ? 'Login' : 'Sign Up',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Google login button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              icon: Image.asset('assets/images/google.png', height: 24),
              label: Text('Continue with Google', style: TextStyle(color: Theme.of(context).baseContent),),
              onPressed: loading
                  ? null
                  : () async {
                      setState(() {
                        loading = true;
                        errorMessage = null;
                      });
                      final error = await auth.loginWithGoogle();
                      setState(() {
                        loading = false;
                        errorMessage = error;
                      });
                      if (error == null) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) =>
                                MainPage(userId: auth.userId!),
                          ),
                        );
                      }
                    },
            ),
          ),

          const SizedBox(height: 16),

          // Toggle login/signup
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
              style: TextStyle(
                color: Theme.of(context).baseContent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

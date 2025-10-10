import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme.dart';
import 'auth_notifier.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
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
      BuildContext context, ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Row(
      children: [
        // Left side - content
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Spendo',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 48),
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
                const SizedBox(height: 48),
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
              // Half circle slightly off-screen to the right
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
              // Hero image centered visually
              Align(
  alignment: Alignment.centerRight,
  child: Padding(
    padding: const EdgeInsets.only(right: 100),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5), // Rounded corners
        border: Border.all(
          color: Theme.of(context).borderColor, // Border color
          width: 1, // Border width
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15), // Shadow color
            blurRadius: 20, // Shadow blur
            offset: const Offset(0, 8), // Shadow position
            spreadRadius: 2, // Shadow spread
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5), // Match container border radius
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
      BuildContext context, ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spendo',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
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

          // Hero image + circle on mobile
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

  // 🧩 Auth form widget
  Widget _buildForm(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
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
          const SizedBox(height: 24),
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
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

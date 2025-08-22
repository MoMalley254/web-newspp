import 'package:flutter/material.dart';
import 'package:newspp_desktop_backend/screens/main_screen.dart';
import 'package:newspp_desktop_backend/services/auth_service.dart';
import 'package:newspp_desktop_backend/services/toast_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final toastHelper = ToastService();
  final authService = AuthService();

  final loginFormKey = GlobalKey<FormState>(debugLabel: 'Login form key');
  final resetFormKey = GlobalKey<FormState>(debugLabel: 'Reset form key');

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController resetEmailController = TextEditingController();

  bool showResetField = false;

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    resetEmailController.dispose();
    super.dispose();
  }

  void _toggleResetField() {
    setState(() {
      showResetField = !showResetField;
    });
  }

  Future<void> _sendResetLink() async {
    updateLoading(true);
    if (resetFormKey.currentState!.validate()) {
      final email = resetEmailController.text.trim();
      // Simulate sending a reset link
      toastHelper.showProcessingtoast('Sending reset link to $email', 2);
    }
    updateLoading(false);
  }

  Future<void> _login() async {
  if (!loginFormKey.currentState!.validate()) return;

  final email = emailController.text.trim();
  final password = passwordController.text;

  toastHelper.showProcessingtoast('Logging in as $email, please wait...', 2);

  updateLoading(true); // Start loading

  try {
    final loginResponse = await authService.login(email, password);

    if (loginResponse) {
      print('Logged in successfully. Proceeding...');
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      print('Login failed. Prompting retry.');
    }
  } catch (e) {
    print('Login exception: $e');
    toastHelper.showErrortoast('An error occurred during login.');
  } finally {
    updateLoading(false); // Always stop loading
  }
}


  void updateLoading(bool state) {
    if (state) {
      setState(() {
        isLoading = true;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF232370), Color(0xFF4F0A8C)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                showResetField
                    ? Column(
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * .5,
                          child: resetPasswordForm(),
                        ),
                      ],
                    )
                    : Column(
                      children: [
                        Text(
                          'Welcome Back!',
                          style: TextStyle(fontSize: 28, color: Colors.white),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Enter your credentials to log in.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        SizedBox(height: 30),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * .5,
                          child: loginForm(context),
                        ),
                      ],
                    ),

                SizedBox(height: 20),

                GestureDetector(
                  onTap: _toggleResetField,
                  child: Text(
                    showResetField ? 'Back to Login' : 'Forgot Password?',
                    style: TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget loginForm(BuildContext context) {
    return Form(
      key: loginFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: emailController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: TextStyle(color: Colors.white),
              filled: true,
              fillColor: Colors.white24,
              border: OutlineInputBorder(),
              errorStyle: TextStyle(fontSize: 18, color: Colors.amberAccent),
            ),
            keyboardType: TextInputType.emailAddress,
            validator:
                (value) =>
                    value == null || !value.contains('@')
                        ? 'Enter a valid email'
                        : null,
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: passwordController,
            style: TextStyle(color: Colors.white),
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(color: Colors.white),
              filled: true,
              fillColor: Colors.white24,
              border: OutlineInputBorder(),
              errorStyle: TextStyle(fontSize: 18, color: Colors.amberAccent),
            ),
            validator:
                (value) =>
                    value == null || value.length < 6
                        ? 'Password too short'
                        : null,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: isLoading ? null : _login, // disables when loading
            child:
                isLoading
                    ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget resetPasswordForm() {
    return Form(
      key: resetFormKey,
      child: Column(
        children: [
          Text(
            'Enter your email to receive a password reset link.',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: resetEmailController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: TextStyle(color: Colors.white),
              filled: true,
              fillColor: Colors.white24,
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator:
                (value) =>
                    value == null || !value.contains('@')
                        ? 'Enter a valid email'
                        : null,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed:
                isLoading ? null : _sendResetLink, // disables when loading
            child:
                isLoading
                    ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }
}

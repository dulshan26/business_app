import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login1 extends StatefulWidget {
  const Login1({super.key});

  @override
  State<Login1> createState() => _Login1State();
}

class _Login1State extends State<Login1> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(); // fixed typo
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true; // show loader while checking saved login

  @override
  void initState() {
    super.initState();
    _checkSavedLogin(); // auto-login check on startup
  }

  // ✅ Check if user is already logged in
  Future<void> _checkSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString("email");
    final savedPassword = prefs.getString("password");

    if (savedEmail != null && savedPassword != null) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: savedEmail,
          password: savedPassword,
        );
        if (!mounted) return;
        context.goNamed("dashboard"); // skip login screen
        return;
      } catch (e) {
        // Saved credentials are invalid, clear them
        await prefs.remove("email");
        await prefs.remove("password");
      }
    }

    // No saved login — show the login form
    setState(() => _isLoading = false);
  }

  Future<void> signIn() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // ✅ Save credentials for next app launch
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("email", _emailController.text.trim());
      await prefs.setString("password", _passwordController.text.trim());

      if (!mounted) return;
      context.goNamed("dashboard");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Login Successful"),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = "❌ No user found with this email";
      } else if (e.code == 'wrong-password') {
        errorMessage = "❌ Wrong password, please try again";
      } else {
        errorMessage = "⚠️ ${e.message}";
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  // ✅ Call this on logout button to clear saved login
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("email");
    await prefs.remove("password");
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    context.goNamed("login");
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading spinner while checking saved credentials
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    width: 50,
                    height: 50,
                    child: Image.asset("asset/logo.jpg"),
                  ),
                  const Text(
                    "Hello Again",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const Text("Welcome back, you've been missed"),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: "Email",
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (val) =>
                        val == null || val.isEmpty ? "Enter your email" : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: "Password",
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                    textInputAction: TextInputAction.done,
                    validator: (val) => val == null || val.isEmpty
                        ? "Enter your password"
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 380,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextButton(
                      onPressed: signIn,
                      child: Text(
                        "Sign In",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Text(
                        "Not registered? ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Register page coming soon"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        child: Text(
                          "Click Here",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
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

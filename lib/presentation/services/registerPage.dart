import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
 bool _obscurePassword = true;
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("http://192.168.43.2//api/register.php"),
        body: {
          "username": _usernameController.text,
          "email": _emailController.text,
          "password": _passwordController.text,
        },
      );

      final data = json.decode(response.body);
      if (data["success"]) {
        await _showDialog("Success", "Account created! Please login.");
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        _showDialog("Registration Failed", data["message"]);
      }
    } catch (e) {
      _showDialog("Error", "email already exits !");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showDialog(String title, String message) async {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.pink)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.pink)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.person_add_alt, color: Colors.pink, size: 100),
                const SizedBox(height: 20),
                const Text(
                  "Create Account 💖",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _usernameController,
                  decoration: _inputDecoration("Username", Icons.person_outline,false),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Enter username" : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration("Email", Icons.email_outlined,false),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Enter email";
                    }
                    final emailRegex =
                        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) {
                      return "Enter valid email";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                 obscureText: _obscurePassword,
                  decoration: _inputDecoration("Password", Icons.lock_outline,true),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Enter password" : null,
                ),
                const SizedBox(height: 25),
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.pink)
                    : ElevatedButton(
                        onPressed: _registerUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text("Sign Up", style: TextStyle(fontSize: 18)),
                      ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text(
                    "Already have an account? Login",
                    style: TextStyle(color: Colors.pink),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon,bool isPassword) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.pink),
      filled: true,
      hintText: label,
      suffixIcon: isPassword?IconButton(
      icon: Icon(
        _obscurePassword ? Icons.visibility_off : Icons.visibility,
        color: Colors.pink,
      ),
      onPressed: () {
        setState(() {
          _obscurePassword = !_obscurePassword;
        });
      },
    ):null,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide.none,
      ),
    );
  }
}

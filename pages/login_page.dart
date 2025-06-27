import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  Future<void> login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => loading = true);
      try {
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        final user = userCredential.user;

        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification(); // retrimite dacă nu e verificat
          await FirebaseAuth.instance.signOut();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Trebuie să confirmi emailul înainte de a te autentifica. Verifică inboxul.',
              ),
            ),
          );
          setState(() => loading = false);
          return;
        }

        Navigator.pushReplacementNamed(context, '/home');
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Login failed')),
        );
      } finally {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.only(top: 100),
            children: [
              const SizedBox(height: 100),
              const Text(
                'FieldFinder',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value!.contains('@') ? null : 'Email invalid',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Parolă'),
                obscureText: true,
                validator: (value) =>
                    value!.length >= 6 ? null : 'Minim 6 caractere',
              ),
              const SizedBox(height: 24),
              loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: login,
                      child: const Text('Autentificare'),
                    ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/register');
                },
                child: const Text("Nu ai cont? Creează unul aici"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

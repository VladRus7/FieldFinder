import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String accountType = 'User';

  Future<void> register() async {
  if (_formKey.currentState!.validate()) {
    try {
      //creeaza user
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;

      // trimite email de verificare oficial de la Firebase
      await user!.sendEmailVerification();
      //adaugare document in colectie
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'accountType': accountType,
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': user.uid,
        'message': 'Bine ai venit în aplicația noastră! Spor la rezervări! ',
        'timestamp': Timestamp.now(),
        'read': false,
      });

      const serviceId = 'service_bvs53ay';
      const templateId = 'template_so724xf';
      const publicKey = 'Q8fvNZ6VuytS7sk2v';

      await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'user_name': nameController.text.trim(),
            'user_email': emailController.text.trim(),
          },
        }),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email de confirmare trimis! Verifică-ți inboxul.'),
        ),
      );

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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
          padding: const EdgeInsets.only(top: 60),
          children: [
            // Row cu buton de back și textul "Register"
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
                const SizedBox(width: 4),
                const Text(
                  'Register',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Titlul FieldFinder centrat
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

            // Form fields
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => value!.isEmpty ? 'Enter your name' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  value!.length != 10 ? 'Invalid phone number' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) =>
                  !value!.contains('@') ? 'Invalid email' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) =>
                  value!.length < 6 ? 'Min 6 characters' : null,
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: accountType,
              decoration: const InputDecoration(labelText: 'Account type'),
              items: const [
                DropdownMenuItem(value: 'User', child: Text('User')),
                DropdownMenuItem(value: 'Firm', child: Text('Firm')),
              ],
              onChanged: (value) {
                setState(() {
                  accountType = value!;
                });
              },
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: register,
              child: const Text('Register'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text("Ai deja cont? Autentifică-te aici"),
            ),
          ],
        ),
      ),
    ),
  );
}


}

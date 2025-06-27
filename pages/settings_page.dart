import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final data = doc.data();
    if (data != null && data.containsKey('notificationsEnabled')) {
      setState(() => notificationsEnabled = data['notificationsEnabled']);
    }
  }

  Future<void> _updateNotificationSetting(bool value) async {
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set(
      {'notificationsEnabled': value},
      SetOptions(merge: true),
    );
    setState(() => notificationsEnabled = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? 'Notificările activate' : 'Notificările dezactivate',
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    if (user?.email != null) {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email pentru resetarea parolei trimis.')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    try {
      await user?.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contul a fost șters.')),
      );
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la ștergerea contului: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: PreferredSize(
    preferredSize: const Size.fromHeight(60),
    child: Container(
      color: Colors.green,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Text(
            'FieldFinder > Setări',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Notificări'),
            value: notificationsEnabled,
            onChanged: _updateNotificationSetting,
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Schimbă parola'),
            onTap: _changePassword,
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Șterge contul'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Confirmă ștergerea'),
                  content: const Text('Ești sigur că vrei să ștergi contul? Această acțiune este ireversibilă.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Anulează'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Șterge'),
                    ),
                  ],
                ),
              );
              if (confirm == true) await _deleteAccount();
            },
          ),
        ],
      ),
    );
  }
}

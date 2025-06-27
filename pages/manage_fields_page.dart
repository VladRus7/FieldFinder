// manage_fields_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_field_page.dart';
import 'edit_field_page.dart';

class ManageFieldsPage extends StatefulWidget {
  const ManageFieldsPage({super.key});

  @override
  State<ManageFieldsPage> createState() => _ManageFieldsPageState();
}

class _ManageFieldsPageState extends State<ManageFieldsPage> {
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _getFieldsForUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final query = await FirebaseFirestore.instance
        .collection('fields')
        .where('ownerId', isEqualTo: uid)
        .get();

    return query.docs;
  }

  void _goToAddField(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddFieldPage()),
    );
  }

  Future<void> _deleteField(String docId) async {
    await FirebaseFirestore.instance.collection('fields').doc(docId).delete();
    setState(() {});
  }

  void _editField(BuildContext context, Map<String, dynamic> fieldData, String docId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditFieldPage(
          fieldId: docId,
          initialData: fieldData,
        ),
      ),
    ).then((_) => setState(() {}));
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
            'FieldFinder > Profil > Gestionare terenuri',
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
      
      body: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        future: _getFieldsForUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('Momentan nu ai niciun teren adăugat.'),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final field = docs[index].data();
              final docId = docs[index].id;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                 leading: field['imageUrl'] != null && field['imageUrl'] != ''
                      ? Image.network(
                      field['imageUrl'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 40),
                )
              : const Icon(Icons.sports_soccer),

                  title: Text(field['name'] ?? 'Teren fără nume'),
                  subtitle: Text(field['location'] ?? 'Locație necunoscută'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editField(context, field, docId),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteField(docId),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
          onPressed: () => _goToAddField(context),
          child: const Text('Adaugă teren'),
        ),
      ),
    );
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'manage_fields_page.dart';

class AddFieldPage extends StatefulWidget {
  const AddFieldPage({super.key});

  @override
  State<AddFieldPage> createState() => _AddFieldPageState();
}
class _AddFieldPageState extends State<AddFieldPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final priceController = TextEditingController();
  final phoneController = TextEditingController();
  final descriptionController = TextEditingController();
  String uploadedImageUrl = '';
  bool isSaving = false;
  bool isUploadingImage = false;

Future<void> _pickAndUploadImage() async {
  try {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      print(' Nicio imagine selectată');
      return;
    }

    setState(() => isUploadingImage = true);

    final bytes = await image.readAsBytes();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
    final ref = FirebaseStorage.instance.ref().child('fields/$fileName');

    print(' Uploading to Firebase Storage as: fields/$fileName');

    await ref.putData(bytes);

    final url = await ref.getDownloadURL();

    print(' Imagine urcată. URL generat: $url');

    setState(() {
      uploadedImageUrl = url;
      isUploadingImage = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Imagine încărcată cu succes!')),
    );
  } catch (e) {
    setState(() => isUploadingImage = false);
    print(' Eroare la încărcare imagine: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Eroare la încărcarea imaginii: $e')),
    );
  }
}



Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;

  if (uploadedImageUrl.isEmpty) {
    print('⚠️ Nu există uploadedImageUrl!');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Te rugăm să încarci o imagine.')),
    );
    return;
  }

  setState(() => isSaving = true);

  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      print(' Nu există UID. Utilizator delogat?');
      return;
    }

    print('📥 Salvăm în Firestore cu imaginea: $uploadedImageUrl');

    await FirebaseFirestore.instance.collection('fields').add({
      'ownerId': uid,
      'name': nameController.text.trim(),
      'location': locationController.text.trim(),
      'pricePerHour': priceController.text.trim(),
      'phone': phoneController.text.trim(),
      'description': descriptionController.text.trim(),
      'imageUrl': uploadedImageUrl,
      'createdAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Teren salvat cu succes!')),
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ManageFieldsPage()),
    );
  } catch (e) {
    setState(() => isSaving = false);
    print(' Eroare la salvarea în Firestore: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Eroare la salvare: $e')),
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
            'FieldFinder > Profil > Adaugă teren',
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
      body: isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Numele terenului'),
                      validator: (value) => value!.isEmpty ? 'Introdu numele' : null,
                    ),
                    TextFormField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'Locație'),
                      validator: (value) => value!.isEmpty ? 'Introdu locația' : null,
                    ),
                    TextFormField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Preț/oră (lei)'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Introdu prețul' : null,
                    ),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Telefon contact'),
                      validator: (value) => value!.length == 10 ? null : 'Număr invalid',
                    ),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Descriere'),
                      maxLines: 3,
                      validator: (value) => value!.isEmpty ? 'Scrie o descriere' : null,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _pickAndUploadImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Alege imagine din dispozitiv'),
                    ),
                    const SizedBox(height: 8),
                    if (isUploadingImage) const CircularProgressIndicator(),
                    if (uploadedImageUrl.isNotEmpty && !isUploadingImage)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Image.network(
                          uploadedImageUrl,
                          height: 150,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 100),
                        ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Salvează terenul'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

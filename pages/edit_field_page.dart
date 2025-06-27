
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditFieldPage extends StatefulWidget {
  final String fieldId;
  final Map<String, dynamic> initialData;

  const EditFieldPage({super.key, required this.fieldId, required this.initialData});

  @override
  State<EditFieldPage> createState() => _EditFieldPageState();
}

class _EditFieldPageState extends State<EditFieldPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController locationController;
  late TextEditingController priceController;
  late TextEditingController phoneController;
  late TextEditingController descriptionController;

  String uploadedImageUrl = '';
  List<String> additionalImages = [];

  bool isSaving = false;
  bool isUploadingAdditional = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialData['name'] ?? '');
    locationController = TextEditingController(text: widget.initialData['location'] ?? '');
    priceController = TextEditingController(text: widget.initialData['pricePerHour'] ?? '');
    phoneController = TextEditingController(text: widget.initialData['phone'] ?? '');
    descriptionController = TextEditingController(text: widget.initialData['description'] ?? '');
    uploadedImageUrl = widget.initialData['imageUrl'] ?? '';
    additionalImages = List<String>.from(widget.initialData['additionalImages'] ?? []);
  }

  Future<void> _pickAndUploadMainImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final ref = FirebaseStorage.instance.ref().child('fields/$fileName');

      await ref.putData(bytes);
      final url = await ref.getDownloadURL();

      setState(() {
        uploadedImageUrl = url;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagine principală actualizată!')),
      );
    } catch (e) {
      print(' Eroare la upload imagine principală: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la încărcare imagine: $e')),
      );
    }
  }

  Future<void> _pickAndUploadAdditionalImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => isUploadingAdditional = true);

      final bytes = await image.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final ref = FirebaseStorage.instance.ref().child('fields/$fileName');

      await ref.putData(bytes);
      final url = await ref.getDownloadURL();

      setState(() {
        additionalImages.add(url);
        isUploadingAdditional = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagine suplimentară adăugată!')),
      );
    } catch (e) {
      setState(() => isUploadingAdditional = false);
      print(' Eroare la upload imagine suplimentară: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la încărcare imagine: $e')),
      );
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    await FirebaseFirestore.instance.collection('fields').doc(widget.fieldId).update({
      'name': nameController.text.trim(),
      'location': locationController.text.trim(),
      'pricePerHour': priceController.text.trim(),
      'phone': phoneController.text.trim(),
      'description': descriptionController.text.trim(),
      'imageUrl': uploadedImageUrl,
      'additionalImages': additionalImages,
    });

    if (mounted) Navigator.pop(context);
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
            'FieldFinder > Profil > Editare teren',
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
                    const SizedBox(height: 20),
                    const Text('Imagine principală:', style: TextStyle(fontWeight: FontWeight.bold)),
                    if (uploadedImageUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Image.network(uploadedImageUrl, height: 150),
                      ),
                    ElevatedButton.icon(
                      onPressed: _pickAndUploadMainImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Schimbă imaginea principală'),
                    ),
                    const SizedBox(height: 24),
                    const Text('Imagini suplimentare:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: additionalImages
                          .map((url) => ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(url,
                                    height: 100, width: 100, fit: BoxFit.cover),
                              ))
                          .toList(),
                    ),
                    if (isUploadingAdditional) const CircularProgressIndicator(),
                    ElevatedButton.icon(
                      onPressed: _pickAndUploadAdditionalImage,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Adaugă imagine suplimentară'),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveChanges,
                      child: const Text('Salvează modificările'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

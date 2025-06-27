// field_booking_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:licenta/helpers/notification_helper.dart';

class FieldBookingPage extends StatefulWidget {
  final Map<String, dynamic> fieldData;

  const FieldBookingPage({super.key, required this.fieldData});

  @override
  State<FieldBookingPage> createState() => _FieldBookingPageState();
}

class _FieldBookingPageState extends State<FieldBookingPage> {
  DateTime? selectedDate;
  String? selectedHour;
  bool isSending = false;
  Set<String> bookedHours = {};
  String? accountType;

  final hours = [
    '16:00', '17:00', '18:00', '19:00', '20:00', '21:00', '22:00', '23:00'
  ];

  @override
  void initState() {
    super.initState();
    fetchUserType();
  }

  Future<void> fetchUserType() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null) {
        setState(() => accountType = data['accountType'] ?? '');
      }
    }
  }

  Future<void> sendBookingEmail({
    required String userName,
    required String userEmail,
    required String fieldName,
    required String date,
    required String hour,
  }) async {
    const serviceId = 'service_bvs53ay';
    const templateId = 'template_d6ehlbl';
    const publicKey = 'Q8fvNZ6VuytS7sk2v';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': publicKey,
        'template_params': {
          'user_name': userName,
          'user_email': userEmail,
          'field_name': fieldName,
          'date': date,
          'hour': hour,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Eroare la trimiterea emailului.');
    }
  }

  Future<void> loadBookedHours(String fieldId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('fieldId', isEqualTo: fieldId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    final results = snapshot.docs.map((doc) => doc['hour']?.toString() ?? '').where((e) => e.isNotEmpty).toSet();
    setState(() {
      bookedHours = results;
    });
  }

  void _launchMaps(String address) async {
    final url = Uri.encodeFull('https://www.google.com/maps/search/?api=1&query=$address');
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Nu pot deschide Google Maps';
    }
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.fieldData;
    final List<String> images = [
      if (field['imageUrl'] != null) field['imageUrl'],
      ...List<String>.from(field['additionalImages'] ?? []),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(field['name'] ?? 'Detalii Teren')),
      body: isSending
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(images[index], width: 300, fit: BoxFit.cover),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(field['description'] ?? '', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Preț/oră: ${field['pricePerHour'] ?? 'N/A'} lei', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Locație:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(field['location'] ?? ''),
                  TextButton.icon(
                    onPressed: () => _launchMaps(field['location'] ?? ''),
                    icon: const Icon(Icons.map),
                    label: const Text('Vezi pe Google Maps'),
                  ),
                  const SizedBox(height: 24),
                  if (accountType == 'Firm')
                    const Text('⚠️ Conturile de tip firmă nu pot face rezervări.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                  else ...[
                    const Text('Alege o dată:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                            selectedHour = null;
                            bookedHours.clear();
                          });
                          await loadBookedHours(widget.fieldData['id'] ?? '', pickedDate);
                        }
                      },
                      child: Text(selectedDate != null ? DateFormat('dd MMM yyyy').format(selectedDate!) : 'Selectează data'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Alege o oră:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: hours.map((hour) {
                        final isSelected = selectedHour == hour;
                        final isBooked = bookedHours.contains(hour);

                        bool isPastHour = false;
                        if (selectedDate != null) {
                          final now = DateTime.now();
                          final selected = DateTime(
                            selectedDate!.year,
                            selectedDate!.month,
                            selectedDate!.day,
                            int.parse(hour.split(':')[0]),
                            int.parse(hour.split(':')[1]),
                          );
                          isPastHour = selected.isBefore(now);
                        }

                        final isDisabled = isBooked || isPastHour;

                        return Tooltip(
                          message: isBooked ? 'Rezervat' : isPastHour ? 'Oră trecută' : '',
                          child: ChoiceChip(
                            label: Text(
                              hour,
                              style: TextStyle(
                                color: isDisabled ? Colors.grey.shade600 : null,
                                decoration: isDisabled ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: isDisabled ? null : (_) => setState(() => selectedHour = hour),
                            selectedColor: Colors.green,
                            disabledColor: Colors.grey.shade300,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: selectedDate != null && selectedHour != null
                          ? () async {
                              setState(() => isSending = true);
                              try {
                                final user = FirebaseAuth.instance.currentUser;
                                final userId = user?.uid ?? '';
                                final userEmail = user?.email ?? 'anonim@email.com';
                                final userName = user?.displayName ?? userEmail.split('@').first;
                                final fieldId = widget.fieldData['id'] ?? '';
                                final fieldName = widget.fieldData['name'] ?? 'teren necunoscut';

                                final snapshot = await FirebaseFirestore.instance
                                    .collection('bookings')
                                    .where('fieldId', isEqualTo: fieldId)
                                    .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day)))
                                    .where('date', isLessThanOrEqualTo: Timestamp.fromDate(DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, 23, 59, 59)))
                                    .where('hour', isEqualTo: selectedHour)
                                    .get();

                                if (snapshot.docs.isNotEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Această oră este deja rezervată!')),
                                  );
                                  setState(() => isSending = false);
                                  return;
                                }

                                await sendBookingEmail(
                                  userName: userName,
                                  userEmail: userEmail,
                                  fieldName: fieldName,
                                  date: DateFormat('dd MMM yyyy').format(selectedDate!),
                                  hour: selectedHour!,
                                );

                                await FirebaseFirestore.instance.collection('bookings').add({
                                  'userId': userId,
                                  'userEmail': userEmail,
                                  'fieldId': fieldId,
                                  'fieldName': fieldName,
                                  'date': Timestamp.fromDate(selectedDate!),
                                  'hour': selectedHour,
                                  'createdAt': Timestamp.now(),
                                });

                                await NotificationHelper.sendFirestoreNotification(
                                  message: 'Ai rezervat terenul "$fieldName" pentru ${DateFormat('dd MMM yyyy').format(selectedDate!)} la ora $selectedHour.',
                                );

                                await loadBookedHours(fieldId, selectedDate!);

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Rezervare salvată și trimisă cu succes!')),
                                  );
                                }
                              } catch (e) {
                                print('Eroare: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Eroare la rezervare: $e')),
                                );
                              } finally {
                                if (mounted) setState(() => isSending = false);
                              }
                            }
                          : null,
                      icon: const Icon(Icons.send),
                      label: const Text('Rezervă acum!'),
                    ),
                  ]
                ],
              ),
            ),
    );
  }
}

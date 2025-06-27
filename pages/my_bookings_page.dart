import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Funcție de utilitate pentru verificarea posibilității anulării
bool _canCancelBooking(DateTime date, String hour) {
  try {
    final hourParts = hour.split(':');
    final bookingDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(hourParts[0]),
      int.parse(hourParts[1]),
    );

    final now = DateTime.now();
    return bookingDateTime.isAfter(now.add(const Duration(hours: 2)));
  } catch (e) {
    return false;
  }
}

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Trebuie să fii autentificat pentru a vedea rezervările.')),
      );
    }

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
            'FieldFinder > Profil > Rezervările mele',
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Eroare: \${snapshot.error}'));
          }

          final bookings = snapshot.data?.docs ?? [];

          if (bookings.isEmpty) {
            return const Center(child: Text('Nu ai rezervări înregistrate.'));
          }

          bookings.sort((a, b) {
            final dateA = (a['date'] as Timestamp).toDate();
            final dateB = (b['date'] as Timestamp).toDate();
            return dateB.compareTo(dateA);
          });

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final data = bookings[index].data() as Map<String, dynamic>;
              final fieldName = data['fieldName'] ?? 'Teren';
              final date = (data['date'] as Timestamp).toDate();
              final hour = data['hour'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(fieldName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${DateFormat('dd MMM yyyy').format(date)} la ora $hour"),
                  leading: const Icon(Icons.calendar_today),
                  trailing: _canCancelBooking(date, hour)
                      ? IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Anulare rezervare'),
                                content: const Text('Ești sigur că vrei să anulezi această rezervare?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('Nu'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text('Da'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await FirebaseFirestore.instance
                                  .collection('bookings')
                                  .doc(bookings[index].id)
                                  .delete();

                              final userDoc = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .get();

                              final notificationsEnabled =
                                  userDoc.data()?['notificationsEnabled'] == true;

                              if (notificationsEnabled) {
                                await FirebaseFirestore.instance.collection('notifications').add({
                                  'userId': user.uid,
                                 'message': 'Rezervarea la "$fieldName" pentru ${DateFormat('dd MMM yyyy').format(date)} la ora $hour a fost anulată.',
                                  'timestamp': Timestamp.now(),
                                  'read': false,
                                });
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Rezervarea a fost anulată.')),
                              );
                            }
                          },
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

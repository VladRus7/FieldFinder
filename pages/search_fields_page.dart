import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'field_booking_page.dart';

class SearchFieldsPage extends StatefulWidget {
  const SearchFieldsPage({super.key});

  @override
  State<SearchFieldsPage> createState() => _SearchFieldsPageState();
}

class _SearchFieldsPageState extends State<SearchFieldsPage> {
  String searchQuery = '';
  bool showFilters = false;
  DateTime? selectedDate;
  String? selectedHour;
  double? maxPrice;
  final hourOptions = ['16:00', '17:00', '18:00', '19:00', '20:00', '21:00', '22:00', '23:00'];

  Set<String> bookedFieldIds = {};

  @override
  void initState() {
    super.initState();
    _loadBookedFields();
  }

  Future<void> _loadBookedFields() async {
    if (selectedDate == null || selectedHour == null) {
      setState(() => bookedFieldIds = {});
      return;
    }

    final start = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
    final end = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, 23, 59, 59);

    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('hour', isEqualTo: selectedHour)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    final booked = snapshot.docs.map((doc) => doc['fieldId'] as String).toSet();
    setState(() => bookedFieldIds = booked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () => setState(() => showFilters = !showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Caută după nume...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
            ),
          ),
          if (showFilters) _buildFilterSection(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('fields')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data?.docs ?? [];

                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();

                  if (!name.contains(searchQuery)) return false;
                  if (maxPrice != null && double.tryParse(data['pricePerHour'].toString()) != null) {
                    final price = double.parse(data['pricePerHour'].toString());
                    if (price > maxPrice!) return false;
                  }
                  if (selectedDate != null && selectedHour != null && bookedFieldIds.contains(doc.id)) {
                    return false;
                  }

                  return true;
                }).toList();

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FieldBookingPage(fieldData: {
                                ...data,
                                'id': doc.id,
                              }),
                            ),
                          );
                        },
                        leading: data['imageUrl'] != null
                            ? Image.network(data['imageUrl'], width: 60, fit: BoxFit.cover)
                            : const Icon(Icons.image_not_supported),
                        title: Text(data['name'] ?? 'Teren'),
                        subtitle: Text('${data['pricePerHour']} lei / oră'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (pickedDate != null) {
                      setState(() => selectedDate = pickedDate);
                      await _loadBookedFields();
                    }
                  },
                  child: Text(selectedDate != null
                      ? DateFormat('dd MMM yyyy').format(selectedDate!)
                      : 'Alege ziua disponibilă'),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                hint: const Text('Oră'),
                value: selectedHour,
                onChanged: (value) async {
                  setState(() => selectedHour = value);
                  await _loadBookedFields();
                },
                items: hourOptions.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Preț maxim: '),
              Expanded(
                child: Slider(
                  value: maxPrice ?? 100,
                  min: 20,
                  max: 500,
                  divisions: 24,
                  label: '${maxPrice?.round() ?? 100} lei',
                  onChanged: (value) => setState(() => maxPrice = value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

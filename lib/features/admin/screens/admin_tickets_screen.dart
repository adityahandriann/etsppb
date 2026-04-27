import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../user/services/ticket_service.dart';
import '../../../widgets/custom_widgets.dart';

class AdminTicketsScreen extends StatefulWidget {
  const AdminTicketsScreen({super.key});

  @override
  State<AdminTicketsScreen> createState() => _AdminTicketsScreenState();
}

class _AdminTicketsScreenState extends State<AdminTicketsScreen> {
  final TicketService _ticketService = TicketService();
  String _statusFilter = 'Semua';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Daftar Laporan'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.report_problem_outlined), text: 'Fasilitas'),
              Tab(icon: Icon(Icons.account_balance_wallet_outlined), text: 'Pembayaran'),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildFilterChips(),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTicketList('tickets'),
                  _buildTicketList('payments'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: ['Semua', 'Pending', 'Unverified', 'Resolved', 'Verified'].map((status) {
            bool isSelected = _statusFilter == status;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(status),
                selected: isSelected,
                onSelected: (val) {
                  if (val) setState(() => _statusFilter = status);
                },
                selectedColor: const Color(0xFF0F172A),
                labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF64748B)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTicketList(String collection) {
    Stream<QuerySnapshot> stream = (collection == 'tickets') 
        ? _ticketService.getAllTickets() 
        : _ticketService.getAllPayments();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            itemCount: 5,
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SkeletonLoading(height: 100),
            ),
          );
        }

        var docs = snapshot.data!.docs;
        
        // Apply Filter
        if (_statusFilter != 'Semua') {
          docs = docs.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == _statusFilter).toList();
        }

        if (docs.isEmpty) {
          return const EmptyState(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Tidak Ada Laporan',
            subtitle: 'Semua aman terkendali untuk kategori ini.',
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            String docId = docs[index].id;
            String base64String = data['imageUrl'] ?? '';
            bool isPending = data['status'] == 'Pending' || data['status'] == 'Unverified';
            bool isProcessing = data['status'] == 'Processing';

            Color statusColor = isPending ? Colors.orange : (isProcessing ? Colors.blue : Colors.green);
            IconData statusIcon = isPending ? Icons.hourglass_empty : (isProcessing ? Icons.build_circle_outlined : Icons.check_circle_outline);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                title: Text('Kamar ${data['nomorKamar']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Status: ${data['status']}', style: TextStyle(color: statusColor, fontSize: 12)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data['deskripsi'] != null)
                          Text(data['deskripsi'], style: const TextStyle(fontSize: 14, color: Color(0xFF334155))),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: base64String.isNotEmpty
                              ? Image.memory(
                                  base64Decode(base64String),
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  height: 100,
                                  width: double.infinity,
                                  color: const Color(0xFFF1F5F9),
                                  child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                                ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (data['status'] == 'Pending')
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _ticketService.updateStatus(collection, docId, 'Processing'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                  child: const Text('Proses Perbaikan'),
                                ),
                              ),
                            if (data['status'] == 'Pending' || data['status'] == 'Processing' || data['status'] == 'Unverified')
                              const SizedBox(width: 8),
                            if (data['status'] == 'Processing' || data['status'] == 'Pending' || data['status'] == 'Unverified')
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _ticketService.updateStatus(collection, docId, collection == 'tickets' ? 'Resolved' : 'Verified'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F172A),
                                  ),
                                  child: Text(collection == 'tickets' ? 'Selesaikan' : 'Verifikasi'),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}

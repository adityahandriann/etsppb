import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ticket_service.dart';
import '../../../widgets/custom_widgets.dart';

class UserTicketsScreen extends StatefulWidget {
  const UserTicketsScreen({super.key});

  @override
  State<UserTicketsScreen> createState() => _UserTicketsScreenState();
}

class _UserTicketsScreenState extends State<UserTicketsScreen> {
  final TicketService _ticketService = TicketService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.lock_outline,
          title: 'Sesi Berakhir',
          subtitle: 'Silakan login kembali untuk melihat riwayat.',
        ),
      );
    }

    final uid = user.uid;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Riwayat Laporan'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.build_circle_outlined), text: 'Kerusakan'),
              Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Pembayaran'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList('tickets', uid),
            _buildList('payments', uid),
          ],
        ),
      ),
    );
  }

  Widget _buildList(String collection, String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: collection == 'tickets' 
          ? _ticketService.getUserTickets(uid) 
          : _ticketService.getUserPayments(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            itemCount: 5,
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SkeletonLoading(height: 80),
            ),
          );
        }

        if (snapshot.data!.docs.isEmpty) {
          return const EmptyState(
            icon: Icons.history_outlined,
            title: 'Belum Ada Riwayat',
            subtitle: 'Semua laporan Anda akan muncul di sini.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            
            bool isPending = data['status'] == 'Pending' || data['status'] == 'Unverified';
            bool isProcessing = data['status'] == 'Processing';
            Color statusColor = isPending ? Colors.orange : (isProcessing ? Colors.blue : Colors.green);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: data['imageUrl'] != null && (data['imageUrl'] as String).isNotEmpty
                      ? Image.memory(base64Decode(data['imageUrl']), width: 50, height: 50, fit: BoxFit.cover)
                      : Container(
                          width: 50, 
                          height: 50, 
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(Icons.image_outlined, color: Colors.grey),
                        ),
                ),
                title: Text(
                  collection == 'tickets' ? (data['deskripsi'] ?? 'Laporan Fasilitas') : 'Laporan Pembayaran',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: ${data['status']}', style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                trailing: Icon(
                  isPending ? Icons.hourglass_top : (isProcessing ? Icons.sync : Icons.check_circle),
                  color: statusColor,
                  size: 20,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cargo_flow/services/firestore_service.dart';
import 'package:cargo_flow/screens/auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getAllPendingUsers(), // Stream for pending users
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final users = snapshot.data!.docs;
          if (users.isEmpty) {
            return const Center(
              child: Text(
                '🚀 لا يوجد مستخدمين معلقين',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              final uid = users[index].id;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الاسم و الايميل
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.deepPurple[100],
                            child: const Icon(Icons.person,
                                color: Colors.deepPurple, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['fullName'] ?? 'No Name',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  user['email'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // التفاصيل (Role & Status)
                      Row(
                        children: [
                          Chip(
                            label: Text("Role: ${user['role'] ?? 'customer'}"),
                            backgroundColor: Colors.blue[50],
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label:
                                Text("Status: ${user['status'] ?? 'pending'}"),
                            backgroundColor: Colors.orange[50],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // الأزرار
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // تفعيل
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              await _firestoreService.activateUser(uid);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('✅ User activated successfully')),
                              );
                            },
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text("تفعيل"),
                          ),
                          const SizedBox(width: 8),

                          // رفض
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .update({
                                'status': 'rejected',
                                'isActive': false,
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('❌ User rejected successfully')),
                              );
                            },
                            icon: const Icon(Icons.close, color: Colors.white),
                            label: const Text("رفض"),
                          ),
                          const SizedBox(width: 8),

                          // حذف
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              await _firestoreService.deleteUser(uid);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('🗑️ User deleted successfully')),
                              );
                            },
                            icon: const Icon(Icons.delete, color: Colors.white),
                            label: const Text("حذف"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

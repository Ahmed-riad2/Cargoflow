import 'package:flutter/material.dart';
import 'package:cargo_flow/services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  bool _loading = true;

  void _loadUserData() async {
    final data = await _firestoreService.getUserById(widget.userId);
    if (data != null) {
      _nameController = TextEditingController(text: data['name'] ?? '');
      _phoneController = TextEditingController(text: data['phone'] ?? '');
      _emailController = TextEditingController(text: data['email'] ?? '');
    } else {
      _nameController = TextEditingController();
      _phoneController = TextEditingController();
      _emailController = TextEditingController();
    }
    setState(() => _loading = false);
  }

  void _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await _firestoreService.updateUser(widget.userId, {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (v) => v == null || v.isEmpty ? 'Enter your phone' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v == null || v.isEmpty ? 'Enter your email' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Update Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

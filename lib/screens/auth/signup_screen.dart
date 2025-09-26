import 'package:cargo_flow/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  final String defaultRole; // Added default role

  const SignUpScreen({super.key, this.defaultRole = "customer"});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _fullNameController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _financeOfficerController = TextEditingController();
  final _logisticsOfficerController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _billingAddressController = TextEditingController();
  final _deliveryAddressesController = TextEditingController();
  final _paymentTermsController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _companyActivityController = TextEditingController();
  final _expectedShipmentSizeController = TextEditingController();
  final _clientSourceController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _maxLoadController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _driverLicenseExpiryController = TextEditingController();
  final _departmentController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _employeeNumberController = TextEditingController();
  final _hireDateController = TextEditingController();

  late String _selectedRole;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.defaultRole; // set default role
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _taxNumberController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _financeOfficerController.dispose();
    _logisticsOfficerController.dispose();
    _emergencyContactController.dispose();
    _billingAddressController.dispose();
    _deliveryAddressesController.dispose();
    _paymentTermsController.dispose();
    _creditLimitController.dispose();
    _companyActivityController.dispose();
    _expectedShipmentSizeController.dispose();
    _clientSourceController.dispose();
    _vehiclePlateController.dispose();
    _vehicleTypeController.dispose();
    _maxLoadController.dispose();
    _licenseNumberController.dispose();
    _driverLicenseExpiryController.dispose();
    _departmentController.dispose();
    _jobTitleController.dispose();
    _employeeNumberController.dispose();
    _hireDateController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim());

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCred.user!.uid)
          .set({
        "fullName": _fullNameController.text.trim(),
        "taxNumber": _taxNumberController.text.trim(),
        "email": _emailController.text.trim(),
        "phone": _phoneController.text.trim(),
        "password": _passwordController.text.trim(),
        "financeOfficer": _financeOfficerController.text.trim(),
        "logisticsOfficer": _logisticsOfficerController.text.trim(),
        "emergencyContact": _emergencyContactController.text.trim(),
        "billingAddress": _billingAddressController.text.trim(),
        "deliveryAddresses": _deliveryAddressesController.text.trim(),
        "paymentTerms": _paymentTermsController.text.trim(),
        "creditLimit": _creditLimitController.text.trim(),
        "companyActivity": _companyActivityController.text.trim(),
        "expectedShipmentSize": _expectedShipmentSizeController.text.trim(),
        "clientSource": _clientSourceController.text.trim(),
        "vehiclePlate": _vehiclePlateController.text.trim(),
        "vehicleType": _vehicleTypeController.text.trim(),
        "maxLoad": _maxLoadController.text.trim(),
        "licenseNumber": _licenseNumberController.text.trim(),
        "driverLicenseExpiry": _driverLicenseExpiryController.text.trim(),
        "department": _departmentController.text.trim(),
        "jobTitle": _jobTitleController.text.trim(),
        "employeeNumber": _employeeNumberController.text.trim(),
        "hireDate": _hireDateController.text.trim(),
        "role": _selectedRole.toLowerCase(),
        "isActive": false,
        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Account created successfully. Please wait for admin approval.")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => _loading = false);
  }

  List<Step> _buildSteps() {
        if (_selectedRole == "admin") {
      return [
        Step(
          title: const Text("Basic Information"),
          content: Column(
            children: [
              _buildField(_fullNameController, "Full Name"),
              _buildField(_emailController, "Email"),
              _buildField(_passwordController, "Password", isPassword: true),
            ],
          ),
          isActive: _currentStep >= 0,
        ),
      ];
    }

    if (_selectedRole == "customer") {
      return [
        Step(
          title: const Text("Basic Information"),
          content: Column(
            children: [
              _buildField(_fullNameController, "Full Name"),
              _buildField(_emailController, "Email"),
              _buildField(_phoneController, "Phone Number"),
              _buildField(_passwordController, "Password", isPassword: true),
              _buildField(_emergencyContactController, "Emergency Contact"),
            ],
          ),
          isActive: _currentStep >= 0,
        ),
        Step(
          title: const Text("Company Information"),
          content: Column(
            children: [
              _buildField(_taxNumberController, "Tax Number"),
              _buildField(_billingAddressController, "Billing Address"),
              _buildField(_deliveryAddressesController, "Delivery Addresses"),
              _buildField(_companyActivityController, "Company Activity"),
              _buildField(_clientSourceController, "Client Source"),
            ],
          ),
          isActive: _currentStep >= 1,
        ),
        Step(
          title: const Text("Additional Information"),
          content: Column(
            children: [
              _buildField(_financeOfficerController, "Finance Officer"),
              _buildField(_logisticsOfficerController, "Logistics Officer"),
              _buildField(_paymentTermsController, "Payment Terms"),
              _buildField(_creditLimitController, "Credit Limit"),
              _buildField(
                  _expectedShipmentSizeController, "Expected Shipment Size"),
            ],
          ),
          isActive: _currentStep >= 2,
        ),
      ];
    }

    if (_selectedRole == "driver") {
      return [
        Step(
          title: const Text("Basic Information"),
          content: Column(
            children: [
              _buildField(_fullNameController, "Full Name"),
              _buildField(_emailController, "Email"),
              _buildField(_phoneController, "Phone Number"),
              _buildField(_passwordController, "Password", isPassword: true),
              _buildField(_emergencyContactController, "Emergency Contact"),
            ],
          ),
          isActive: _currentStep >= 0,
        ),
        Step(
          title: const Text("Company Information"),
          content: Column(
            children: [
              _buildField(_vehiclePlateController, "Vehicle Plate Number"),
              _buildField(_vehicleTypeController, "Vehicle Type"),
              _buildField(_maxLoadController, "Maximum Load"),
            ],
          ),
          isActive: _currentStep >= 1,
        ),
        Step(
          title: const Text("Additional Information"),
          content: Column(
            children: [
              _buildField(_licenseNumberController, "License Number"),
              _buildField(
                  _driverLicenseExpiryController, "Driver License Expiry"),
            ],
          ),
          isActive: _currentStep >= 2,
        ),
      ];
    }

    if (_selectedRole == "employee") {
      return [
        Step(
          title: const Text("Basic Information"),
          content: Column(
            children: [
              _buildField(_fullNameController, "Full Name"),
              _buildField(_emailController, "Email"),
              _buildField(_phoneController, "Phone Number"),
              _buildField(_passwordController, "Password", isPassword: true),
              _buildField(_emergencyContactController, "Emergency Contact"),
            ],
          ),
          isActive: _currentStep >= 0,
        ),
        Step(
          title: const Text("Company Information"),
          content: Column(
            children: [
              _buildField(_departmentController, "Department"),
              _buildField(_jobTitleController, "Job Title"),
              _buildField(_employeeNumberController, "Employee Number"),
            ],
          ),
          isActive: _currentStep >= 1,
        ),
        Step(
          title: const Text("Additional Information"),
          content: Column(
            children: [
              _buildField(_hireDateController, "Hire Date"),
            ],
          ),
          isActive: _currentStep >= 2,
        ),
      ];
    }

    // fallback
    return [
      Step(
        title: const Text("Basic Information"),
        content: Column(
          children: [
            _buildField(_fullNameController, "Full Name"),
            _buildField(_emailController, "Email"),
            _buildField(_phoneController, "Phone Number"),
            _buildField(_passwordController, "Password", isPassword: true),
          ],
        ),
        isActive: _currentStep >= 0,
      ),
    ];
  }

  Widget _buildField(TextEditingController controller, String label,
      {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (val) =>
            val == null || val.isEmpty ? "This field is required" : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create New Account")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Stepper(
                steps: _buildSteps(),
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep < _buildSteps().length - 1) {
                    setState(() => _currentStep++);
                  } else {
                    _signUp();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep--);
                  }
                },
              ),
            ),
    );
  }
}

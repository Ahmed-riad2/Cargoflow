import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ====== SIGN UP ======
  Future<User?> signUpWithEmail({
    required String fullName,
    required String taxNumber,
    required String email,
    required String password,
    required String phone,
    required String role,
    // Extra fields
    String? financeOfficer,
    String? logisticsOfficer,
    String? emergencyContact,
    String? billingAddress,
    String? deliveryAddresses,
    String? paymentTerms,
    String? creditLimit,
    String? companyActivity,
    String? expectedShipmentSize,
    String? clientSource,
    String? vehiclePlate,
    String? vehicleType,
    String? maxLoad,
    String? licenseNumber,
    String? driverLicenseExpiry,
    String? department,
    String? jobTitle,
    String? employeeNumber,
    String? hireDate,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final User? user = userCredential.user;
      if (user == null) throw Exception('Sign-up failed: User is null.');

      /// Base user data
      Map<String, dynamic> userData = {
        'uid': user.uid,
        'name': fullName.trim(),
        'taxNumber': taxNumber.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': role.toLowerCase(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      /// Extra fields
      if (financeOfficer != null) userData['financeOfficer'] = financeOfficer;
      if (logisticsOfficer != null) userData['logisticsOfficer'] = logisticsOfficer;
      if (emergencyContact != null) userData['emergencyContact'] = emergencyContact;
      if (billingAddress != null) userData['billingAddress'] = billingAddress;
      if (deliveryAddresses != null) userData['deliveryAddresses'] = deliveryAddresses;
      if (paymentTerms != null) userData['paymentTerms'] = paymentTerms;
      if (creditLimit != null) userData['creditLimit'] = creditLimit;
      if (companyActivity != null) userData['companyActivity'] = companyActivity;
      if (expectedShipmentSize != null) userData['expectedShipmentSize'] = expectedShipmentSize;
      if (clientSource != null) userData['clientSource'] = clientSource;
      if (vehiclePlate != null) userData['vehiclePlate'] = vehiclePlate;
      if (vehicleType != null) userData['vehicleType'] = vehicleType;
      if (maxLoad != null) userData['maxLoad'] = maxLoad;
      if (licenseNumber != null) userData['licenseNumber'] = licenseNumber;
      if (driverLicenseExpiry != null) userData['driverLicenseExpiry'] = driverLicenseExpiry;
      if (department != null) userData['department'] = department;
      if (jobTitle != null) userData['jobTitle'] = jobTitle;
      if (employeeNumber != null) userData['employeeNumber'] = employeeNumber;
      if (hireDate != null) userData['hireDate'] = hireDate;

      /// Save user in Firestore
      await _firestore.collection('users').doc(user.uid).set(userData);

      await _sendAdminNotification(user.uid);

      return user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          throw Exception('Password is too weak.');
        case 'email-already-in-use':
          throw Exception('An account already exists with this email.');
        case 'invalid-email':
          throw Exception('Invalid email address.');
        default:
          throw Exception('Sign-up failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Sign-up failed: $e');
    }
  }

  Future<void> _sendAdminNotification(String userId) async {
    await _firestore.collection('admin_notifications').add({
      'message': 'New user $userId needs verification.',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// ====== ACTIVATE USER ======
  Future<void> activateUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'status': 'active',
    });
  }

  /// ====== LOGIN ======
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      /// Special hardcoded admin
      if (email.trim() == "Ahmedadmin1@gmail.com" &&
          password.trim() == "00000000A") {
        // Fake user admin
        return _FakeAdminUser();
      }

      // Normal login
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final User? user = userCredential.user;
      if (user == null) throw Exception('Login failed: User is null.');
      return user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found with this email.');
        case 'wrong-password':
          throw Exception('Incorrect password.');
        case 'invalid-email':
          throw Exception('Invalid email format.');
        case 'user-disabled':
          throw Exception('This account has been disabled.');
        default:
          throw Exception('Login failed: ${e.message}');
      }
    }
  }

  /// ====== GET ROLE ======
  Future<String> getUserRole(String uid) async {
    try {
      if (uid == "admin_fake_uid") return "admin"; // fake admin role
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['role'] as String? ?? 'customer';
      }
      return 'customer';
    } catch (e) {
      return 'customer';
    }
  }

  /// ====== LOGOUT ======
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

/// ====== Fake Admin User ======
/// بيشبه User عادي لكن بيديك UID خاص
class _FakeAdminUser implements User {
  @override
  String get uid => "admin_fake_uid";

  @override
  String? get email => "Ahmedadmin1@gmail.com";

  // باقي الخصائص نخليها null أو قيم افتراضية
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

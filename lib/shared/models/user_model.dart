import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/app_enums.dart';

class UserModel {
  final String name;
  final String email;
  final String code;
  final UserRole role;
  final String phone;
  final bool isActive;
  final List<String> assignedRoutes;
  final String? locationId;
  final String? locationName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.name,
    required this.email,
    required this.code,
    required this.role,
    required this.phone,
    this.isActive = true,
    this.assignedRoutes = const [],
    this.locationId,
    this.locationName,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      code: data['code']?.toString() ?? '',
      role: UserRole.fromString(data['role'] ?? 'SALES'),
      phone: data['phone'] ?? '',
      isActive: data['isActive'] ?? true,
      assignedRoutes: List<String>.from(data['assignedRoutes'] ?? []),
      locationId: data['locationId']?.toString(),
      locationName: data['locationName'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'code': code,
      'role': role.name.toUpperCase(),
      'phone': phone,
      'isActive': isActive,
      'assignedRoutes': assignedRoutes,
      'locationId': locationId ?? '',
      'locationName': locationName ?? '',
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

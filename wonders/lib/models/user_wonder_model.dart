import 'dart:io';

class UserWonderModel {
  final String id;
  final String userId;
  String name;
  String description;
  String? imageUrl; // Keep for Firebase storage reference
  File? imageFile; // Added for local file reference (not stored in Firestore)
  String? location;
  double? latitude;
  double? longitude;
  DateTime? plannedVisitDate;
  DateTime createdAt;
  bool isCompleted;
  DateTime? completedDate;

  UserWonderModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    this.imageUrl,
    this.imageFile, // Added field
    this.location,
    this.latitude,
    this.longitude,
    this.plannedVisitDate,
    required this.createdAt,
    this.isCompleted = false,
    this.completedDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl, // Store URL in Firestore, not File object
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'plannedVisitDate': plannedVisitDate?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
      'completedDate': completedDate?.millisecondsSinceEpoch,
    };
  }

  factory UserWonderModel.fromJson(String id, Map<String, dynamic> json) {
    return UserWonderModel(
      id: id,
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'], // Load URL from Firestore
      location: json['location'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      plannedVisitDate:
          json['plannedVisitDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(json['plannedVisitDate'])
              : null,
      createdAt:
          json['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
              : DateTime.now(),
      isCompleted: json['isCompleted'] ?? false,
      completedDate:
          json['completedDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(json['completedDate'])
              : null,
    );
  }

  // Create a copy with an attached file
  UserWonderModel copyWithFile(File file) {
    return UserWonderModel(
      id: this.id,
      userId: this.userId,
      name: this.name,
      description: this.description,
      imageUrl: this.imageUrl,
      imageFile: file,
      location: this.location,
      latitude: this.latitude,
      longitude: this.longitude,
      plannedVisitDate: this.plannedVisitDate,
      createdAt: this.createdAt,
      isCompleted: this.isCompleted,
      completedDate: this.completedDate,
    );
  }
}

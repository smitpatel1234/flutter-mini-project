class UserModel {
  final String uid;
  final String email;
  String? name;
  String? gender;
  DateTime? dateOfBirth;
  String? wonder;

  UserModel({
    required this.uid,
    required this.email,
    this.name,
    this.gender,
    this.dateOfBirth,
    this.wonder,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.millisecondsSinceEpoch,
      'wonder': wonder,
    };
  }

  // Create UserModel from Firestore document
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'],
      gender: json['gender'],
      dateOfBirth:
          json['dateOfBirth'] != null
              ? DateTime.fromMillisecondsSinceEpoch(json['dateOfBirth'])
              : null,
      wonder: json['wonder'],
    );
  }
}

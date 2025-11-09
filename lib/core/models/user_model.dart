class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  /// Converts this [UserModel] instance to a JSON map for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
    };
  }

  /// Creates a [UserModel] instance from a Firestore document snapshot (Map).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
    );
  }

  /// Creates a copy of this user model with updated fields.
  UserModel copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? email,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
    );
  }
}
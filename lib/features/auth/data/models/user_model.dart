import 'dart:convert';
import '../../domain/models/user_profile.dart';

class UserModel extends UserProfile {
  const UserModel({
    required super.id,
    required super.name,
    required super.username,
    required super.email,
    required super.phone,
    required super.website,
    required super.companyName,
    super.companyCatchPhrase,
    super.companyBs,
    super.street,
    super.suite,
    super.city,
    super.zipcode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final company = json['company'] as Map<String, dynamic>? ?? {};
    final address = json['address'] as Map<String, dynamic>? ?? {};

    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      website: json['website'] as String? ?? '',
      companyName: company['name'] as String? ?? 'N/A',
      companyCatchPhrase: company['catchPhrase'] as String? ?? '',
      companyBs: company['bs'] as String? ?? '',
      street: address['street'] as String? ?? '',
      suite: address['suite'] as String? ?? '',
      city: address['city'] as String? ?? '',
      zipcode: address['zipcode'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'phone': phone,
      'website': website,
      'company': {
        'name': companyName,
        'catchPhrase': companyCatchPhrase,
        'bs': companyBs,
      },
      'address': {
        'street': street,
        'suite': suite,
        'city': city,
        'zipcode': zipcode,
      },
    };
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': 1, // Single active session record
      'user_id': id,
      'name': name,
      'username': username,
      'email': email,
      'phone': phone,
      'website': website,
      'company_name': companyName,
      'raw_json': jsonEncode(toJson()),
      'logged_in_at': DateTime.now().toIso8601String(),
    };
  }

  factory UserModel.fromDbMap(Map<String, dynamic> map) {
    if (map.containsKey('raw_json') && map['raw_json'] != null) {
      try {
        final decoded = jsonDecode(map['raw_json'] as String) as Map<String, dynamic>;
        return UserModel.fromJson(decoded);
      } catch (_) {
        // Fallback to flat column reading
      }
    }
    return UserModel(
      id: map['user_id'] as int? ?? map['id'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      username: map['username'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      website: map['website'] as String? ?? '',
      companyName: map['company_name'] as String? ?? '',
    );
  }
}


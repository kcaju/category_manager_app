import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final int id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String website;
  final String companyName;
  final String companyCatchPhrase;
  final String companyBs;
  final String street;
  final String suite;
  final String city;
  final String zipcode;

  const UserProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.website,
    required this.companyName,
    this.companyCatchPhrase = '',
    this.companyBs = '',
    this.street = '',
    this.suite = '',
    this.city = '',
    this.zipcode = '',
  });

  @override
  List<Object?> get props => [
        id,
        name,
        username,
        email,
        phone,
        website,
        companyName,
        companyCatchPhrase,
        companyBs,
        street,
        suite,
        city,
        zipcode,
      ];
}

